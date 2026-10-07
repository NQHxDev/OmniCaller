use crate::dtos::call_dtos::*;
use crate::entities::{call, call_participant, user, user_presence};
use anyhow::{anyhow, Result};
use chrono::Utc;
use livekit_api::access_token::{AccessToken, VideoGrants};
use sea_orm::sea_query::Expr;
use sea_orm::*;
use std::env;
use uuid::Uuid;

#[derive(Clone)]
pub struct CallService {
   db: DatabaseConnection,
}

impl CallService {
   pub fn new(db: DatabaseConnection) -> Self {
      Self { db }
   }

   /// Initiate a new call (direct or group)
   pub async fn initiate_call(
      &self,
      initiator_id: Uuid,
      dto: InitiateCallDto,
   ) -> Result<InitiateCallResponse> {
      tracing::info!("=== CallService::initiate_call START ===");
      tracing::info!("initiator_id: {}, call_type: {}, mode: {}", initiator_id, dto.call_type, dto.mode);
      
      // Validate call type
      if dto.call_type != "voice" && dto.call_type != "video" {
         return Err(anyhow!("Invalid call type. Must be 'voice' or 'video'"));
      }

      // Validate mode
      if dto.mode != "direct" && dto.mode != "group" {
         return Err(anyhow!("Invalid mode. Must be 'direct' or 'group'"));
      }

      // Validate participants
      if dto.mode == "direct" && dto.participant_ids.len() != 1 {
         return Err(anyhow!("Direct call must have exactly 1 participant"));
      }

      // For group calls, conversation_id is required
      if dto.mode == "group" && dto.conversation_id.is_none() {
         return Err(anyhow!("Group call requires conversation_id"));
      }

      // For group calls, if participant_ids is empty, fetch from conversation
      let participant_ids = if dto.mode == "group" && dto.participant_ids.is_empty() {
         tracing::info!("Group call with empty participant_ids, fetching from conversation");
         self.get_conversation_member_ids(dto.conversation_id.unwrap(), initiator_id).await?
      } else {
         dto.participant_ids.clone()
      };

      // Validate participant count after resolving
      if dto.mode == "group" && participant_ids.is_empty() {
         return Err(anyhow!("Group call must have at least 1 participant (conversation has no other members)"));
      }

      if dto.mode == "group" && participant_ids.len() > 19 {
         return Err(anyhow!("Group call cannot exceed 20 participants (including initiator)"));
      }

      // Check if initiator is in participant list (they shouldn't be)
      if dto.participant_ids.contains(&initiator_id) {
         tracing::warn!("Participant list contains initiator_id, this will create duplicate participant records");
      }

      // Check for duplicate participant IDs
      let mut unique_participants = std::collections::HashSet::new();
      for pid in &dto.participant_ids {
         if !unique_participants.insert(pid) {
            return Err(anyhow!("Duplicate participant ID found: {}", pid));
         }
      }

      tracing::info!("Validation passed, {} unique participants", dto.participant_ids.len());
      
      // Generate unique room name
      let room_name = format!("call_{}", Uuid::now_v7());

      // Create call record
      let call_id = Uuid::now_v7();
      let now = Utc::now();

      let call_model = call::ActiveModel {
         id: Set(call_id),
         room_name: Set(room_name.clone()),
         call_type: Set(dto.call_type.clone()),
         mode: Set(dto.mode.clone()),
         conversation_id: Set(dto.conversation_id),
         initiated_by: Set(initiator_id),
         status: Set("ringing".to_string()),
         started_at: Set(now.into()),
         ended_at: Set(None),
         duration: Set(None),
         created_at: Set(now.into()),
         updated_at: Set(now.into()),
      };

      tracing::info!("Inserting call record into database: call_id={}", call_id);
      let call_result = call_model.insert(&self.db).await.map_err(|e| {
         tracing::error!("Database insert failed: {:?}", e);
         e
      })?;
      tracing::info!("Call record inserted successfully");

      // Create participant records
      let mut participant_models = vec![];

      // Add initiator as participant with 'joined' status
      let initiator_participant_id = Uuid::now_v7();
      participant_models.push(call_participant::ActiveModel {
         id: Set(initiator_participant_id),
         call_id: Set(call_id),
         user_id: Set(initiator_id),
         status: Set("joined".to_string()),
         joined_at: Set(Some(now.into())),
         left_at: Set(None),
         duration: Set(None),
         created_at: Set(now.into()),
         updated_at: Set(now.into()),
      });

      // Add other participants with 'invited' status
      for participant_id in participant_ids.iter() {
         let participant_model_id = Uuid::now_v7();
         participant_models.push(call_participant::ActiveModel {
            id: Set(participant_model_id),
            call_id: Set(call_id),
            user_id: Set(*participant_id),
            status: Set("invited".to_string()),
            joined_at: Set(None),
            left_at: Set(None),
            duration: Set(None),
            created_at: Set(now.into()),
            updated_at: Set(now.into()),
         });
      }

      tracing::info!("Inserting {} participant records", participant_models.len());
      call_participant::Entity::insert_many(participant_models)
         .exec(&self.db)
         .await
         .map_err(|e| {
            tracing::error!("Failed to insert participants: {:?}", e);
            e
         })?;
      tracing::info!("Participant records inserted successfully");

      // Generate LiveKit token for initiator
      tracing::info!("Generating LiveKit token for initiator");
      let token = self.generate_livekit_token(initiator_id, &room_name, true).await.map_err(|e| {
         tracing::error!("Failed to generate LiveKit token: {:?}", e);
         e
      })?;
      tracing::info!("LiveKit token generated successfully");

      // Get all participants
      let participants = self.get_call_participants(call_id).await?;

      let call_response = CallResponse {
         id: call_result.id,
         room_name: call_result.room_name,
         call_type: call_result.call_type,
         mode: call_result.mode,
         conversation_id: call_result.conversation_id,
         initiated_by: call_result.initiated_by,
         status: call_result.status,
         started_at: call_result.started_at.to_utc(),
         ended_at: call_result.ended_at.map(|dt| dt.to_utc()),
         duration: call_result.duration,
         participants,
      };

      tracing::info!("=== CallService::initiate_call SUCCESS ===");
      Ok(InitiateCallResponse { call: call_response, token })
   }

