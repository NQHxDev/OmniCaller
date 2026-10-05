use crate::dtos::user::{SearchUsersRequest, SearchUsersResponse, UserProfile, UserResponse};
use crate::middlewares::auth_middleware::AuthUser;
use crate::services::user_service::UserService;
use axum::{
   extract::{Path, Query, State},
   http::StatusCode,
   Json,
};
use validator::Validate;

#[derive(Clone)]
pub struct UserHandler {
   user_service: UserService,
}

impl UserHandler {
   pub fn new(user_service: UserService) -> Self {
      Self { user_service }
   }

   pub async fn search_users(
      auth_user: AuthUser,
      State(handler): State<UserHandler>,
      Query(mut request): Query<SearchUsersRequest>,
   ) -> Result<Json<UserResponse<SearchUsersResponse>>, (StatusCode, Json<UserResponse<()>>)> {
      // Normalize query to lowercase
      request.query = request.query.trim().to_lowercase();

      // Validate request
      if let Err(validation_errors) = request.validate() {
         let error_message = validation_errors
            .field_errors()
            .iter()
            .map(|(field, errors)| {
               let messages: Vec<String> = errors
                  .iter()
                  .filter_map(|e| e.message.as_ref().map(|m| m.to_string()))
                  .collect();
               format!("{}: {}", field, messages.join(", "))
            })
            .collect::<Vec<_>>()
            .join("; ");

         return Err((
            StatusCode::BAD_REQUEST,
            Json(UserResponse {
               success: false,
               data: None,
               error: Some(error_message),
            }),
         ));
      }

      // Check if query is empty after trim
      if request.query.is_empty() {
         return Err((
            StatusCode::BAD_REQUEST,
            Json(UserResponse {
               success: false,
               data: None,
               error: Some("Query cannot be empty".to_string()),
            }),
         ));
      }

      // Process search - exclude current user
      match handler.user_service.search_users(request, &auth_user.user_id).await {
         Ok(response) => Ok(Json(UserResponse {
            success: true,
            data: Some(response),
            error: None,
         })),
         Err(e) => {
            let error_msg = e.to_string();
            Err((
               StatusCode::INTERNAL_SERVER_ERROR,
               Json(UserResponse {
                  success: false,
                  data: None,
                  error: Some(error_msg),
               }),
            ))
         }
      }
   }

   pub async fn get_user_profile(
      _auth_user: AuthUser,
      State(handler): State<UserHandler>,
      Path(username): Path<String>,
   ) -> Result<Json<UserResponse<UserProfile>>, (StatusCode, Json<UserResponse<()>>)> {
      // Normalize username to lowercase
      let username = username.trim().to_lowercase();

      // Validate username is not empty
      if username.is_empty() {
         return Err((
            StatusCode::BAD_REQUEST,
            Json(UserResponse {
               success: false,
               data: None,
               error: Some("Username cannot be empty".to_string()),
            }),
         ));
      }

      // Get user profile
      match handler.user_service.get_user_profile(&username).await {
         Ok(profile) => Ok(Json(UserResponse {
            success: true,
            data: Some(profile),
            error: None,
         })),
         Err(e) => {
            let error_msg = e.to_string();
            let status_code = if error_msg.contains("not found") {
               StatusCode::NOT_FOUND
            } else {
               StatusCode::INTERNAL_SERVER_ERROR
            };

            Err((
               status_code,
               Json(UserResponse {
                  success: false,
                  data: None,
                  error: Some(error_msg),
               }),
            ))
         }
      }
   }
}
