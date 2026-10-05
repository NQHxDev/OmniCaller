use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(table_name = "message")]
pub struct Model {
   #[sea_orm(primary_key, auto_increment = false)]
   pub id: Uuid,

   pub conversation_id: Uuid,
   pub sender_id: Uuid,
   pub reply_to_message_id: Option<Uuid>,

   #[sea_orm(column_type = "String(StringLen::N(20))")]
   pub message_type: MessageType,

   #[sea_orm(column_type = "Text")]
   pub content: Option<String>,

   #[sea_orm(column_type = "String(StringLen::N(20))")]
   pub status: MessageStatus,

   pub created_at: DateTimeWithTimeZone,
   pub updated_at: DateTimeWithTimeZone,
   pub deleted_at: Option<DateTimeWithTimeZone>,
}

#[derive(Debug, Clone, PartialEq, Eq, EnumIter, DeriveActiveEnum, Serialize, Deserialize)]
#[sea_orm(rs_type = "String", db_type = "String(StringLen::N(20))")]
pub enum MessageType {
   #[sea_orm(string_value = "text")]
   Text,
   #[sea_orm(string_value = "image")]
   Image,
   #[sea_orm(string_value = "video")]
   Video,
   #[sea_orm(string_value = "audio")]
   Audio,
   #[sea_orm(string_value = "file")]
   File,
   #[sea_orm(string_value = "call_log")]
   CallLog,
   #[sea_orm(string_value = "system")]
   System,
}

#[derive(Debug, Clone, PartialEq, Eq, EnumIter, DeriveActiveEnum, Serialize, Deserialize)]
#[sea_orm(rs_type = "String", db_type = "String(StringLen::N(20))")]
pub enum MessageStatus {
   #[sea_orm(string_value = "sent")]
   Sent,
   #[sea_orm(string_value = "delivered")]
   Delivered,
   #[sea_orm(string_value = "read")]
   Read,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
   #[sea_orm(
      belongs_to = "super::conversation::Entity",
      from = "Column::ConversationId",
      to = "super::conversation::Column::Id",
      on_update = "Cascade",
      on_delete = "Cascade"
   )]
   Conversation,

   #[sea_orm(
      belongs_to = "super::user::Entity",
      from = "Column::SenderId",
      to = "super::user::Column::Id",
      on_update = "Cascade",
      on_delete = "Cascade"
   )]
   Sender,

   #[sea_orm(
      belongs_to = "Entity",
      from = "Column::ReplyToMessageId",
      to = "Column::Id",
      on_update = "Cascade",
      on_delete = "SetNull"
   )]
   ReplyTo,

   #[sea_orm(has_many = "super::message_attachment::Entity")]
   Attachments,
}

impl Related<super::conversation::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Conversation.def()
   }
}

impl Related<super::user::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Sender.def()
   }
}

impl Related<super::message_attachment::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Attachments.def()
   }
}

impl ActiveModelBehavior for ActiveModel {}

impl Model {
   pub fn is_deleted(&self) -> bool {
      self.deleted_at.is_some()
   }

   pub fn is_text(&self) -> bool {
      self.message_type == MessageType::Text
   }

   pub fn is_media(&self) -> bool {
      matches!(
         self.message_type,
         MessageType::Image | MessageType::Video | MessageType::Audio | MessageType::File
      )
   }

   pub fn is_system(&self) -> bool {
      self.message_type == MessageType::System
   }

   pub fn is_reply(&self) -> bool {
      self.reply_to_message_id.is_some()
   }

   pub fn is_sent(&self) -> bool {
      self.status == MessageStatus::Sent
   }

   pub fn is_delivered(&self) -> bool {
      self.status == MessageStatus::Delivered
   }

   pub fn is_read(&self) -> bool {
      self.status == MessageStatus::Read
   }
}
