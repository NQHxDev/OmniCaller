use crate::dtos::friend_dtos::*;
use crate::repositories::friend_repository::FriendRepository;
use crate::repositories::user_repository::UserRepository;
use anyhow::{anyhow, Context, Result};
use uuid::Uuid;

#[derive(Clone)]
pub struct FriendService {
   friend_repo: FriendRepository,
   user_repo: UserRepository,
}

impl FriendService {
   pub fn new(friend_repo: FriendRepository, user_repo: UserRepository) -> Self {
      Self { friend_repo, user_repo }
   }

   // Send friend request by username or user_id
   pub async fn send_friend_request(
      &self,
      user_id: Uuid,
      friend_username: Option<String>,
      friend_id: Option<Uuid>,
   ) -> Result<FriendshipResponse> {
      let (friend_user, friend_account) = if let Some(fid) = friend_id {
         self
            .user_repo
            .find_by_user_id_with_account(&fid)
            .await
            .context("Failed to query user by id")?
            .ok_or_else(|| anyhow!("User not found"))?
      } else if let Some(uname) = friend_username {
         self
            .user_repo
            .find_by_username(&uname)
            .await
            .context("Failed to query user by username")?
            .ok_or_else(|| anyhow!("User not found"))?
      } else {
         return Err(anyhow!("Must provide either friend_id or friend_username"));
      };

      // Check if user is trying to add themselves
      if user_id == friend_user.id {
         return Err(anyhow!("Cannot send friend request to yourself"));
      }

      // Check if friendship already exists
      if let Some(existing) = self
         .friend_repo
         .find_friendship(user_id, friend_user.id)
         .await
         .context("Failed to check existing friendship")?
      {
         match existing.status {
            crate::entities::friendship::FriendshipStatus::Pending => {
               return Err(anyhow!("Friend request already pending"));
            }
            crate::entities::friendship::FriendshipStatus::Accepted => {
               return Err(anyhow!("Already friends"));
            }
            crate::entities::friendship::FriendshipStatus::Blocked => {
               return Err(anyhow!("Cannot send friend request"));
            }
            crate::entities::friendship::FriendshipStatus::Rejected => {
               // Allow resending after rejection
            }
         }
      }

      // Create or reactivate friend request
      let friendship = self
         .friend_repo
         .upsert_friend_request(user_id, friend_user.id)
         .await
         .context("Failed to create friend request")?;

      Ok(FriendshipResponse {
         id: friendship.id,
         request_id: Some(friendship.id),
         user_id: friendship.user_id,
         friend_id: friendship.friend_id,
         username: Some(friend_account.username),
         display_name: Some(friend_user.display_name),
         status: friendship.status,
         requested_at: friendship.requested_at.naive_utc().and_utc(),
         responded_at: friendship.responded_at.map(|dt| dt.naive_utc().and_utc()),
         created_at: friendship.created_at.naive_utc().and_utc(),
         updated_at: friendship.updated_at.naive_utc().and_utc(),
      })
   }

   // Respond to friend request (accept or reject)
   pub async fn respond_to_friend_request(
      &self,
      user_id: Uuid,
      friendship_or_user_id: Uuid,
      accept: bool,
   ) -> Result<FriendshipResponse> {
      // Find friendship either by its ID or between the two users
      let friendship = match self
         .friend_repo
         .find_by_id(friendship_or_user_id)
         .await
         .context("Failed to query friendship")?
      {
         Some(f) => f,
         None => self
            .friend_repo
            .find_friendship(user_id, friendship_or_user_id)
            .await
            .context("Failed to query friendship by user pair")?
            .ok_or_else(|| anyhow!("Friend request not found"))?,
      };

      // Verify the user is the recipient of the request
      if friendship.friend_id != user_id {
         return Err(anyhow!("Not authorized to respond to this request"));
      }

      // Verify the request is still pending
      if !friendship.is_pending() {
         return Err(anyhow!("Friend request is no longer pending"));
      }

      // Accept or reject
      let updated_friendship = if accept {
         self
            .friend_repo
            .accept_friend_request(friendship.id)
            .await
            .context("Failed to accept friend request")?
      } else {
         self
            .friend_repo
            .reject_friend_request(friendship.id)
            .await
            .context("Failed to reject friend request")?
      };

      Ok(FriendshipResponse {
         id: updated_friendship.id,
         request_id: Some(updated_friendship.id),
         user_id: updated_friendship.user_id,
         friend_id: updated_friendship.friend_id,
         username: None,
         display_name: None,
         status: updated_friendship.status,
         requested_at: updated_friendship.requested_at.naive_utc().and_utc(),
         responded_at: updated_friendship.responded_at.map(|dt| dt.naive_utc().and_utc()),
         created_at: updated_friendship.created_at.naive_utc().and_utc(),
         updated_at: updated_friendship.updated_at.naive_utc().and_utc(),
      })
   }

