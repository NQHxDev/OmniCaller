use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "calls")]
pub struct Model {
   #[sea_orm(primary_key, auto_increment = false)]
   pub id: Uuid,
   #[sea_orm(unique)]
   pub room_name: String,
   #[sea_orm(column_name = "type")]
   pub call_type: String, // 'voice' or 'video'
   pub mode: String, // 'direct' or 'group'
   pub conversation_id: Option<Uuid>,
   pub initiated_by: Uuid,
   pub status: String, // 'ringing', 'active', 'ended', 'missed', 'rejected'
   pub started_at: DateTimeWithTimeZone,
   pub ended_at: Option<DateTimeWithTimeZone>,
   pub duration: Option<i32>, // Duration in seconds
   pub created_at: DateTimeWithTimeZone,
   pub updated_at: DateTimeWithTimeZone,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
   #[sea_orm(
      belongs_to = "super::user::Entity",
      from = "Column::InitiatedBy",
      to = "super::user::Column::Id",
      on_update = "Cascade",
      on_delete = "Cascade"
   )]
   Initiator,
   #[sea_orm(
      belongs_to = "super::conversation::Entity",
      from = "Column::ConversationId",
      to = "super::conversation::Column::Id",
      on_update = "Cascade",
      on_delete = "SetNull"
   )]
   Conversation,
   #[sea_orm(has_many = "super::call_participant::Entity")]
   CallParticipants,
}

impl Related<super::user::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Initiator.def()
   }
}

impl Related<super::conversation::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Conversation.def()
   }
}

impl Related<super::call_participant::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::CallParticipants.def()
   }
}

impl ActiveModelBehavior for ActiveModel {}
