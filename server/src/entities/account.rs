use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(table_name = "account")]
pub struct Model {
   #[sea_orm(primary_key, auto_increment = false)]
   pub id: Uuid,

   #[sea_orm(unique, column_type = "String(StringLen::N(30))")]
   pub username: String,

   #[sea_orm(column_type = "String(StringLen::N(255))")]
   pub password: String,

   pub created_at: DateTimeWithTimeZone,
   pub updated_at: DateTimeWithTimeZone,
   pub deleted_at: Option<DateTimeWithTimeZone>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
   #[sea_orm(has_one = "super::user::Entity")]
   User,
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
}
