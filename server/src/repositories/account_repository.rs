use crate::entities::account::{self, Entity as Account};
use anyhow::Result;
use sea_orm::*;
use uuid::Uuid;

#[derive(Clone)]
pub struct AccountRepository {
   db: DatabaseConnection,
}

impl AccountRepository {
   pub fn new(db: DatabaseConnection) -> Self {
      Self { db }
   }

   /// Create a new account
   pub async fn create(&self, username: &str, password_hash: &str) -> Result<account::Model> {
      let now = chrono::Utc::now().into();

      let account = account::ActiveModel {
         id: Set(Uuid::now_v7()),
         username: Set(username.to_string()),
         password: Set(password_hash.to_string()),
         created_at: Set(now),
         updated_at: Set(now),
         deleted_at: Set(None),
      };

      let result = account.insert(&self.db).await?;
      Ok(result)
   }

   /// Find account by username
   pub async fn find_by_username(&self, username: &str) -> Result<Option<account::Model>> {
      let account = Account::find()
         .filter(account::Column::Username.eq(username))
         .filter(account::Column::DeletedAt.is_null())
         .one(&self.db)
         .await?;

      Ok(account)
   }

   /// Find account by ID
   pub async fn find_by_id(&self, id: &Uuid) -> Result<Option<account::Model>> {
      let account = Account::find_by_id(*id)
         .filter(account::Column::DeletedAt.is_null())
         .one(&self.db)
         .await?;

      Ok(account)
   }

   /// Check if username exists
   pub async fn username_exists(&self, username: &str) -> Result<bool> {
      let count = Account::find()
         .filter(account::Column::Username.eq(username))
         .filter(account::Column::DeletedAt.is_null())
         .count(&self.db)
         .await?;

      Ok(count > 0)
   }
}