   // Cancel friend request
   pub async fn cancel_friend_request(
      &self,
      user_id: Uuid,
      friendship_or_user_id: Uuid,
   ) -> Result<()> {
      let friendship = match self
         .friend_repo
         .find_by_id(friendship_or_user_id)
         .await
         .context("Failed to query friendship")?
      {
         Some(f) => f,
         None => self
            .friend_repo
            .find_friendship(user_id, friendship_or_user_id)
            .await
            .context("Failed to query friendship by user pair")?
            .ok_or_else(|| anyhow!("Friend request not found"))?,
      };

      if friendship.user_id != user_id {
         return Err(anyhow!("Not authorized to cancel this friend request"));
      }

      if !friendship.is_pending() {
         return Err(anyhow!("Friend request is no longer pending"));
      }

      self
         .friend_repo
         .remove_friend(friendship.id)
         .await
         .context("Failed to cancel friend request")?;

      Ok(())
   }

   // Get list of friends
   pub async fn get_friends(&self, user_id: Uuid) -> Result<FriendsListResponse> {
      let friends_data = self
         .friend_repo
         .get_friends(user_id)
         .await
         .context("Failed to get friends list")?;

      let friends: Vec<FriendWithUserInfo> = friends_data
         .into_iter()
         .map(|(friendship, _user, account)| FriendWithUserInfo {
            friendship_id: friendship.id,
            friend_user_id: _user.id,
            user_id: Some(_user.id),
            username: account.username,
            display_name: _user.display_name,
            status: friendship.status,
            requested_at: friendship.requested_at.naive_utc().and_utc(),
            responded_at: friendship.responded_at.map(|dt| dt.naive_utc().and_utc()),
         })
         .collect();

      let total = friends.len();

      Ok(FriendsListResponse { friends, total })
   }

   // Get received pending friend requests
   pub async fn get_received_requests(
      &self,
      user_id: Uuid,
   ) -> Result<ReceivedRequestsListResponse> {
      let received_data = self
         .friend_repo
         .get_pending_received_requests(user_id)
         .await
         .context("Failed to get received requests")?;

      let requests: Vec<PendingRequestWithUserInfo> = received_data
         .into_iter()
         .map(|(friendship, _user, account)| PendingRequestWithUserInfo {
            id: friendship.id,
            friendship_id: friendship.id,
            user_id: _user.id,
            requester_user_id: _user.id,
            username: account.username,
            display_name: _user.display_name,
            requested_at: friendship.requested_at.naive_utc().and_utc(),
            status: friendship.status,
         })
         .collect();

      let total = requests.len();
      Ok(ReceivedRequestsListResponse { requests, total })
   }

   // Get sent pending friend requests
   pub async fn get_sent_requests(&self, user_id: Uuid) -> Result<SentRequestsListResponse> {
      let sent_data = self
         .friend_repo
         .get_pending_sent_requests(user_id)
         .await
         .context("Failed to get sent requests")?;

      let requests: Vec<SentRequestWithUserInfo> = sent_data
         .into_iter()
         .map(|(friendship, _user, account)| SentRequestWithUserInfo {
            id: friendship.id,
            friendship_id: friendship.id,
            user_id: _user.id,
            friend_user_id: _user.id,
            username: account.username,
            display_name: _user.display_name,
            requested_at: friendship.requested_at.naive_utc().and_utc(),
            status: friendship.status,
         })
         .collect();

      let total = requests.len();
      Ok(SentRequestsListResponse { requests, total })
   }

   // Get pending friend requests (both received and sent)
   pub async fn get_pending_requests(&self, user_id: Uuid) -> Result<PendingRequestsResponse> {
      let received = self.get_received_requests(user_id).await?;
      let sent = self.get_sent_requests(user_id).await?;

      Ok(PendingRequestsResponse {
         received_requests: received.requests,
         sent_requests: sent.requests,
         total_received: received.total,
         total_sent: sent.total,
      })
   }

