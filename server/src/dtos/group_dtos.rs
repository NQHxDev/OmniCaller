use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Deserialize, Validate)]
pub struct CreateGroupRequest {
   #[validate(length(
      min = 1,
      max = 100,
      message = "Group name must be between 1 and 100 characters"
   ))]
   pub name: String,

   #[validate(length(max = 500, message = "Description must not exceed 500 characters"))]
   pub description: Option<String>,

   pub avatar_url: Option<String>,
   pub banner_url: Option<String>,

   #[validate(length(min = 1, message = "At least one member is required"))]
   pub member_ids: Vec<Uuid>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateGroupProfileRequest {
   #[validate(length(
      min = 1,
      max = 100,
      message = "Group name must be between 1 and 100 characters"
   ))]
   pub name: Option<String>,

   #[validate(length(max = 500, message = "Description must not exceed 500 characters"))]
   pub description: Option<String>,

   pub avatar_url: Option<String>,
   pub banner_url: Option<String>,
   pub pinned_message_id: Option<Uuid>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GroupProfileResponse {
   pub id: Uuid,
   pub name: String,
   pub description: Option<String>,
   pub avatar_url: Option<String>,
   pub banner_url: Option<String>,
   pub pinned_message_id: Option<Uuid>,
   pub created_by: Uuid,
   pub member_count: i64,
   pub created_at: String,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CreateGroupInviteRequest {
   pub max_uses: Option<i32>,
   pub expires_in_seconds: Option<i64>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GroupInviteResponse {
   pub id: Uuid,
   pub conversation_id: Uuid,
   pub inviter_id: Uuid,
   pub inviter_name: String,
   pub code: String,
   pub max_uses: Option<i32>,
   pub uses_count: i32,
   pub expires_at: Option<String>,
   pub created_at: String,
   pub is_valid: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GroupInviteDetailResponse {
   pub code: String,
   pub group_id: Uuid,
   pub group_name: String,
   pub group_avatar_url: Option<String>,
   pub inviter_name: String,
   pub member_count: i64,
   pub is_valid: bool,
   pub expires_at: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct JoinGroupByInviteRequest {
   pub code: String,
}

#[derive(Debug, Deserialize)]
pub struct PromoteMemberRequest {
   pub user_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct DemoteMemberRequest {
   pub user_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct TransferOwnershipRequest {
   pub new_owner_id: Uuid,
}

#[derive(Debug, Serialize)]
pub struct RoleUpdateResponse {
   pub success: bool,
   pub message: String,
   pub user_id: Uuid,
   pub new_role: String,
}
