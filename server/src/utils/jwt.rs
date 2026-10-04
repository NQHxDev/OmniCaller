use anyhow::{Context, Result};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct TokenPayload {
   pub sub: String,      // Subject (user_id)
   pub username: String, // Username
   pub iat: u64,         // Issued at
   pub exp: u64,         // Expiration time
   pub token_type: TokenType,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum TokenType {
   Access,
   Refresh,
}

#[derive(Debug, Clone)]
pub struct JwtConfig {
   pub access_token_secret: String,
   pub refresh_token_secret: String,
   pub access_token_expiry: u64,  // in seconds
   pub refresh_token_expiry: u64, // in seconds
}

impl JwtConfig {
   pub fn from_env() -> Result<Self> {
      Ok(Self {
         access_token_secret: std::env::var("JWT_ACCESS_SECRET")
            .context("JWT_ACCESS_SECRET is required")?,
         refresh_token_secret: std::env::var("JWT_REFRESH_SECRET")
            .context("JWT_REFRESH_SECRET is required")?,
         access_token_expiry: std::env::var("JWT_ACCESS_EXPIRY")
                .unwrap_or_else(|_| "900".to_string()) // 15 minutes default
                .parse()
                .context("JWT_ACCESS_EXPIRY must be a valid number")?,
         refresh_token_expiry: std::env::var("JWT_REFRESH_EXPIRY")
                .unwrap_or_else(|_| "604800".to_string()) // 7 days default
                .parse()
                .context("JWT_REFRESH_EXPIRY must be a valid number")?,
      })
   }
}

pub fn generate_access_token(user_id: &Uuid, username: &str, config: &JwtConfig) -> Result<String> {
   let now = SystemTime::now()
      .duration_since(UNIX_EPOCH)
      .context("System time error")?
      .as_secs();

   let payload = TokenPayload {
      sub: user_id.to_string(),
      username: username.to_string(),
      iat: now,
      exp: now + config.access_token_expiry,
      token_type: TokenType::Access,
   };

   encode(
      &Header::default(),
      &payload,
      &EncodingKey::from_secret(config.access_token_secret.as_bytes()),
   )
   .context("Failed to generate access token")
}

pub fn generate_refresh_token(
   user_id: &Uuid,
   username: &str,
   config: &JwtConfig,
) -> Result<String> {
   let now = SystemTime::now()
      .duration_since(UNIX_EPOCH)
      .context("System time error")?
      .as_secs();

   let payload = TokenPayload {
      sub: user_id.to_string(),
      username: username.to_string(),
      iat: now,
      exp: now + config.refresh_token_expiry,
      token_type: TokenType::Refresh,
   };

   encode(
      &Header::default(),
      &payload,
      &EncodingKey::from_secret(config.refresh_token_secret.as_bytes()),
   )
   .context("Failed to generate refresh token")
}

pub fn verify_access_token(token: &str, config: &JwtConfig) -> Result<TokenPayload> {
   let token_data = decode::<TokenPayload>(
      token,
      &DecodingKey::from_secret(config.access_token_secret.as_bytes()),
      &Validation::default(),
   )
   .context("Invalid or expired access token")?;

   if token_data.claims.token_type != TokenType::Access {
      anyhow::bail!("Invalid token type");
   }

   Ok(token_data.claims)
}

pub fn verify_refresh_token(token: &str, config: &JwtConfig) -> Result<TokenPayload> {
   let token_data = decode::<TokenPayload>(
      token,
      &DecodingKey::from_secret(config.refresh_token_secret.as_bytes()),
      &Validation::default(),
   )
   .context("Invalid or expired refresh token")?;

   if token_data.claims.token_type != TokenType::Refresh {
      anyhow::bail!("Invalid token type");
   }

   Ok(token_data.claims)
}
