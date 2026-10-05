use crate::dtos::user::{
   PaginationInfo, SearchUsersRequest, SearchUsersResponse, UserProfile, UserSearchResult,
};
use crate::repositories::user_repository::UserRepository;
use anyhow::{Context, Result};
use uuid::Uuid;

#[derive(Clone)]
pub struct UserService {
   user_repo: UserRepository,
}

impl UserService {
   pub fn new(user_repo: UserRepository) -> Self {
      Self { user_repo }
   }

   /// Search users by display name or username (excluding current user)
   pub async fn search_users(
      &self,
      request: SearchUsersRequest,
      current_user_id: &str,
   ) -> Result<SearchUsersResponse> {
      let page = request.page.unwrap_or(1);
      let page_size = request.page_size.unwrap_or(10);

      // Parse current user ID
      let current_user_uuid = Uuid::parse_str(current_user_id).context("Invalid user ID format")?;

      let (users, total) = self
         .user_repo
         .search(&request.query, page, page_size, Some(&current_user_uuid))
         .await
         .context("Failed to search users")?;

      let user_results: Vec<UserSearchResult> = users
         .into_iter()
         .map(|(user, account)| UserSearchResult {
            user_id: user.id.to_string(),
            username: account.username,
            display_name: user.display_name,
         })
         .collect();

      let total_pages = (total as f64 / page_size as f64).ceil() as u64;

      Ok(SearchUsersResponse {
         users: user_results,
         pagination: PaginationInfo {
            current_page: page,
            page_size,
            total_items: total,
            total_pages,
         },
      })
   }

   /// Get user profile by username
   pub async fn get_user_profile(&self, username: &str) -> Result<UserProfile> {
      let (user, account) = self
         .user_repo
         .find_by_username(username)
         .await
         .context("Failed to query user")?
         .ok_or_else(|| anyhow::anyhow!("User not found"))?;

      Ok(UserProfile {
         user_id: user.id.to_string(),
         username: account.username,
         display_name: user.display_name,
         created_at: user.created_at.to_string(),
      })
   }
}
