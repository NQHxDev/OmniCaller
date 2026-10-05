use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(table_name = "conversation")]
pub struct Model {
   #[sea_orm(primary_key, auto_increment = false)]
   pub id: Uuid,

   #[sea_orm(column_type = "String(StringLen::N(20))")]
   pub r#type: ConversationType,

   #[sea_orm(column_type = "String(StringLen::N(100))")]
   pub title: Option<String>,

   #[sea_orm(column_type = "String(StringLen::N(255))")]
   pub avatar_url: Option<String>,

   pub created_by: Uuid,

   pub created_at: DateTimeWithTimeZone,
   pub updated_at: DateTimeWithTimeZone,
   pub deleted_at: Option<DateTimeWithTimeZone>,
}

#[derive(Debug, Clone, PartialEq, Eq, EnumIter, DeriveActiveEnum, Serialize, Deserialize)]
#[sea_orm(rs_type = "String", db_type = "String(StringLen::N(20))")]
pub enum ConversationType {
   #[sea_orm(string_value = "direct")]
   Direct,
   #[sea_orm(string_value = "group")]
   Group,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
   #[sea_orm(
      belongs_to = "super::user::Entity",
      from = "Column::CreatedBy",
      to = "super::user::Column::Id",
      on_update = "Cascade",
      on_delete = "Cascade"
   )]
   Creator,

   #[sea_orm(has_many = "super::conversation_member::Entity")]
   Members,

   #[sea_orm(has_many = "super::message::Entity")]
   Messages,
}

impl Related<super::user::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Creator.def()
   }
}

impl Related<super::conversation_member::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Members.def()
   }
}

impl Related<super::message::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Messages.def()
   }
}

impl ActiveModelBehavior for ActiveModel {}

impl Model {
   pub fn is_deleted(&self) -> bool {
      self.deleted_at.is_some()
   }

   pub fn is_direct(&self) -> bool {
      self.r#type == ConversationType::Direct
   }

   pub fn is_group(&self) -> bool {
      self.r#type == ConversationType::Group
   }
}
