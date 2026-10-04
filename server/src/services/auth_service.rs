use crate::dtos::auth::{LoginRequest, LoginResponse, RegisterRequest, RegisterResponse};
use crate::repositories::account_repository::AccountRepository;
use crate::repositories::user_repository::UserRepository;
use crate::utils::jwt::{generate_access_token, generate_refresh_token, JwtConfig};
use crate::utils::password::{hash_password, verify_password};
use anyhow::{Context, Result};

#[derive(Clone)]
pub struct AuthService {
    account_repo: AccountRepository,
    user_repo: UserRepository,
    jwt_config: JwtConfig,
}

impl AuthService {
    pub fn new(
        account_repo: AccountRepository,
        user_repo: UserRepository,
        jwt_config: JwtConfig,
    ) -> Self {
        Self {
            account_repo,
            user_repo,
            jwt_config,
        }
    }

    /// Register a new user
    pub async fn register(&self, mut request: RegisterRequest) -> Result<RegisterResponse> {
        // Normalize username to lowercase
        request.normalize_username();

        // Check if username already exists
        if self.account_repo.username_exists(&request.username).await? {
            anyhow::bail!("Username already exists");
        }

        // Hash password
        let password_hash = hash_password(&request.password)
            .context("Failed to hash password")?;

        // Create account
        let account = self
            .account_repo
            .create(&request.username, &password_hash)
            .await
            .context("Failed to create account")?;

        // Create user
        let user = self
            .user_repo
            .create(&account.id, &request.display_name)
            .await
            .context("Failed to create user")?;

        // Generate tokens
        let access_token = generate_access_token(&user.id, &account.username, &self.jwt_config)
            .context("Failed to generate access token")?;

        let refresh_token = generate_refresh_token(&user.id, &account.username, &self.jwt_config)
            .context("Failed to generate refresh token")?;

        Ok(RegisterResponse {
            user_id: user.id.to_string(),
            username: account.username,
            display_name: user.display_name,
            access_token,
            refresh_token,
        })
    }

    /// Login user
    pub async fn login(&self, mut request: LoginRequest) -> Result<LoginResponse> {
        // Normalize username to lowercase
        request.normalize_username();

        // Find account by username
        let account = self
            .account_repo
            .find_by_username(&request.username)
            .await
            .context("Failed to query account")?
            .ok_or_else(|| anyhow::anyhow!("Invalid username or password"))?;

        // Verify password
        let is_valid = verify_password(&request.password, &account.password)
            .context("Failed to verify password")?;

        if !is_valid {
            anyhow::bail!("Invalid username or password");
        }

        // Get user profile
        let user = self
            .user_repo
            .find_by_account_id(&account.id)
            .await
            .context("Failed to query user")?
            .ok_or_else(|| anyhow::anyhow!("User profile not found"))?;

        // Generate tokens
        let access_token = generate_access_token(&user.id, &account.username, &self.jwt_config)
            .context("Failed to generate access token")?;

        let refresh_token = generate_refresh_token(&user.id, &account.username, &self.jwt_config)
            .context("Failed to generate refresh token")?;

        Ok(LoginResponse {
            user_id: user.id.to_string(),
            username: account.username,
            display_name: user.display_name,
            access_token,
            refresh_token,
        })
    }
}
