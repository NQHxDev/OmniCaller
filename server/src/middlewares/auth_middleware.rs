use crate::utils::jwt::{verify_access_token, JwtConfig, TokenPayload};
use axum::{
   async_trait,
   extract::FromRequestParts,
   http::{request::Parts, StatusCode},
   response::{IntoResponse, Response},
   Json,
};
use serde_json::json;

#[derive(Clone)]
pub struct AuthState {
   pub jwt_config: JwtConfig,
}

pub struct AuthUser {
   pub user_id: String,
   pub username: String,
   pub token_payload: TokenPayload,
}

#[async_trait]
impl<S> FromRequestParts<S> for AuthUser
where
   S: Send + Sync,
{
   type Rejection = Response;

   async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
      // Extract AuthState from extensions
      let auth_state = parts.extensions.get::<AuthState>().ok_or_else(|| {
         (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "success": false,
                "error": "Authentication configuration error"
            })),
         )
            .into_response()
      })?;

      // Extract Authorization header
      let authorization = parts
         .headers
         .get("Authorization")
         .and_then(|h| h.to_str().ok())
         .ok_or_else(|| {
            (
               StatusCode::UNAUTHORIZED,
               Json(json!({
                   "success": false,
                   "error": "Missing authorization header"
               })),
            )
               .into_response()
         })?;

      // Extract token from "Bearer <token>"
      let token = authorization.strip_prefix("Bearer ").ok_or_else(|| {
         (
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "success": false,
                "error": "Invalid authorization format"
            })),
         )
            .into_response()
      })?;

      // Verify token
      let token_payload = verify_access_token(token, &auth_state.jwt_config).map_err(|e| {
         (
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "success": false,
                "error": format!("Invalid token: {}", e)
            })),
         )
            .into_response()
      })?;

      Ok(AuthUser {
         user_id: token_payload.sub.clone(),
         username: token_payload.username.clone(),
         token_payload,
      })
   }
}
