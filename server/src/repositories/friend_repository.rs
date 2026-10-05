use crate::entities::{account, friendship, user};
use chrono::Utc;
use sea_orm::*;
use uuid::Uuid;

#[derive(Clone)]
pub struct FriendRepository {
   db: DatabaseConnection,
}

impl FriendRepository {
   pub fn new(db: DatabaseConnection) -> Self {
      Self { db }
   }

   // Check if friendship exists between two users (in any direction, active/non-deleted)
   pub async fn find_friendship(
      &self,
      user_id: Uuid,
      friend_id: Uuid,
   ) -> Result<Option<friendship::Model>, DbErr> {
      friendship::Entity::find()
         .filter(
            Condition::any()
               .add(
                  Condition::all()
                     .add(friendship::Column::UserId.eq(user_id))
                     .add(friendship::Column::FriendId.eq(friend_id)),
               )
               .add(
                  Condition::all()
                     .add(friendship::Column::UserId.eq(friend_id))
                     .add(friendship::Column::FriendId.eq(user_id)),
               ),
         )
         .filter(friendship::Column::DeletedAt.is_null())
         .one(&self.db)
         .await
   }

   // Check if any friendship row exists between two users (including soft deleted or rejected)
   pub async fn find_any_friendship(
      &self,
      user_id: Uuid,
      friend_id: Uuid,
   ) -> Result<Option<friendship::Model>, DbErr> {
      friendship::Entity::find()
         .filter(
            Condition::any()
               .add(
                  Condition::all()
                     .add(friendship::Column::UserId.eq(user_id))
                     .add(friendship::Column::FriendId.eq(friend_id)),
               )
               .add(
                  Condition::all()
                     .add(friendship::Column::UserId.eq(friend_id))
                     .add(friendship::Column::FriendId.eq(user_id)),
               ),
         )
         .one(&self.db)
         .await
   }

   // Create or reactivate a friend request
   pub async fn upsert_friend_request(
      &self,
      user_id: Uuid,
      friend_id: Uuid,
   ) -> Result<friendship::Model, DbErr> {
      let now = Utc::now();
      if let Some(existing) = self.find_any_friendship(user_id, friend_id).await? {
         let mut active_model: friendship::ActiveModel = existing.into();
         active_model.user_id = Set(user_id);
         active_model.friend_id = Set(friend_id);
         active_model.status = Set(friendship::FriendshipStatus::Pending);
         active_model.requested_at = Set(now.into());
         active_model.responded_at = Set(None);
         active_model.deleted_at = Set(None);
         active_model.updated_at = Set(now.into());
         active_model.update(&self.db).await
      } else {
         let friendship = friendship::ActiveModel {
            id: Set(Uuid::now_v7()),
            user_id: Set(user_id),
            friend_id: Set(friend_id),
            status: Set(friendship::FriendshipStatus::Pending),
            requested_at: Set(now.into()),
            responded_at: Set(None),
            created_at: Set(now.into()),
            updated_at: Set(now.into()),
            deleted_at: Set(None),
         };

         friendship.insert(&self.db).await
      }
   }

   // Find friendship by ID
   pub async fn find_by_id(&self, id: Uuid) -> Result<Option<friendship::Model>, DbErr> {
      friendship::Entity::find_by_id(id)
         .filter(friendship::Column::DeletedAt.is_null())
         .one(&self.db)
         .await
   }

   // Accept friend request
   pub async fn accept_friend_request(
      &self,
      friendship_id: Uuid,
   ) -> Result<friendship::Model, DbErr> {
      let now = Utc::now();
      let mut friendship: friendship::ActiveModel = friendship::Entity::find_by_id(friendship_id)
         .one(&self.db)
         .await?
         .ok_or(DbErr::RecordNotFound("Friendship not found".to_string()))?
         .into();

      friendship.status = Set(friendship::FriendshipStatus::Accepted);
      friendship.responded_at = Set(Some(now.into()));
      friendship.updated_at = Set(now.into());

      friendship.update(&self.db).await
   }

   // Reject friend request
   pub async fn reject_friend_request(
      &self,
      friendship_id: Uuid,
   ) -> Result<friendship::Model, DbErr> {
      let now = Utc::now();
      let mut friendship: friendship::ActiveModel = friendship::Entity::find_by_id(friendship_id)
         .one(&self.db)
         .await?
         .ok_or(DbErr::RecordNotFound("Friendship not found".to_string()))?
         .into();

      friendship.status = Set(friendship::FriendshipStatus::Rejected);
      friendship.responded_at = Set(Some(now.into()));
      friendship.updated_at = Set(now.into());

      friendship.update(&self.db).await
   }

