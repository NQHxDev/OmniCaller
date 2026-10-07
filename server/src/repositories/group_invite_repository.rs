use crate::entities::{conversation, group_invite, user};
use sea_orm::*;
use uuid::Uuid;

pub struct GroupInviteRepository;

impl GroupInviteRepository {
   /// Create a new group invite
   pub async fn create(
      db: &DatabaseConnection,
      conversation_id: Uuid,
      inviter_id: Uuid,
      code: String,
      max_uses: Option<i32>,
      expires_at: Option<chrono::DateTime<chrono::Utc>>,
   ) -> Result<group_invite::Model, DbErr> {
      let now = chrono::Utc::now();
      let expires_at_tz = expires_at.map(|dt| dt.into());

      let invite = group_invite::ActiveModel {
         id: Set(Uuid::now_v7()),
         conversation_id: Set(conversation_id),
         inviter_id: Set(inviter_id),
         code: Set(code),
         max_uses: Set(max_uses),
         uses_count: Set(0),
         expires_at: Set(expires_at_tz),
         created_at: Set(now.into()),
         revoked_at: Set(None),
      };

      invite.insert(db).await
   }

   /// Find invite by code
   pub async fn find_by_code(
      db: &DatabaseConnection,
      code: &str,
   ) -> Result<Option<group_invite::Model>, DbErr> {
      group_invite::Entity::find()
         .filter(group_invite::Column::Code.eq(code))
         .one(db)
         .await
   }

   /// Find invite by id with conversation and inviter
   pub async fn find_by_id_with_details(
      db: &DatabaseConnection,
      invite_id: Uuid,
   ) -> Result<Option<(group_invite::Model, conversation::Model, user::Model)>, DbErr> {
      group_invite::Entity::find_by_id(invite_id)
         .find_also_related(conversation::Entity)
         .find_also_related(user::Entity)
         .one(db)
         .await
         .map(|result| {
            result.and_then(|(invite, conv_opt, user_opt)| {
               conv_opt.and_then(|conv| user_opt.map(|user| (invite, conv, user)))
            })
         })
   }

   /// Find invite by code with conversation and inviter details
   pub async fn find_by_code_with_details(
      db: &DatabaseConnection,
      code: &str,
   ) -> Result<Option<(group_invite::Model, conversation::Model, user::Model)>, DbErr> {
      let invite_opt = group_invite::Entity::find()
         .filter(group_invite::Column::Code.eq(code))
         .find_also_related(conversation::Entity)
         .one(db)
         .await?;

      if let Some((invite, Some(conversation))) = invite_opt {
         let inviter = user::Entity::find_by_id(invite.inviter_id).one(db).await?;
         if let Some(inviter) = inviter {
            return Ok(Some((invite, conversation, inviter)));
         }
      }

      Ok(None)
   }

   /// List all invites for a conversation
   pub async fn find_by_conversation(
      db: &DatabaseConnection,
      conversation_id: Uuid,
   ) -> Result<Vec<group_invite::Model>, DbErr> {
      group_invite::Entity::find()
         .filter(group_invite::Column::ConversationId.eq(conversation_id))
         .order_by_desc(group_invite::Column::CreatedAt)
         .all(db)
         .await
   }

   /// Increment uses count
   pub async fn increment_uses(
      db: &DatabaseConnection,
      invite_id: Uuid,
   ) -> Result<group_invite::Model, DbErr> {
      let invite = group_invite::Entity::find_by_id(invite_id)
         .one(db)
         .await?
         .ok_or(DbErr::RecordNotFound("Group invite not found".to_string()))?;

      let mut active_invite: group_invite::ActiveModel = invite.into();
      active_invite.uses_count = Set(active_invite.uses_count.unwrap() + 1);

      active_invite.update(db).await
   }

   /// Revoke an invite
   pub async fn revoke(
      db: &DatabaseConnection,
      invite_id: Uuid,
   ) -> Result<group_invite::Model, DbErr> {
      let invite = group_invite::Entity::find_by_id(invite_id)
         .one(db)
         .await?
         .ok_or(DbErr::RecordNotFound("Group invite not found".to_string()))?;

      let mut active_invite: group_invite::ActiveModel = invite.into();
      active_invite.revoked_at = Set(Some(chrono::Utc::now().into()));

      active_invite.update(db).await
   }

   /// Delete expired invites (cleanup job)
   pub async fn delete_expired(db: &DatabaseConnection) -> Result<DeleteResult, DbErr> {
      let now = chrono::Utc::now();
      group_invite::Entity::delete_many()
         .filter(group_invite::Column::ExpiresAt.lt(now))
         .exec(db)
         .await
   }

   /// Check if invite is valid
   pub fn is_valid(invite: &group_invite::Model) -> bool {
      invite.is_valid()
   }
}