   /// Join an existing call
   pub async fn join_call(&self, user_id: Uuid, call_id: Uuid) -> Result<JoinCallResponse> {
      // Find call
      let call = call::Entity::find_by_id(call_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("Call not found"))?;

      // Check if call is still active
      if call.status == "ended" || call.status == "missed" || call.status == "rejected" {
         return Err(anyhow!("Call has already ended"));
      }

      // Find participant record
      let participant = call_participant::Entity::find()
         .filter(call_participant::Column::CallId.eq(call_id))
         .filter(call_participant::Column::UserId.eq(user_id))
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("User is not a participant in this call"))?;

      // Update participant status to 'joined'
      let now = Utc::now();
      let mut participant_active: call_participant::ActiveModel = participant.into();
      participant_active.status = Set("joined".to_string());
      participant_active.joined_at = Set(Some(now.into()));
      participant_active.updated_at = Set(now.into());
      participant_active.update(&self.db).await?;

      // Update call status to 'active' if it was 'ringing'
      if call.status == "ringing" {
         let mut call_active: call::ActiveModel = call.clone().into();
         call_active.status = Set("active".to_string());
         call_active.updated_at = Set(now.into());
         call_active.update(&self.db).await?;
      }

      // Generate LiveKit token
      let token = self.generate_livekit_token(user_id, &call.room_name, true).await?;

      // Get all participants
      let participants = self.get_call_participants(call_id).await?;

      let call_response = CallResponse {
         id: call.id,
         room_name: call.room_name,
         call_type: call.call_type,
         mode: call.mode,
         conversation_id: call.conversation_id,
         initiated_by: call.initiated_by,
         status: "active".to_string(),
         started_at: call.started_at.to_utc(),
         ended_at: call.ended_at.map(|dt| dt.to_utc()),
         duration: call.duration,
         participants,
      };

