use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// Request DTOs
#[derive(Debug, Deserialize, Serialize)]
pub struct InitiateCallDto {
   pub call_type: String,             // 'voice' or 'video'
   pub mode: String,                  // 'direct' or 'group'
   pub conversation_id: Option<Uuid>, // Required for group calls
   pub participant_ids: Vec<Uuid>,    // For direct call: 1 user, for group: multiple users
}

#[derive(Debug, Deserialize, Serialize)]
pub struct JoinCallDto {
   pub call_id: Uuid,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct EndCallDto {
   pub call_id: Uuid,
}

// Response DTOs
#[derive(Debug, Serialize, Deserialize)]
pub struct CallResponse {
   pub id: Uuid,
   pub room_name: String,
   pub call_type: String,
   pub mode: String,
   pub conversation_id: Option<Uuid>,
   pub initiated_by: Uuid,
   pub status: String,
   pub started_at: DateTime<Utc>,
   pub ended_at: Option<DateTime<Utc>>,
   pub duration: Option<i32>,
   pub participants: Vec<CallParticipantResponse>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CallParticipantResponse {
   pub id: Uuid,
   pub user_id: Uuid,
   pub status: String,
   pub joined_at: Option<DateTime<Utc>>,
   pub left_at: Option<DateTime<Utc>>,
   pub duration: Option<i32>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct InitiateCallResponse {
   pub call: CallResponse,
   pub token: String, // LiveKit access token for initiator
}

#[derive(Debug, Serialize, Deserialize)]
pub struct JoinCallResponse {
   pub call: CallResponse,
   pub token: String, // LiveKit access token for participant
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CallHistoryResponse {
   pub calls: Vec<CallResponse>,
   pub total: usize,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ActiveCallsResponse {
   pub calls: Vec<CallResponse>,
}

// WebSocket call messages
#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(tag = "type")]
pub enum WsCallMessage {
   // Incoming call notification
   IncomingCall {
      call_id: Uuid,
      room_name: String,
      call_type: String,
      mode: String,
      initiated_by: Uuid,
      initiator_name: String,
      conversation_id: Option<Uuid>,
   },
   // Call status update
   CallStatusUpdate {
      call_id: Uuid,
      status: String,
   },
   // Participant joined
   ParticipantJoined {
      call_id: Uuid,
      user_id: Uuid,
      username: String,
   },
   // Participant left
   ParticipantLeft {
      call_id: Uuid,
      user_id: Uuid,
      username: String,
   },
   // Call ended
   CallEnded {
      call_id: Uuid,
      ended_by: Uuid,
      duration: Option<i32>,
   },
}

// Presence DTOs
#[derive(Debug, Serialize, Deserialize)]
pub struct UserPresenceResponse {
   pub user_id: Uuid,
   pub status: String,
   pub last_seen_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdatePresenceDto {
   pub status: String, // 'online', 'offline', 'busy', 'in_call'
}
