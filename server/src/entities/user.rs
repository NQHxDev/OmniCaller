use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(table_name = "user")]
pub struct Model {
   #[sea_orm(primary_key, auto_increment = false)]
   pub id: Uuid,

   #[sea_orm(unique)]
   pub account_id: Uuid,

   #[sea_orm(column_type = "String(StringLen::N(100))")]
   pub display_name: String,

   pub created_at: DateTimeWithTimeZone,
   pub updated_at: DateTimeWithTimeZone,
   pub deleted_at: Option<DateTimeWithTimeZone>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
   #[sea_orm(
      belongs_to = "super::account::Entity",
      from = "Column::AccountId",
      to = "super::account::Column::Id",
      on_update = "Cascade",
      on_delete = "Cascade"
   )]
   Account,
}

impl Related<super::account::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Account.def()
   }
}

impl ActiveModelBehavior for ActiveModel {}

impl Model {
   pub fn is_deleted(&self) -> bool {
      self.deleted_at.is_some()
   }
}
