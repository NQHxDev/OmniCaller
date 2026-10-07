use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Serialize, Deserialize)]
#[sea_orm(table_name = "user_presence")]
pub struct Model {
   #[sea_orm(primary_key, auto_increment = false)]
   pub user_id: Uuid,
   pub status: String, // 'online', 'offline', 'busy', 'in_call'
   pub last_seen_at: DateTimeWithTimeZone,
   pub updated_at: DateTimeWithTimeZone,
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
}

impl Related<super::user::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::User.def()
   }
}

impl ActiveModelBehavior for ActiveModel {}