      Ok(JoinCallResponse { call: call_response, token })
   }

   /// End a call - returns (CallResponse, Option<(message_model, conversation_id)>)
   pub async fn end_call(&self, user_id: Uuid, call_id: Uuid) -> Result<(CallResponse, Option<(crate::entities::message::Model, Uuid)>)> {
      // Find call
      let call = call::Entity::find_by_id(call_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("Call not found"))?;

      // Check if user is part of the call
      let participant = call_participant::Entity::find()
         .filter(call_participant::Column::CallId.eq(call_id))
         .filter(call_participant::Column::UserId.eq(user_id))
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("User is not a participant in this call"))?;

      let now = Utc::now();

      // Update participant status
      if participant.status == "joined" && participant.joined_at.is_some() {
         let joined_at = participant.joined_at.unwrap();
         let duration_secs = (now.timestamp() - joined_at.to_utc().timestamp()) as i32;

         let mut participant_active: call_participant::ActiveModel = participant.into();
         participant_active.status = Set("left".to_string());
         participant_active.left_at = Set(Some(now.into()));
         participant_active.duration = Set(Some(duration_secs));
         participant_active.updated_at = Set(now.into());
         participant_active.update(&self.db).await?;
      }

      // End call if it's not already ended
      if call.status != "ended" {
         let started_at = call.started_at;
         let duration_secs = (now.timestamp() - started_at.to_utc().timestamp()) as i32;

         let mut call_active: call::ActiveModel = call.clone().into();
         call_active.status = Set("ended".to_string());
         call_active.ended_at = Set(Some(now.into()));
         call_active.duration = Set(Some(duration_secs));
         call_active.updated_at = Set(now.into());
         call_active.update(&self.db).await?;
      }

      // Get updated call data
      let updated_call = call::Entity::find_by_id(call_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("Call not found"))?;

      // Create call_log message
      let message_data = {
         let conversation_id = self.get_or_create_conversation_for_call(&updated_call).await?;
         let message = self.create_call_log_message(&updated_call, conversation_id).await?;
         Some((message, conversation_id))
      };

      let participants = self.get_call_participants(call_id).await?;

      let call_response = CallResponse {
         id: updated_call.id,
         room_name: updated_call.room_name,
         call_type: updated_call.call_type,
         mode: updated_call.mode,
         conversation_id: updated_call.conversation_id,
         initiated_by: updated_call.initiated_by,
         status: updated_call.status,
         started_at: updated_call.started_at.to_utc(),
         ended_at: updated_call.ended_at.map(|dt| dt.to_utc()),
         duration: updated_call.duration,
         participants,
      };

      Ok((call_response, message_data))
   }

   /// Get call history for a user
   pub async fn get_call_history(
      &self,
      user_id: Uuid,
      limit: u64,
      offset: u64,
   ) -> Result<CallHistoryResponse> {
      // Find all calls where user is a participant
      let participant_call_ids = call_participant::Entity::find()
         .filter(call_participant::Column::UserId.eq(user_id))
         .all(&self.db)
         .await?
         .into_iter()
         .map(|p| p.call_id)
         .collect::<Vec<_>>();

      let calls = call::Entity::find()
         .filter(call::Column::Id.is_in(participant_call_ids))
         .order_by_desc(call::Column::StartedAt)
         .limit(limit)
         .offset(offset)
         .all(&self.db)
         .await?;

      let total = calls.len();

      let mut call_responses = vec![];
      for call in calls {
         let participants = self.get_call_participants(call.id).await?;
         call_responses.push(CallResponse {
            id: call.id,
            room_name: call.room_name,
            call_type: call.call_type,
            mode: call.mode,
            conversation_id: call.conversation_id,
            initiated_by: call.initiated_by,
            status: call.status,
            started_at: call.started_at.to_utc(),
            ended_at: call.ended_at.map(|dt| dt.to_utc()),
            duration: call.duration,
            participants,
         });
      }

      Ok(CallHistoryResponse { calls: call_responses, total })
   }

   /// Get active calls for a user
   pub async fn get_active_calls(&self, user_id: Uuid) -> Result<ActiveCallsResponse> {
      // Find all active/ringing calls where user is a participant
      let participant_call_ids = call_participant::Entity::find()
         .filter(call_participant::Column::UserId.eq(user_id))
         .all(&self.db)
         .await?
         .into_iter()
         .map(|p| p.call_id)
         .collect::<Vec<_>>();

      let calls = call::Entity::find()
         .filter(call::Column::Id.is_in(participant_call_ids))
         .filter(call::Column::Status.eq("ringing").or(call::Column::Status.eq("active")))
         .order_by_desc(call::Column::StartedAt)
         .all(&self.db)
         .await?;

      let mut call_responses = vec![];
      for call in calls {
         let participants = self.get_call_participants(call.id).await?;
         call_responses.push(CallResponse {
            id: call.id,
            room_name: call.room_name,
            call_type: call.call_type,
            mode: call.mode,
            conversation_id: call.conversation_id,
            initiated_by: call.initiated_by,
            status: call.status,
            started_at: call.started_at.to_utc(),
            ended_at: call.ended_at.map(|dt| dt.to_utc()),
            duration: call.duration,
            participants,
         });
      }

      Ok(ActiveCallsResponse { calls: call_responses })
   }

   /// Get call by ID
   pub async fn get_call(&self, call_id: Uuid) -> Result<CallResponse> {
      let call = call::Entity::find_by_id(call_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("Call not found"))?;

      let participants = self.get_call_participants(call_id).await?;

      Ok(CallResponse {
         id: call.id,
         room_name: call.room_name,
         call_type: call.call_type,
         mode: call.mode,
         conversation_id: call.conversation_id,
         initiated_by: call.initiated_by,
         status: call.status,
         started_at: call.started_at.to_utc(),
         ended_at: call.ended_at.map(|dt| dt.to_utc()),
         duration: call.duration,
         participants,
      })
   }

   /// Helper: Get call participants
   async fn get_call_participants(&self, call_id: Uuid) -> Result<Vec<CallParticipantResponse>> {
      let participants = call_participant::Entity::find()
         .filter(call_participant::Column::CallId.eq(call_id))
         .all(&self.db)
         .await?;

      Ok(participants
         .into_iter()
         .map(|p| CallParticipantResponse {
            id: p.id,
            user_id: p.user_id,
            status: p.status,
            joined_at: p.joined_at.map(|dt| dt.to_utc()),
            left_at: p.left_at.map(|dt| dt.to_utc()),
            duration: p.duration,
         })
         .collect())
   }

   /// Helper: Generate LiveKit access token
   async fn generate_livekit_token(
      &self,
      user_id: Uuid,
      room_name: &str,
      can_publish: bool,
   ) -> Result<String> {
      let api_key = env::var("LIVEKIT_API_KEY").unwrap_or_else(|_| "devkey".to_string());
      let api_secret = env::var("LIVEKIT_API_SECRET").unwrap_or_else(|_| "secret".to_string());

      // Get user info
      let user = user::Entity::find_by_id(user_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("User not found"))?;

      let token = AccessToken::with_api_key(&api_key, &api_secret)
         .with_identity(&user_id.to_string())
         .with_name(&user.display_name)
         .with_grants(VideoGrants {
            room_join: true,
            room: room_name.to_string(),
            can_publish: Some(can_publish),
            can_subscribe: Some(true),
            can_publish_data: Some(true),
            ..Default::default()
         })
         .to_jwt()?;

      Ok(token)
   }

   /// Update user presence
   pub async fn update_presence(
      &self,
      user_id: Uuid,
      status: String,
   ) -> Result<UserPresenceResponse> {
      let now = Utc::now();

      // Try to find existing presence
      let existing = user_presence::Entity::find_by_id(user_id).one(&self.db).await?;

      if let Some(presence) = existing {
         // Update existing
         let mut active: user_presence::ActiveModel = presence.into();
         active.status = Set(status.clone());
         active.last_seen_at = Set(now.into());
         active.updated_at = Set(now.into());
         let updated = active.update(&self.db).await?;

         Ok(UserPresenceResponse {
            user_id: updated.user_id,
            status: updated.status,
            last_seen_at: updated.last_seen_at.to_utc(),
         })
      } else {
         // Create new
         let new_presence = user_presence::ActiveModel {
            user_id: Set(user_id),
            status: Set(status.clone()),
            last_seen_at: Set(now.into()),
            updated_at: Set(now.into()),
         };
         let created = new_presence.insert(&self.db).await?;

         Ok(UserPresenceResponse {
            user_id: created.user_id,
            status: created.status,
            last_seen_at: created.last_seen_at.to_utc(),
         })
      }
   }

   /// Get user presence
   pub async fn get_presence(&self, user_id: Uuid) -> Result<UserPresenceResponse> {
      let presence = user_presence::Entity::find_by_id(user_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("Presence not found"))?;

      Ok(UserPresenceResponse {
         user_id: presence.user_id,
         status: presence.status,
         last_seen_at: presence.last_seen_at.to_utc(),
      })
   }

   /// Get multiple users presence
   pub async fn get_presences(&self, user_ids: Vec<Uuid>) -> Result<Vec<UserPresenceResponse>> {
      let presences = user_presence::Entity::find()
         .filter(user_presence::Column::UserId.is_in(user_ids))
         .all(&self.db)
         .await?;

      Ok(presences
         .into_iter()
         .map(|p| UserPresenceResponse {
            user_id: p.user_id,
            status: p.status,
            last_seen_at: p.last_seen_at.to_utc(),
         })
         .collect())
   }

   /// Helper: Get user display name
   pub async fn get_user_name(&self, user_id: Uuid) -> Result<String> {
      let user = user::Entity::find_by_id(user_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("User not found"))?;

      Ok(user.display_name)
   }

   /// Helper: Get user info (username and display_name)
   pub async fn get_user_info(&self, user_id: Uuid) -> Result<(String, String)> {
      use crate::entities::account;

      let user = user::Entity::find_by_id(user_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("User not found"))?;

      let account = account::Entity::find_by_id(user.account_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("Account not found"))?;

      Ok((account.username, user.display_name))
   }

   /// Reject a call (for invited participants) - returns (CallResponse, Option<(message_model, conversation_id)>)
   pub async fn reject_call(&self, user_id: Uuid, call_id: Uuid) -> Result<(CallResponse, Option<(crate::entities::message::Model, Uuid)>)> {
      // Find call
      let call = call::Entity::find_by_id(call_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("Call not found"))?;

      // Check if call is still active
      if call.status != "ringing" {
         return Err(anyhow!("Call is not in ringing state"));
      }

      // Find participant record
      let participant = call_participant::Entity::find()
         .filter(call_participant::Column::CallId.eq(call_id))
         .filter(call_participant::Column::UserId.eq(user_id))
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("User is not a participant in this call"))?;

      let now = Utc::now();

      // Update participant status to 'rejected'
      let mut participant_active: call_participant::ActiveModel = participant.into();
      participant_active.status = Set("rejected".to_string());
      participant_active.updated_at = Set(now.into());
      participant_active.update(&self.db).await?;

      // Check if all participants rejected - if so, end the call
      let all_participants = call_participant::Entity::find()
         .filter(call_participant::Column::CallId.eq(call_id))
         .all(&self.db)
         .await?;

      let all_rejected = all_participants
         .iter()
         .filter(|p| p.user_id != call.initiated_by)
         .all(|p| p.status == "rejected");

      if all_rejected {
         let mut call_active: call::ActiveModel = call.clone().into();
         call_active.status = Set("rejected".to_string());
         call_active.ended_at = Set(Some(now.into()));
         call_active.updated_at = Set(now.into());
         call_active.update(&self.db).await?;
      }

      // Get updated call data
      let updated_call = call::Entity::find_by_id(call_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("Call not found"))?;

      // Create call_log message if call is rejected
      let message_data = if updated_call.status == "rejected" {
         let conversation_id = self.get_or_create_conversation_for_call(&updated_call).await?;
         let message = self.create_call_log_message(&updated_call, conversation_id).await?;
         Some((message, conversation_id))
      } else {
         None
      };

      let participants = self.get_call_participants(call_id).await?;

      let call_response = CallResponse {
         id: updated_call.id,
         room_name: updated_call.room_name,
         call_type: updated_call.call_type,
         mode: updated_call.mode,
         conversation_id: updated_call.conversation_id,
         initiated_by: updated_call.initiated_by,
         status: updated_call.status,
         started_at: updated_call.started_at.to_utc(),
         ended_at: updated_call.ended_at.map(|dt| dt.to_utc()),
         duration: updated_call.duration,
         participants,
      };

      Ok((call_response, message_data))
   }

   /// Cancel a call (for initiator only) - returns (CallResponse, Option<(message_model, conversation_id)>)
   pub async fn cancel_call(&self, user_id: Uuid, call_id: Uuid) -> Result<(CallResponse, Option<(crate::entities::message::Model, Uuid)>)> {
      // Find call
      let call = call::Entity::find_by_id(call_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("Call not found"))?;

      // Check if user is the initiator
      if call.initiated_by != user_id {
         return Err(anyhow!("Only the initiator can cancel the call"));
      }

      // Check if call is still in ringing state
      if call.status != "ringing" {
         return Err(anyhow!("Call cannot be cancelled in current state"));
      }

      let now = Utc::now();

      // Update call status to 'missed'
      let mut call_active: call::ActiveModel = call.clone().into();
      call_active.status = Set("missed".to_string());
      call_active.ended_at = Set(Some(now.into()));
      call_active.updated_at = Set(now.into());
      call_active.update(&self.db).await?;

      // Update all participant statuses to 'missed'
      call_participant::Entity::update_many()
         .filter(call_participant::Column::CallId.eq(call_id))
         .col_expr(call_participant::Column::Status, Expr::value("missed"))
         .col_expr(call_participant::Column::UpdatedAt, Expr::value(now))
         .exec(&self.db)
         .await?;

      // Get updated call data
      let updated_call = call::Entity::find_by_id(call_id)
         .one(&self.db)
         .await?
         .ok_or_else(|| anyhow!("Call not found"))?;

      // Create call_log message
      let message_data = {
         let conversation_id = self.get_or_create_conversation_for_call(&updated_call).await?;
         let message = self.create_call_log_message(&updated_call, conversation_id).await?;
         Some((message, conversation_id))
      };

      let participants = self.get_call_participants(call_id).await?;

      let call_response = CallResponse {
         id: updated_call.id,
         room_name: updated_call.room_name,
         call_type: updated_call.call_type,
         mode: updated_call.mode,
         conversation_id: updated_call.conversation_id,
         initiated_by: updated_call.initiated_by,
         status: updated_call.status,
         started_at: updated_call.started_at.to_utc(),
         ended_at: updated_call.ended_at.map(|dt| dt.to_utc()),
         duration: updated_call.duration,
         participants,
      };

      Ok((call_response, message_data))
   }

   /// Helper: Get or create conversation for call
   async fn get_or_create_conversation_for_call(&self, call: &call::Model) -> Result<Uuid> {
      // If call already has conversation_id, use it
      if let Some(conv_id) = call.conversation_id {
         return Ok(conv_id);
      }

      // For direct calls, find or create direct conversation between initiator and the other participant
      if call.mode == "direct" {
         let participants = call_participant::Entity::find()
            .filter(call_participant::Column::CallId.eq(call.id))
            .all(&self.db)
            .await?;

         let other_user_id = participants
            .iter()
            .find(|p| p.user_id != call.initiated_by)
            .map(|p| p.user_id)
            .ok_or_else(|| anyhow!("Could not find other participant"))?;

         return self
            .find_or_create_direct_conversation_for_call(call.initiated_by, other_user_id)
            .await;
      }

      // For group calls without conversation_id, this shouldn't happen
      Err(anyhow!("Group call must have conversation_id"))
   }

   /// Helper: Find or create direct conversation between two users
   async fn find_or_create_direct_conversation_for_call(
      &self,
      user_id1: Uuid,
      user_id2: Uuid,
   ) -> Result<Uuid> {
      use crate::entities::{conversation, conversation_member};
      use crate::entities::conversation::ConversationType;

      // Try to find existing direct conversation
      let existing = conversation::Entity::find()
         .filter(conversation::Column::Type.eq(ConversationType::Direct))
         .filter(conversation::Column::DeletedAt.is_null())
         .inner_join(conversation_member::Entity)
         .filter(
            Condition::any()
               .add(conversation_member::Column::UserId.eq(user_id1))
               .add(conversation_member::Column::UserId.eq(user_id2)),
         )
         .group_by(conversation::Column::Id)
         .having(sea_orm::sea_query::Expr::cust(
            "COUNT(DISTINCT conversation_member.user_id) = 2",
         ))
         .one(&self.db)
         .await?;

      if let Some(conv) = existing {
         return Ok(conv.id);
      }

      // Create new conversation
      let now = Utc::now();
      let conv_id = Uuid::now_v7();

      let new_conv = conversation::ActiveModel {
         id: Set(conv_id),
         r#type: Set(ConversationType::Direct),
         title: Set(None),
         avatar_url: Set(None),
         description: Set(None),
         banner_url: Set(None),
         pinned_message_id: Set(None),
         created_by: Set(user_id1),
         created_at: Set(now.into()),
         updated_at: Set(now.into()),
         deleted_at: Set(None),
      };

      new_conv.insert(&self.db).await?;

      // Add both users as members
      let member1 = conversation_member::ActiveModel {
         id: Set(Uuid::now_v7()),
         conversation_id: Set(conv_id),
         user_id: Set(user_id1),
         role: Set(conversation_member::MemberRole::Member),
         last_read_message_id: Set(None),
         joined_at: Set(now.into()),
         left_at: Set(None),
      };

      let member2 = conversation_member::ActiveModel {
         id: Set(Uuid::now_v7()),
         conversation_id: Set(conv_id),
         user_id: Set(user_id2),
         role: Set(conversation_member::MemberRole::Member),
         last_read_message_id: Set(None),
         joined_at: Set(now.into()),
         left_at: Set(None),
      };

      member1.insert(&self.db).await?;
      member2.insert(&self.db).await?;

      Ok(conv_id)
   }

   /// Helper: Create a call_log message in conversation and return the message model
   async fn create_call_log_message(
      &self,
      call: &call::Model,
      conversation_id: Uuid,
   ) -> Result<crate::entities::message::Model> {
      use crate::entities::message::{self, MessageType, MessageStatus};
      use serde_json::json;

      let now = Utc::now();
      let message_id = Uuid::now_v7();

      // Determine call status for log
      let log_status = match call.status.as_str() {
         "ended" => "completed",
         "rejected" => "rejected",
         "missed" => "missed",
         _ => "cancelled",
      };

      // Build JSON metadata
      let metadata = json!({
         "call_id": call.id.to_string(),
         "call_type": call.call_type,
         "mode": call.mode,
         "status": log_status,
         "duration": call.duration,
         "started_at": call.started_at.to_rfc3339(),
         "ended_at": call.ended_at.map(|dt| dt.to_rfc3339()),
      });

      let message = message::ActiveModel {
         id: Set(message_id),
         conversation_id: Set(conversation_id),
         sender_id: Set(call.initiated_by),
         reply_to_message_id: Set(None),
         message_type: Set(MessageType::CallLog),
         content: Set(Some(metadata.to_string())),
         status: Set(MessageStatus::Sent),
         created_at: Set(now.into()),
         updated_at: Set(now.into()),
         deleted_at: Set(None),
      };

      let created = message.insert(&self.db).await?;

      // Update conversation's updated_at timestamp
      use crate::entities::conversation;
      conversation::Entity::update_many()
         .filter(conversation::Column::Id.eq(conversation_id))
         .col_expr(conversation::Column::UpdatedAt, Expr::value(now))
         .exec(&self.db)
         .await?;

      Ok(created)
   }

   /// Helper: Get conversation member IDs (excluding initiator)
   async fn get_conversation_member_ids(&self, conversation_id: Uuid, initiator_id: Uuid) -> Result<Vec<Uuid>> {
      use crate::entities::conversation_member;

      let members = conversation_member::Entity::find()
         .filter(conversation_member::Column::ConversationId.eq(conversation_id))
         .filter(conversation_member::Column::LeftAt.is_null())
         .all(&self.db)
         .await?;

      let member_ids: Vec<Uuid> = members
         .into_iter()
         .map(|m| m.user_id)
         .filter(|uid| *uid != initiator_id)
         .collect();

      tracing::info!("Found {} members in conversation {} (excluding initiator)", member_ids.len(), conversation_id);

      Ok(member_ids)
   }
}
