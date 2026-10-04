use serde::{Deserialize, Serialize};
use validator::Validate;

#[derive(Debug, Deserialize, Validate)]
pub struct RegisterRequest {
    #[validate(length(min = 2, max = 50, message = "Display name must be between 2 and 50 characters"))]
    pub display_name: String,

    #[validate(
        length(min = 6, max = 30, message = "Username must be between 6 and 30 characters"),
        custom(function = "validate_username")
    )]
    pub username: String,

    #[validate(length(min = 6, max = 100, message = "Password must be between 6 and 100 characters"))]
    pub password: String,

    #[validate(must_match(other = "password", message = "Passwords do not match"))]
    pub confirm_password: String,
}

#[derive(Debug, Serialize)]
pub struct RegisterResponse {
    pub user_id: String,
    pub username: String,
    pub display_name: String,
    pub access_token: String,
    pub refresh_token: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<String>,
}

impl RegisterRequest {
    /// Normalize username to lowercase
    pub fn normalize_username(&mut self) {
        self.username = self.username.to_lowercase();
    }
}

fn validate_username(username: &str) -> Result<(), validator::ValidationError> {
    let re = regex::Regex::new(r"^[a-z0-9]+$").unwrap();
    if !re.is_match(username) {
        return Err(validator::ValidationError::new("invalid_username"));
    }
    Ok(())
}

#[derive(Debug, Deserialize, Validate)]
pub struct LoginRequest {
    #[validate(length(min = 6, max = 30, message = "Username must be between 6 and 30 characters"))]
    pub username: String,

    #[validate(length(min = 6, max = 100, message = "Password must be between 6 and 100 characters"))]
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct LoginResponse {
    pub user_id: String,
    pub username: String,
    pub display_name: String,
    pub access_token: String,
    pub refresh_token: String,
}

impl LoginRequest {
    /// Normalize username to lowercase
    pub fn normalize_username(&mut self) {
        self.username = self.username.to_lowercase();
    }
}
