use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(table_name = "conversation_member")]
pub struct Model {
   #[sea_orm(primary_key, auto_increment = false)]
   pub id: Uuid,

   pub conversation_id: Uuid,
   pub user_id: Uuid,

   #[sea_orm(column_type = "String(StringLen::N(20))")]
   pub role: MemberRole,

   pub last_read_message_id: Option<Uuid>,

   pub joined_at: DateTimeWithTimeZone,
   pub left_at: Option<DateTimeWithTimeZone>,
}

#[derive(Debug, Clone, PartialEq, Eq, EnumIter, DeriveActiveEnum, Serialize, Deserialize)]
#[sea_orm(rs_type = "String", db_type = "String(StringLen::N(20))")]
pub enum MemberRole {
   #[sea_orm(string_value = "owner")]
   Owner,
   #[sea_orm(string_value = "admin")]
   Admin,
   #[sea_orm(string_value = "member")]
   Member,
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
      from = "Column::UserId",
      to = "super::user::Column::Id",
      on_update = "Cascade",
      on_delete = "Cascade"
   )]
   User,

   #[sea_orm(
      belongs_to = "super::message::Entity",
      from = "Column::LastReadMessageId",
      to = "super::message::Column::Id",
      on_update = "Cascade",
      on_delete = "SetNull"
   )]
   LastReadMessage,
}

impl Related<super::conversation::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Conversation.def()
   }
}

impl Related<super::user::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::User.def()
   }
}

impl Related<super::message::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::LastReadMessage.def()
   }
}

impl ActiveModelBehavior for ActiveModel {}

impl Model {
   pub fn is_active(&self) -> bool {
      self.left_at.is_none()
   }

   pub fn has_left(&self) -> bool {
      self.left_at.is_some()
   }

   pub fn is_owner(&self) -> bool {
      self.role == MemberRole::Owner
   }

   pub fn is_admin(&self) -> bool {
      self.role == MemberRole::Admin
   }

   pub fn is_member(&self) -> bool {
      self.role == MemberRole::Member
   }

   pub fn can_manage(&self) -> bool {
      self.role == MemberRole::Owner || self.role == MemberRole::Admin
   }
}
