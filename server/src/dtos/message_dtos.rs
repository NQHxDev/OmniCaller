use crate::entities::conversation::ConversationType;
use crate::entities::message::{MessageStatus, MessageType};
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

// Request DTOs
#[derive(Debug, Deserialize, Validate)]
pub struct CreateDirectConversationDto {
   #[validate(length(min = 1, message = "Friend username is required"))]
   pub friend_username: String,
}

#[derive(Debug, Deserialize, Validate)]
pub struct SendMessageDto {
   pub conversation_id: Uuid,

   #[validate(length(
      min = 1,
      max = 5000,
      message = "Message content must be between 1 and 5000 characters"
   ))]
   pub content: String,

   pub reply_to_message_id: Option<Uuid>,
}

#[derive(Debug, Deserialize)]
pub struct GetMessagesQuery {
   pub cursor: Option<Uuid>, // message_id to start from
   pub limit: Option<u64>,   // default 30
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateMessageStatusDto {
   pub message_id: Uuid,
   pub status: MessageStatus,
}

// Response DTOs
#[derive(Debug, Serialize)]
pub struct ConversationDto {
   pub id: Uuid,
   pub r#type: ConversationType,
   pub title: Option<String>,
   pub avatar_url: Option<String>,
   pub other_user: Option<ConversationUserDto>,
   pub last_message: Option<MessageDto>,
   pub unread_count: u64,
   pub created_at: DateTime<Utc>,
   pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct ConversationUserDto {
   pub user_id: Uuid,
   pub username: String,
   pub display_name: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MessageDto {
   pub id: Uuid,
   pub conversation_id: Uuid,
   pub sender_id: Uuid,
   pub sender_username: String,
   pub sender_display_name: String,
   pub reply_to_message_id: Option<Uuid>,
   pub message_type: MessageType,
   pub content: Option<String>,
   pub status: MessageStatus,
   pub created_at: DateTime<Utc>,
   pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct MessagesResponse {
   pub messages: Vec<MessageDto>,
   pub next_cursor: Option<Uuid>,
   pub has_more: bool,
}

#[derive(Debug, Serialize)]
pub struct ConversationsResponse {
   pub conversations: Vec<ConversationDto>,
   pub total: usize,
}

// WebSocket Event DTOs
#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum WsClientMessage {
   // Client -> Server
   SendMessage {
      conversation_id: Uuid,
      content: String,
      reply_to_message_id: Option<Uuid>,
   },
   TypingStart {
      conversation_id: Uuid,
   },
   TypingStop {
      conversation_id: Uuid,
   },
   MessageDelivered {
      message_id: Uuid,
   },
   MessageRead {
      message_id: Uuid,
   },
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum WsServerMessage {
   // Server -> Client - Messages
   MessageNew {
      message: MessageDto,
   },
   MessageStatus {
      message_id: Uuid,
      status: MessageStatus,
   },
   TypingStart {
      conversation_id: Uuid,
      user_id: Uuid,
      username: String,
   },
   TypingStop {
      conversation_id: Uuid,
      user_id: Uuid,
   },
   
   // Server -> Client - Calls
   IncomingCall {
      call_id: Uuid,
      room_name: String,
      call_type: String,
      mode: String,
      initiated_by: Uuid,
      initiator_name: String,
      conversation_id: Option<Uuid>,
   },
   CallStatusUpdate {
      call_id: Uuid,
      status: String,
   },
   ParticipantJoined {
      call_id: Uuid,
      user_id: Uuid,
      username: String,
   },
   ParticipantLeft {
      call_id: Uuid,
      user_id: Uuid,
      username: String,
   },
   CallEnded {
      call_id: Uuid,
      ended_by: Uuid,
      duration: Option<i32>,
   },
   
   // Server -> Client - Presence
   PresenceUpdate {
      user_id: Uuid,
      status: String,
   },
   
   // General
   Error {
      message: String,
   },
   Connected {
      user_id: Uuid,
   },
}
