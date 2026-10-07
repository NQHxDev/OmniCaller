use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "call_participants")]
pub struct Model {
   #[sea_orm(primary_key, auto_increment = false)]
   pub id: Uuid,
   pub call_id: Uuid,
   pub user_id: Uuid,
   pub status: String, // 'invited', 'ringing', 'joined', 'left', 'rejected', 'missed'
   pub joined_at: Option<DateTimeWithTimeZone>,
   pub left_at: Option<DateTimeWithTimeZone>,
   pub duration: Option<i32>, // Duration in seconds
   pub created_at: DateTimeWithTimeZone,
   pub updated_at: DateTimeWithTimeZone,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
   #[sea_orm(
      belongs_to = "super::call::Entity",
      from = "Column::CallId",
      to = "super::call::Column::Id",
      on_update = "Cascade",
      on_delete = "Cascade"
   )]
   Call,
   #[sea_orm(
      belongs_to = "super::user::Entity",
      from = "Column::UserId",
      to = "super::user::Column::Id",
      on_update = "Cascade",
      on_delete = "Cascade"
   )]
   User,
}

impl Related<super::call::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Call.def()
   }
}

impl Related<super::user::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::User.def()
   }
}

impl ActiveModelBehavior for ActiveModel {}
