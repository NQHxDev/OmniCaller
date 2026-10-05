use crate::entities::account::{self, Entity as Account};
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

   /// Get database connection
   pub fn db(&self) -> &DatabaseConnection {
      &self.db
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

   /// Find user by user ID with account info
   pub async fn find_by_user_id_with_account(
      &self,
      user_id: &Uuid,
   ) -> Result<Option<(user::Model, account::Model)>> {
      if let Some(user) = User::find_by_id(*user_id)
         .filter(user::Column::DeletedAt.is_null())
         .one(&self.db)
         .await?
      {
         if let Some(account) = Account::find()
            .filter(account::Column::Id.eq(user.account_id))
            .filter(account::Column::DeletedAt.is_null())
            .one(&self.db)
            .await?
         {
            return Ok(Some((user, account)));
         }
      }

      Ok(None)
   }

   /// Find user by username (with account info)
   pub async fn find_by_username(
      &self,
      username: &str,
   ) -> Result<Option<(user::Model, account::Model)>> {
      // First find account by username
      let account = Account::find()
         .filter(account::Column::Username.eq(username.to_lowercase()))
         .filter(account::Column::DeletedAt.is_null())
         .one(&self.db)
         .await?;

      if let Some(account) = account {
         // Then find user by account_id
         let user = User::find()
            .filter(user::Column::AccountId.eq(account.id))
            .filter(user::Column::DeletedAt.is_null())
            .one(&self.db)
            .await?;

         if let Some(user) = user {
            return Ok(Some((user, account)));
         }
      }

      Ok(None)
   }

   /// Search users by display name or username with pagination (excluding current user)
   pub async fn search(
      &self,
      query: &str,
      page: u64,
      page_size: u64,
      exclude_user_id: Option<&Uuid>,
   ) -> Result<(Vec<(user::Model, account::Model)>, u64)> {
      let search_term = format!("%{}%", query);

      // Build query with join using LIKE for case-insensitive search
      let mut query_builder = User::find()
         .inner_join(Account)
         .filter(user::Column::DeletedAt.is_null())
         .filter(
            Condition::any()
               .add(user::Column::DisplayName.like(&search_term))
               .add(account::Column::Username.like(&search_term)),
         );

      // Exclude current user if provided
      if let Some(user_id) = exclude_user_id {
         query_builder = query_builder.filter(user::Column::Id.ne(*user_id));
      }

      // Get total count
      let total = query_builder.clone().count(&self.db).await?;

      // Get paginated results
      let users: Vec<user::Model> = query_builder
         .order_by_asc(user::Column::DisplayName)
         .offset((page - 1) * page_size)
         .limit(page_size)
         .all(&self.db)
         .await?;

      // Fetch associated accounts for each user
      let mut results = Vec::new();
      for user in users {
         if let Some(account) = Account::find()
            .filter(account::Column::Id.eq(user.account_id))
            .one(&self.db)
            .await?
         {
            results.push((user, account));
         }
      }

      Ok((results, total))
   }
}