   // Get friendship status with a user
   pub async fn get_friendship_status(
      &self,
      user_id: Uuid,
      target_user_id: Uuid,
   ) -> Result<FriendshipStatusResponse> {
      let friendship_opt = self
         .friend_repo
         .find_friendship(user_id, target_user_id)
         .await
         .context("Failed to find friendship")?;

      if let Some(friendship) = friendship_opt {
         match friendship.status {
            crate::entities::friendship::FriendshipStatus::Accepted => {
               Ok(FriendshipStatusResponse {
                  status: "accepted".to_string(),
                  request_id: Some(friendship.id),
                  friendship_id: Some(friendship.id),
               })
            }
            crate::entities::friendship::FriendshipStatus::Pending => {
               if friendship.user_id == user_id {
                  Ok(FriendshipStatusResponse {
                     status: "pending_sent".to_string(),
                     request_id: Some(friendship.id),
                     friendship_id: Some(friendship.id),
                  })
               } else {
                  Ok(FriendshipStatusResponse {
                     status: "pending_received".to_string(),
                     request_id: Some(friendship.id),
                     friendship_id: Some(friendship.id),
                  })
               }
            }
            crate::entities::friendship::FriendshipStatus::Blocked => {
               Ok(FriendshipStatusResponse {
                  status: "blocked".to_string(),
                  request_id: Some(friendship.id),
                  friendship_id: Some(friendship.id),
               })
            }
            crate::entities::friendship::FriendshipStatus::Rejected => {
               Ok(FriendshipStatusResponse {
                  status: "rejected".to_string(),
                  request_id: None,
                  friendship_id: None,
               })
            }
         }
      } else {
         Ok(FriendshipStatusResponse {
            status: "none".to_string(),
            request_id: None,
            friendship_id: None,
         })
      }
   }

   // Remove friend (unfriend)
   pub async fn remove_friend(&self, user_id: Uuid, friendship_or_user_id: Uuid) -> Result<()> {
      let friendship = match self
         .friend_repo
         .find_by_id(friendship_or_user_id)
         .await
         .context("Failed to query friendship")?
      {
         Some(f) => f,
         None => self
            .friend_repo
            .find_friendship(user_id, friendship_or_user_id)
            .await
            .context("Failed to query friendship by user pair")?
            .ok_or_else(|| anyhow!("Friendship not found"))?,
      };

      // Verify the user is part of this friendship
      if friendship.user_id != user_id && friendship.friend_id != user_id {
         return Err(anyhow!("Not authorized to remove this friendship"));
      }

      // Remove friendship
      self
         .friend_repo
         .remove_friend(friendship.id)
         .await
         .context("Failed to remove friend")?;

      Ok(())
   }

   // Block user
   pub async fn block_user(
      &self,
      user_id: Uuid,
      friendship_or_user_id: Uuid,
   ) -> Result<FriendshipResponse> {
      let friendship = match self
         .friend_repo
         .find_by_id(friendship_or_user_id)
         .await
         .context("Failed to query friendship")?
      {
         Some(f) => f,
         None => self
            .friend_repo
            .find_friendship(user_id, friendship_or_user_id)
            .await
            .context("Failed to query friendship by user pair")?
            .ok_or_else(|| anyhow!("Friendship not found"))?,
      };

      // Verify the user is part of this friendship
      if friendship.user_id != user_id && friendship.friend_id != user_id {
         return Err(anyhow!("Not authorized to block this user"));
      }

      // Block user
      let updated_friendship = self
         .friend_repo
         .block_user(friendship.id)
         .await
         .context("Failed to block user")?;

      Ok(FriendshipResponse {
         id: updated_friendship.id,
         request_id: Some(updated_friendship.id),
         user_id: updated_friendship.user_id,
         friend_id: updated_friendship.friend_id,
         username: None,
         display_name: None,
         status: updated_friendship.status,
         requested_at: updated_friendship.requested_at.naive_utc().and_utc(),
         responded_at: updated_friendship.responded_at.map(|dt| dt.naive_utc().and_utc()),
         created_at: updated_friendship.created_at.naive_utc().and_utc(),
         updated_at: updated_friendship.updated_at.naive_utc().and_utc(),
      })
   }
}
