use serde::{Deserialize, Serialize};
use validator::Validate;

#[derive(Debug, Deserialize, Validate)]
pub struct SearchUsersRequest {
   #[validate(length(
      min = 1,
      max = 100,
      message = "Query must be between 1 and 100 characters"
   ))]
   pub query: String,

   #[validate(range(min = 1, message = "Page must be at least 1"))]
   pub page: Option<u64>,

   #[validate(range(min = 1, max = 100, message = "Page size must be between 1 and 100"))]
   pub page_size: Option<u64>,
}

#[derive(Debug, Serialize)]
pub struct UserSearchResult {
   pub user_id: String,
   pub username: String,
   pub display_name: String,
}

#[derive(Debug, Serialize)]
pub struct SearchUsersResponse {
   pub users: Vec<UserSearchResult>,
   pub pagination: PaginationInfo,
}

#[derive(Debug, Serialize)]
pub struct PaginationInfo {
   pub current_page: u64,
   pub page_size: u64,
   pub total_items: u64,
   pub total_pages: u64,
}

#[derive(Debug, Serialize)]
pub struct UserResponse<T> {
   pub success: bool,
   pub data: Option<T>,
   pub error: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct UserProfile {
   pub user_id: String,
   pub username: String,
   pub display_name: String,
   pub created_at: String,
}