   // Get all accepted friends for a user
   pub async fn get_friends(
      &self,
      user_id: Uuid,
   ) -> Result<Vec<(friendship::Model, user::Model, account::Model)>, DbErr> {
      let friendships = friendship::Entity::find()
         .filter(
            Condition::any()
               .add(friendship::Column::UserId.eq(user_id))
               .add(friendship::Column::FriendId.eq(user_id)),
         )
         .filter(friendship::Column::Status.eq(friendship::FriendshipStatus::Accepted))
         .filter(friendship::Column::DeletedAt.is_null())
         .all(&self.db)
         .await?;

      let mut results = Vec::new();
      for friendship_model in friendships {
         // Determine which user is the friend
         let friend_id = if friendship_model.user_id == user_id {
            friendship_model.friend_id
         } else {
            friendship_model.user_id
         };

         // Fetch friend user info
         if let Some(friend_user) = user::Entity::find_by_id(friend_id)
            .filter(user::Column::DeletedAt.is_null())
            .one(&self.db)
            .await?
         {
            // Fetch friend account info
            if let Some(friend_account) = account::Entity::find_by_id(friend_user.account_id)
               .filter(account::Column::DeletedAt.is_null())
               .one(&self.db)
               .await?
            {
               results.push((friendship_model, friend_user, friend_account));
            }
         }
      }

      Ok(results)
   }

   // Get pending friend requests received by user
   pub async fn get_pending_received_requests(
      &self,
      user_id: Uuid,
   ) -> Result<Vec<(friendship::Model, user::Model, account::Model)>, DbErr> {
      let friendships = friendship::Entity::find()
         .filter(friendship::Column::FriendId.eq(user_id))
         .filter(friendship::Column::Status.eq(friendship::FriendshipStatus::Pending))
         .filter(friendship::Column::DeletedAt.is_null())
         .all(&self.db)
         .await?;

      let mut results = Vec::new();
      for friendship_model in friendships {
         // Fetch requester user info
         if let Some(requester_user) = user::Entity::find_by_id(friendship_model.user_id)
            .filter(user::Column::DeletedAt.is_null())
            .one(&self.db)
            .await?
         {
            // Fetch requester account info
            if let Some(requester_account) = account::Entity::find_by_id(requester_user.account_id)
               .filter(account::Column::DeletedAt.is_null())
               .one(&self.db)
               .await?
            {
               results.push((friendship_model, requester_user, requester_account));
            }
         }
      }

      Ok(results)
   }

   // Get pending friend requests sent by user
   pub async fn get_pending_sent_requests(
      &self,
      user_id: Uuid,
   ) -> Result<Vec<(friendship::Model, user::Model, account::Model)>, DbErr> {
      let friendships = friendship::Entity::find()
         .filter(friendship::Column::UserId.eq(user_id))
         .filter(friendship::Column::Status.eq(friendship::FriendshipStatus::Pending))
         .filter(friendship::Column::DeletedAt.is_null())
         .all(&self.db)
         .await?;

      let mut results = Vec::new();
      for friendship_model in friendships {
         // Fetch friend user info
         if let Some(friend_user) = user::Entity::find_by_id(friendship_model.friend_id)
            .filter(user::Column::DeletedAt.is_null())
            .one(&self.db)
            .await?
         {
            // Fetch friend account info
            if let Some(friend_account) = account::Entity::find_by_id(friend_user.account_id)
               .filter(account::Column::DeletedAt.is_null())
               .one(&self.db)
               .await?
            {
               results.push((friendship_model, friend_user, friend_account));
            }
         }
      }

      Ok(results)
   }

   // Remove/unfriend (soft delete)
   pub async fn remove_friend(&self, friendship_id: Uuid) -> Result<(), DbErr> {
      let now = Utc::now();
      let mut friendship: friendship::ActiveModel = friendship::Entity::find_by_id(friendship_id)
         .one(&self.db)
         .await?
         .ok_or(DbErr::RecordNotFound("Friendship not found".to_string()))?
         .into();

      friendship.deleted_at = Set(Some(now.into()));
      friendship.updated_at = Set(now.into());

      friendship.update(&self.db).await?;
      Ok(())
   }

   // Block user
   pub async fn block_user(&self, friendship_id: Uuid) -> Result<friendship::Model, DbErr> {
      let now = Utc::now();
      let mut friendship: friendship::ActiveModel = friendship::Entity::find_by_id(friendship_id)
         .one(&self.db)
         .await?
         .ok_or(DbErr::RecordNotFound("Friendship not found".to_string()))?
         .into();

      friendship.status = Set(friendship::FriendshipStatus::Blocked);
      friendship.updated_at = Set(now.into());

      friendship.update(&self.db).await
   }
}
