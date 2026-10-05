use crate::dtos::friend_dtos::*;
use crate::middlewares::auth_middleware::AuthUser;
use crate::services::friend_service::FriendService;
use axum::{
   extract::{Path, State},
   http::StatusCode,
   response::{IntoResponse, Response},
   Json,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Clone)]
pub struct FriendHandler {
   service: FriendService,
}

#[derive(Debug, Serialize, Deserialize)]
struct ApiResponse<T> {
   success: bool,
   data: Option<T>,
   error: Option<String>,
}

impl FriendHandler {
   pub fn new(service: FriendService) -> Self {
      Self { service }
   }

   // POST /api/friends/requests or POST /api/friends/request - Send friend request
   pub async fn send_friend_request(
      auth_user: AuthUser,
      State(handler): State<Self>,
      Json(payload): Json<SendFriendRequestDto>,
   ) -> Response {
      let user_id = match Uuid::parse_str(&auth_user.user_id) {
         Ok(id) => id,
         Err(_) => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendshipResponse> {
                  success: false,
                  data: None,
                  error: Some("Invalid user ID".to_string()),
               }),
            )
               .into_response()
         }
      };

      match handler
         .service
         .send_friend_request(user_id, payload.friend_username, payload.friend_id)
         .await
      {
         Ok(friendship) => (
            StatusCode::CREATED,
            Json(ApiResponse {
               success: true,
               data: Some(friendship),
               error: None,
            }),
         )
            .into_response(),
         Err(e) => {
            tracing::error!("Failed to send friend request: {:?}", e);
            (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendshipResponse> {
                  success: false,
                  data: None,
                  error: Some(e.to_string()),
               }),
            )
               .into_response()
         }
      }
   }

   // POST /api/friends/respond - Respond to friend request (accept/reject)
   pub async fn respond_to_friend_request(
      auth_user: AuthUser,
      State(handler): State<Self>,
      Json(payload): Json<RespondFriendRequestDto>,
   ) -> Response {
      let user_id = match Uuid::parse_str(&auth_user.user_id) {
         Ok(id) => id,
         Err(_) => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendshipResponse> {
                  success: false,
                  data: None,
                  error: Some("Invalid user ID".to_string()),
               }),
            )
               .into_response()
         }
      };

      let friendship_id = match payload.friendship_id {
         Some(id) => id,
         None => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendshipResponse> {
                  success: false,
                  data: None,
                  error: Some("friendship_id is required".to_string()),
               }),
            )
               .into_response()
         }
      };

      match handler
         .service
         .respond_to_friend_request(user_id, friendship_id, payload.accept)
         .await
      {
         Ok(friendship) => (
            StatusCode::OK,
            Json(ApiResponse {
               success: true,
               data: Some(friendship),
               error: None,
            }),
         )
            .into_response(),
         Err(e) => {
            tracing::error!("Failed to respond to friend request: {:?}", e);
            (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendshipResponse> {
                  success: false,
                  data: None,
                  error: Some(e.to_string()),
               }),
            )
               .into_response()
         }
      }
   }

   // POST /api/friends/requests/:id/accept - Accept friend request
   pub async fn accept_friend_request_by_path(
      auth_user: AuthUser,
      State(handler): State<Self>,
      Path(id): Path<Uuid>,
   ) -> Response {
      let user_id = match Uuid::parse_str(&auth_user.user_id) {
         Ok(uid) => uid,
         Err(_) => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendshipResponse> {
                  success: false,
                  data: None,
                  error: Some("Invalid user ID".to_string()),
               }),
            )
               .into_response()
         }
      };

      match handler.service.respond_to_friend_request(user_id, id, true).await {
         Ok(friendship) => (
            StatusCode::OK,
            Json(ApiResponse {
               success: true,
               data: Some(friendship),
               error: None,
            }),
         )
            .into_response(),
         Err(e) => {
            tracing::error!("Failed to accept friend request: {:?}", e);
            (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendshipResponse> {
                  success: false,
                  data: None,
                  error: Some(e.to_string()),
               }),
            )
               .into_response()
         }
      }
   }

   // POST /api/friends/requests/:id/reject - Reject friend request
   pub async fn reject_friend_request_by_path(
      auth_user: AuthUser,
      State(handler): State<Self>,
      Path(id): Path<Uuid>,
   ) -> Response {
      let user_id = match Uuid::parse_str(&auth_user.user_id) {
         Ok(uid) => uid,
         Err(_) => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendshipResponse> {
                  success: false,
                  data: None,
                  error: Some("Invalid user ID".to_string()),
               }),
            )
               .into_response()
         }
      };

      match handler.service.respond_to_friend_request(user_id, id, false).await {
         Ok(friendship) => (
            StatusCode::OK,
            Json(ApiResponse {
               success: true,
               data: Some(friendship),
               error: None,
            }),
         )
            .into_response(),
         Err(e) => {
            tracing::error!("Failed to reject friend request: {:?}", e);
            (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendshipResponse> {
                  success: false,
                  data: None,
                  error: Some(e.to_string()),
               }),
            )
               .into_response()
         }
      }
   }

   // DELETE /api/friends/requests/:id/cancel or DELETE /api/friends/requests/:id - Cancel sent friend request
   pub async fn cancel_friend_request_by_path(
      auth_user: AuthUser,
      State(handler): State<Self>,
      Path(id): Path<Uuid>,
   ) -> Response {
      let user_id = match Uuid::parse_str(&auth_user.user_id) {
         Ok(uid) => uid,
         Err(_) => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<()> {
                  success: false,
                  data: None,
                  error: Some("Invalid user ID".to_string()),
               }),
            )
               .into_response()
         }
      };

      match handler.service.cancel_friend_request(user_id, id).await {
         Ok(_) => (
            StatusCode::OK,
            Json(ApiResponse::<()> { success: true, data: None, error: None }),
         )
            .into_response(),
         Err(e) => {
            tracing::error!("Failed to cancel friend request: {:?}", e);
            (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<()> {
                  success: false,
                  data: None,
                  error: Some(e.to_string()),
               }),
            )
               .into_response()
         }
      }
   }

   // GET /api/friends - Get list of friends
   pub async fn get_friends(auth_user: AuthUser, State(handler): State<Self>) -> Response {
      let user_id = match Uuid::parse_str(&auth_user.user_id) {
         Ok(id) => id,
         Err(_) => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendsListResponse> {
                  success: false,
                  data: None,
                  error: Some("Invalid user ID".to_string()),
               }),
            )
               .into_response()
         }
      };

      match handler.service.get_friends(user_id).await {
         Ok(friends_list) => (
            StatusCode::OK,
            Json(ApiResponse {
               success: true,
               data: Some(friends_list),
               error: None,
            }),
         )
            .into_response(),
         Err(e) => {
            tracing::error!("Failed to get friends list: {:?}", e);
            (
               StatusCode::INTERNAL_SERVER_ERROR,
               Json(ApiResponse::<FriendsListResponse> {
                  success: false,
                  data: None,
                  error: Some(e.to_string()),
               }),
            )
               .into_response()
         }
      }
   }

   // GET /api/friends/requests/received - Get received friend requests
   pub async fn get_received_requests(
      auth_user: AuthUser,
      State(handler): State<Self>,
   ) -> Response {
      let user_id = match Uuid::parse_str(&auth_user.user_id) {
         Ok(id) => id,
         Err(_) => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<ReceivedRequestsListResponse> {
                  success: false,
                  data: None,
                  error: Some("Invalid user ID".to_string()),
               }),
            )
               .into_response()
         }
      };

      match handler.service.get_received_requests(user_id).await {
         Ok(res) => (
            StatusCode::OK,
            Json(ApiResponse {
               success: true,
               data: Some(res),
               error: None,
            }),
         )
            .into_response(),
         Err(e) => {
            tracing::error!("Failed to get received requests: {:?}", e);
            (
               StatusCode::INTERNAL_SERVER_ERROR,
               Json(ApiResponse::<ReceivedRequestsListResponse> {
                  success: false,
                  data: None,
                  error: Some(e.to_string()),
               }),
            )
               .into_response()
         }
      }
   }

   // GET /api/friends/requests/sent - Get sent friend requests
   pub async fn get_sent_requests(auth_user: AuthUser, State(handler): State<Self>) -> Response {
      let user_id = match Uuid::parse_str(&auth_user.user_id) {
         Ok(id) => id,
         Err(_) => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<SentRequestsListResponse> {
                  success: false,
                  data: None,
                  error: Some("Invalid user ID".to_string()),
               }),
            )
               .into_response()
         }
      };

      match handler.service.get_sent_requests(user_id).await {
         Ok(res) => (
            StatusCode::OK,
            Json(ApiResponse {
               success: true,
               data: Some(res),
               error: None,
            }),
         )
            .into_response(),
         Err(e) => {
            tracing::error!("Failed to get sent requests: {:?}", e);
            (
               StatusCode::INTERNAL_SERVER_ERROR,
               Json(ApiResponse::<SentRequestsListResponse> {
                  success: false,
                  data: None,
                  error: Some(e.to_string()),
               }),
            )
               .into_response()
         }
      }
   }

   // GET /api/friends/pending or GET /api/friends/requests - Get pending friend requests
   pub async fn get_pending_requests(auth_user: AuthUser, State(handler): State<Self>) -> Response {
      let user_id = match Uuid::parse_str(&auth_user.user_id) {
         Ok(id) => id,
         Err(_) => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<PendingRequestsResponse> {
                  success: false,
                  data: None,
                  error: Some("Invalid user ID".to_string()),
               }),
            )
               .into_response()
         }
      };

      match handler.service.get_pending_requests(user_id).await {
         Ok(pending_requests) => (
            StatusCode::OK,
            Json(ApiResponse {
               success: true,
               data: Some(pending_requests),
               error: None,
            }),
         )
            .into_response(),
         Err(e) => {
            tracing::error!("Failed to get pending requests: {:?}", e);
            (
               StatusCode::INTERNAL_SERVER_ERROR,
               Json(ApiResponse::<PendingRequestsResponse> {
                  success: false,
                  data: None,
                  error: Some(e.to_string()),
               }),
            )
               .into_response()
         }
      }
   }

   // GET /api/friends/status/:user_id - Get friendship status
   pub async fn get_friendship_status(
      auth_user: AuthUser,
      State(handler): State<Self>,
      Path(target_user_id): Path<Uuid>,
   ) -> Response {
      let user_id = match Uuid::parse_str(&auth_user.user_id) {
         Ok(id) => id,
         Err(_) => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendshipStatusResponse> {
                  success: false,
                  data: None,
                  error: Some("Invalid user ID".to_string()),
               }),
            )
               .into_response()
         }
      };

      match handler.service.get_friendship_status(user_id, target_user_id).await {
         Ok(status_response) => (
            StatusCode::OK,
            Json(ApiResponse {
               success: true,
               data: Some(status_response),
               error: None,
            }),
         )
            .into_response(),
         Err(e) => {
            tracing::error!("Failed to get friendship status: {:?}", e);
            (
               StatusCode::INTERNAL_SERVER_ERROR,
               Json(ApiResponse::<FriendshipStatusResponse> {
                  success: false,
                  data: None,
                  error: Some(e.to_string()),
               }),
            )
               .into_response()
         }
      }
   }

   // DELETE /api/friends/:id - Remove friend (unfriend)
   pub async fn remove_friend(
      auth_user: AuthUser,
      State(handler): State<Self>,
      Path(friendship_or_user_id): Path<Uuid>,
   ) -> Response {
      let user_id = match Uuid::parse_str(&auth_user.user_id) {
         Ok(id) => id,
         Err(_) => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<()> {
                  success: false,
                  data: None,
                  error: Some("Invalid user ID".to_string()),
               }),
            )
               .into_response()
         }
      };

      match handler.service.remove_friend(user_id, friendship_or_user_id).await {
         Ok(_) => (
            StatusCode::OK,
            Json(ApiResponse::<()> { success: true, data: None, error: None }),
         )
            .into_response(),
         Err(e) => {
            tracing::error!("Failed to remove friend: {:?}", e);
            (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<()> {
                  success: false,
                  data: None,
                  error: Some(e.to_string()),
               }),
            )
               .into_response()
         }
      }
   }

   // POST /api/friends/:id/block - Block user
   pub async fn block_user(
      auth_user: AuthUser,
      State(handler): State<Self>,
      Path(friendship_or_user_id): Path<Uuid>,
   ) -> Response {
      let user_id = match Uuid::parse_str(&auth_user.user_id) {
         Ok(id) => id,
         Err(_) => {
            return (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendshipResponse> {
                  success: false,
                  data: None,
                  error: Some("Invalid user ID".to_string()),
               }),
            )
               .into_response()
         }
      };

      match handler.service.block_user(user_id, friendship_or_user_id).await {
         Ok(friendship) => (
            StatusCode::OK,
            Json(ApiResponse {
               success: true,
               data: Some(friendship),
               error: None,
            }),
         )
            .into_response(),
         Err(e) => {
            tracing::error!("Failed to block user: {:?}", e);
            (
               StatusCode::BAD_REQUEST,
               Json(ApiResponse::<FriendshipResponse> {
                  success: false,
                  data: None,
                  error: Some(e.to_string()),
               }),
            )
               .into_response()
         }
      }
   }
}
