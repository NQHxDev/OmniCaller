use sea_orm::entity::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, Serialize, Deserialize)]
#[sea_orm(table_name = "message_attachment")]
pub struct Model {
   #[sea_orm(primary_key, auto_increment = false)]
   pub id: Uuid,

   pub message_id: Uuid,

   #[sea_orm(column_type = "Text")]
   pub file_url: String,

   #[sea_orm(column_type = "Text")]
   pub thumbnail_url: Option<String>,

   #[sea_orm(column_type = "String(StringLen::N(50))")]
   pub file_type: String,

   pub file_size_bytes: i64,

   pub width: Option<i32>,
   pub height: Option<i32>,
   pub duration_seconds: Option<i32>,

   pub created_at: DateTimeWithTimeZone,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
   #[sea_orm(
      belongs_to = "super::message::Entity",
      from = "Column::MessageId",
      to = "super::message::Column::Id",
      on_update = "Cascade",
      on_delete = "Cascade"
   )]
   Message,
}

impl Related<super::message::Entity> for Entity {
   fn to() -> RelationDef {
      Relation::Message.def()
   }
}

impl ActiveModelBehavior for ActiveModel {}

impl Model {
   pub fn is_image(&self) -> bool {
      self.file_type.starts_with("image/")
   }

   pub fn is_video(&self) -> bool {
      self.file_type.starts_with("video/")
   }

   pub fn is_audio(&self) -> bool {
      self.file_type.starts_with("audio/")
   }

   pub fn has_dimensions(&self) -> bool {
      self.width.is_some() && self.height.is_some()
   }

   pub fn has_duration(&self) -> bool {
      self.duration_seconds.is_some()
   }

   pub fn file_size_mb(&self) -> f64 {
      self.file_size_bytes as f64 / (1024.0 * 1024.0)
   }
}
