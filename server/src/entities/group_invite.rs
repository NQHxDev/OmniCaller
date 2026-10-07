use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(table_name = "group_invite")]
pub struct Model {
   #[sea_orm(primary_key, auto_increment = false)]
   pub id: Uuid,

   pub conversation_id: Uuid,
   pub inviter_id: Uuid,

   #[sea_orm(column_type = "String(StringLen::N(32))", unique)]
   pub code: String,

   pub max_uses: Option<i32>,
   pub uses_count: i32,

   pub expires_at: Option<DateTimeWithTimeZone>,
   pub created_at: DateTimeWithTimeZone,
   pub revoked_at: Option<DateTimeWithTimeZone>,
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
      from = "Column::InviterId",
      to = "super::user::Column::Id",
      on_update = "Cascade",
      on_delete = "Cascade"
   )]
   Inviter,
}

impl Related<super::conversation::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Conversation.def()
   }
}

impl Related<super::user::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Inviter.def()
   }
}

impl ActiveModelBehavior for ActiveModel {}

impl Model {
   pub fn is_expired(&self) -> bool {
      if let Some(expires_at) = self.expires_at {
         let now: DateTimeWithTimeZone = chrono::Utc::now().into();
         expires_at < now
      } else {
         false
      }
   }

   pub fn is_revoked(&self) -> bool {
      self.revoked_at.is_some()
   }

   pub fn is_max_uses_reached(&self) -> bool {
      if let Some(max_uses) = self.max_uses {
         self.uses_count >= max_uses
      } else {
         false
      }
   }

   pub fn is_valid(&self) -> bool {
      !self.is_expired() && !self.is_revoked() && !self.is_max_uses_reached()
   }
}
