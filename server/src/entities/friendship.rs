use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(table_name = "friendship")]
pub struct Model {
   #[sea_orm(primary_key, auto_increment = false)]
   pub id: Uuid,

   pub user_id: Uuid,
   pub friend_id: Uuid,

   #[sea_orm(column_type = "String(StringLen::N(20))")]
   pub status: FriendshipStatus,

   pub requested_at: DateTimeWithTimeZone,
   pub responded_at: Option<DateTimeWithTimeZone>,

   pub created_at: DateTimeWithTimeZone,
   pub updated_at: DateTimeWithTimeZone,
   pub deleted_at: Option<DateTimeWithTimeZone>,
}

#[derive(Debug, Clone, PartialEq, Eq, EnumIter, DeriveActiveEnum, Serialize, Deserialize)]
#[sea_orm(rs_type = "String", db_type = "String(StringLen::N(20))")]
pub enum FriendshipStatus {
   #[sea_orm(string_value = "pending")]
   Pending,
   #[sea_orm(string_value = "accepted")]
   Accepted,
   #[sea_orm(string_value = "rejected")]
   Rejected,
   #[sea_orm(string_value = "blocked")]
   Blocked,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
   #[sea_orm(
      belongs_to = "super::user::Entity",
      from = "Column::UserId",
      to = "super::user::Column::Id",
      on_update = "Cascade",
      on_delete = "Cascade"
   )]
   User,
   #[sea_orm(
      belongs_to = "super::user::Entity",
      from = "Column::FriendId",
      to = "super::user::Column::Id",
      on_update = "Cascade",
      on_delete = "Cascade"
   )]
   Friend,
}

impl Related<super::user::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::User.def()
   }
}

impl ActiveModelBehavior for ActiveModel {}

impl Model {
   pub fn is_deleted(&self) -> bool {
      self.deleted_at.is_some()
   }

   pub fn is_pending(&self) -> bool {
      self.status == FriendshipStatus::Pending
   }

   pub fn is_accepted(&self) -> bool {
      self.status == FriendshipStatus::Accepted
   }

   pub fn is_rejected(&self) -> bool {
      self.status == FriendshipStatus::Rejected
   }

   pub fn is_blocked(&self) -> bool {
      self.status == FriendshipStatus::Blocked
   }
}
