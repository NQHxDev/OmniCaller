use crate::dtos::group_dtos::{CreateGroupRequest, GroupProfileResponse};
use crate::middlewares::auth_middleware::AuthUser;
use crate::services::group_service::GroupService;
use axum::{extract::State, http::StatusCode, Json};
use serde::Serialize;
use uuid::Uuid;
use validator::Validate;

#[derive(Clone)]
pub struct GroupHandler {
   group_service: GroupService,
}

impl GroupHandler {
   pub fn new(group_service: GroupService) -> Self {
      Self { group_service }
   }

   /// POST /groups - Create a new group
   pub async fn create_group(
      auth_user: AuthUser,
      State(handler): State<Self>,
      Json(request): Json<CreateGroupRequest>,
   ) -> Result<(StatusCode, Json<GroupProfileResponse>), (StatusCode, Json<ErrorResponse>)> {
      let user_id = Uuid::parse_str(&auth_user.user_id).map_err(|_| {
         (
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
               error: "Invalid user ID in token".to_string(),
            }),
         )
      })?;

      // Validate request
      if let Err(validation_errors) = request.validate() {
         return Err((
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
               error: format!("Validation error: {}", validation_errors),
            }),
         ));
      }

      // Create group
      match handler.group_service.create_group(&user_id, request).await {
         Ok(group) => Ok((StatusCode::CREATED, Json(group))),
         Err(e) => {
            eprintln!("Failed to create group: {}", e);
            Err((StatusCode::INTERNAL_SERVER_ERROR, Json(ErrorResponse { error: e.to_string() })))
         }
      }
   }

   /// GET /groups - Get all groups the user is a member of
   pub async fn get_user_groups(
      auth_user: AuthUser,
      State(handler): State<Self>,
   ) -> Result<(StatusCode, Json<GroupsResponse>), (StatusCode, Json<ErrorResponse>)> {
      let user_id = Uuid::parse_str(&auth_user.user_id).map_err(|_| {
         (
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
               error: "Invalid user ID in token".to_string(),
            }),
         )
      })?;

      match handler.group_service.get_user_groups(&user_id).await {
         Ok(groups) => Ok((StatusCode::OK, Json(GroupsResponse { groups }))),
         Err(e) => {
            eprintln!("Failed to get user groups: {}", e);
            Err((
               StatusCode::INTERNAL_SERVER_ERROR,
               Json(ErrorResponse {
                  error: "Failed to retrieve groups".to_string(),
               }),
            ))
         }
      }
   }

   /// POST /groups/:id/members/promote - Promote member to admin
   pub async fn promote_member(
      auth_user: AuthUser,
      State(handler): State<Self>,
      axum::extract::Path(group_id): axum::extract::Path<Uuid>,
      Json(request): Json<crate::dtos::group_dtos::PromoteMemberRequest>,
   ) -> Result<
      (StatusCode, Json<crate::dtos::group_dtos::RoleUpdateResponse>),
      (StatusCode, Json<ErrorResponse>),
   > {
      let user_id = Uuid::parse_str(&auth_user.user_id).map_err(|_| {
         (
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
               error: "Invalid user ID in token".to_string(),
            }),
         )
      })?;

      match handler
         .group_service
         .promote_member_to_admin(&group_id, &user_id, &request.user_id)
         .await
      {
         Ok(_) => Ok((
            StatusCode::OK,
            Json(crate::dtos::group_dtos::RoleUpdateResponse {
               success: true,
               message: "Member promoted to admin successfully".to_string(),
               user_id: request.user_id,
               new_role: "admin".to_string(),
            }),
         )),
         Err(e) => {
            eprintln!("Failed to promote member: {}", e);
            Err((StatusCode::FORBIDDEN, Json(ErrorResponse { error: e.to_string() })))
         }
      }
   }

   /// POST /groups/:id/members/demote - Demote admin to member
   pub async fn demote_member(
      auth_user: AuthUser,
      State(handler): State<Self>,
      axum::extract::Path(group_id): axum::extract::Path<Uuid>,
      Json(request): Json<crate::dtos::group_dtos::DemoteMemberRequest>,
   ) -> Result<
      (StatusCode, Json<crate::dtos::group_dtos::RoleUpdateResponse>),
      (StatusCode, Json<ErrorResponse>),
   > {
      let user_id = Uuid::parse_str(&auth_user.user_id).map_err(|_| {
         (
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
               error: "Invalid user ID in token".to_string(),
            }),
         )
      })?;

      match handler
         .group_service
         .demote_admin_to_member(&group_id, &user_id, &request.user_id)
         .await
      {
         Ok(_) => Ok((
            StatusCode::OK,
            Json(crate::dtos::group_dtos::RoleUpdateResponse {
               success: true,
               message: "Admin demoted to member successfully".to_string(),
               user_id: request.user_id,
               new_role: "member".to_string(),
            }),
         )),
         Err(e) => {
            eprintln!("Failed to demote admin: {}", e);
            Err((StatusCode::FORBIDDEN, Json(ErrorResponse { error: e.to_string() })))
         }
      }
   }

   /// POST /groups/:id/transfer-ownership - Transfer ownership to an admin
   pub async fn transfer_ownership(
      auth_user: AuthUser,
      State(handler): State<Self>,
      axum::extract::Path(group_id): axum::extract::Path<Uuid>,
      Json(request): Json<crate::dtos::group_dtos::TransferOwnershipRequest>,
   ) -> Result<
      (StatusCode, Json<crate::dtos::group_dtos::RoleUpdateResponse>),
      (StatusCode, Json<ErrorResponse>),
   > {
      let user_id = Uuid::parse_str(&auth_user.user_id).map_err(|_| {
         (
            StatusCode::BAD_REQUEST,
            Json(ErrorResponse {
               error: "Invalid user ID in token".to_string(),
            }),
         )
      })?;

      match handler
         .group_service
         .transfer_ownership(&group_id, &user_id, &request.new_owner_id)
         .await
      {
         Ok(_) => Ok((
            StatusCode::OK,
            Json(crate::dtos::group_dtos::RoleUpdateResponse {
               success: true,
               message: "Ownership transferred successfully".to_string(),
               user_id: request.new_owner_id,
               new_role: "owner".to_string(),
            }),
         )),
         Err(e) => {
            eprintln!("Failed to transfer ownership: {}", e);
            Err((StatusCode::FORBIDDEN, Json(ErrorResponse { error: e.to_string() })))
         }
      }
   }
}

#[derive(Serialize)]
pub struct GroupsResponse {
   pub groups: Vec<GroupProfileResponse>,
}

#[derive(Serialize)]
pub struct ErrorResponse {
   pub error: String,
}
