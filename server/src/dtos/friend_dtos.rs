use crate::entities::friendship::FriendshipStatus;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct SendFriendRequestDto {
   #[serde(default)]
   pub friend_username: Option<String>,
   #[serde(default)]
   pub friend_id: Option<Uuid>,
}

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct RespondFriendRequestDto {
   #[serde(default)]
   pub friendship_id: Option<Uuid>,
   #[serde(default)]
   pub accept: bool, // true = accept, false = reject
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FriendshipResponse {
   pub id: Uuid,
   #[serde(skip_serializing_if = "Option::is_none")]
   pub request_id: Option<Uuid>,
   pub user_id: Uuid,
   pub friend_id: Uuid,
   #[serde(skip_serializing_if = "Option::is_none")]
   pub username: Option<String>,
   #[serde(skip_serializing_if = "Option::is_none")]
   pub display_name: Option<String>,
   pub status: FriendshipStatus,
   pub requested_at: DateTime<Utc>,
   pub responded_at: Option<DateTime<Utc>>,
   pub created_at: DateTime<Utc>,
   pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FriendWithUserInfo {
   pub friendship_id: Uuid,
   pub friend_user_id: Uuid,
   #[serde(skip_serializing_if = "Option::is_none")]
   pub user_id: Option<Uuid>,
   pub username: String,
   pub display_name: String,
   pub status: FriendshipStatus,
   pub requested_at: DateTime<Utc>,
   pub responded_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PendingRequestWithUserInfo {
   pub id: Uuid,
   pub friendship_id: Uuid,
   pub user_id: Uuid,
   pub requester_user_id: Uuid,
   pub username: String,
   pub display_name: String,
   pub requested_at: DateTime<Utc>,
   pub status: FriendshipStatus,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SentRequestWithUserInfo {
   pub id: Uuid,
   pub friendship_id: Uuid,
   pub user_id: Uuid,
   pub friend_user_id: Uuid,
   pub username: String,
   pub display_name: String,
   pub requested_at: DateTime<Utc>,
   pub status: FriendshipStatus,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FriendsListResponse {
   pub friends: Vec<FriendWithUserInfo>,
   pub total: usize,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PendingRequestsResponse {
   pub received_requests: Vec<PendingRequestWithUserInfo>,
   pub sent_requests: Vec<SentRequestWithUserInfo>,
   pub total_received: usize,
   pub total_sent: usize,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ReceivedRequestsListResponse {
   pub requests: Vec<PendingRequestWithUserInfo>,
   pub total: usize,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SentRequestsListResponse {
   pub requests: Vec<SentRequestWithUserInfo>,
   pub total: usize,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FriendshipStatusResponse {
   pub status: String,
   #[serde(skip_serializing_if = "Option::is_none")]
   pub request_id: Option<Uuid>,
   #[serde(skip_serializing_if = "Option::is_none")]
   pub friendship_id: Option<Uuid>,
}

#[cfg(test)]
mod tests {
   use super::*;

   #[test]
   fn test_send_friend_request_dto_deserialization() {
      let json_data = r#"{"friend_id": "00000000-0000-0000-0000-000000000001"}"#;
      let dto: SendFriendRequestDto = serde_json::from_str(json_data).unwrap();
      assert_eq!(
         dto.friend_id,
         Some(Uuid::parse_str("00000000-0000-0000-0000-000000000001").unwrap())
      );
      assert_eq!(dto.friend_username, None);

      let json_data2 = r#"{"friend_username": "johndoe"}"#;
      let dto2: SendFriendRequestDto = serde_json::from_str(json_data2).unwrap();
      assert_eq!(dto2.friend_username, Some("johndoe".to_string()));
      assert_eq!(dto2.friend_id, None);
   }

   #[test]
   fn test_friendship_status_response_serialization() {
      let res = FriendshipStatusResponse {
         status: "pending_sent".to_string(),
         request_id: Some(Uuid::nil()),
         friendship_id: Some(Uuid::nil()),
      };
      let serialized = serde_json::to_string(&res).unwrap();
      assert!(serialized.contains("pending_sent"));
      assert!(serialized.contains("request_id"));
   }
}
