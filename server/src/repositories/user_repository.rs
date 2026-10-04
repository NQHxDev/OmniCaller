use crate::entities::user::{self, Entity as User};
use anyhow::Result;
use sea_orm::*;
use uuid::Uuid;

#[derive(Clone)]
pub struct UserRepository {
   db: DatabaseConnection,
}

impl UserRepository {
   pub fn new(db: DatabaseConnection) -> Self {
      Self { db }
   }

   /// Create a new user
   pub async fn create(&self, account_id: &Uuid, display_name: &str) -> Result<user::Model> {
      let now = chrono::Utc::now().into();

      let user = user::ActiveModel {
         id: Set(Uuid::now_v7()),
         account_id: Set(*account_id),
         display_name: Set(display_name.to_string()),
         created_at: Set(now),
         updated_at: Set(now),
         deleted_at: Set(None),
      };

      let result = user.insert(&self.db).await?;
      Ok(result)
   }

   /// Find user by account ID
   pub async fn find_by_account_id(&self, account_id: &Uuid) -> Result<Option<user::Model>> {
      let user = User::find()
         .filter(user::Column::AccountId.eq(*account_id))
         .filter(user::Column::DeletedAt.is_null())
         .one(&self.db)
         .await?;

      Ok(user)
   }

   /// Find user by ID
   pub async fn find_by_id(&self, id: &Uuid) -> Result<Option<user::Model>> {
      let user = User::find_by_id(*id)
         .filter(user::Column::DeletedAt.is_null())
         .one(&self.db)
         .await?;

      Ok(user)
   }
}
