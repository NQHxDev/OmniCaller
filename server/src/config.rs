use anyhow::{Context, Result};
use serde::Deserialize;
use std::env;

#[derive(Debug, Clone, Deserialize)]
pub struct Config {
   pub server: ServerConfig,
   pub app: AppConfig,
   pub database: DatabaseConfig,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ServerConfig {
   pub host: String,
   pub port: u16,
}

#[derive(Debug, Clone, Deserialize)]
pub struct AppConfig {
   pub env: Environment,
   pub log_level: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct DatabaseConfig {
   pub url: String,
   pub max_connections: u32,
   pub min_connections: u32,
   pub connect_timeout: u64,
}

#[derive(Debug, Clone, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum Environment {
   Development,
   Staging,
   Production,
}

impl Config {
   pub fn from_env() -> Result<Self> {
      // Load .env file if exists (ignore if not found)
      dotenvy::dotenv().ok();

      let server = ServerConfig {
         host: env::var("SERVER_HOST").unwrap_or_else(|_| "0.0.0.0".to_string()),
         port: env::var("SERVER_PORT")
            .unwrap_or_else(|_| "3000".to_string())
            .parse()
            .context("SERVER_PORT must be a valid port number")?,
      };

      let app = AppConfig {
         env: env::var("APP_ENV")
            .unwrap_or_else(|_| "development".to_string())
            .parse()
            .context("APP_ENV must be one of: development, staging, production")?,
         log_level: env::var("LOG_LEVEL").unwrap_or_else(|_| "info".to_string()),
      };

      let database = DatabaseConfig {
         url: env::var("DATABASE_URL").context("DATABASE_URL is required")?,
         max_connections: env::var("DATABASE_MAX_CONNECTIONS")
            .unwrap_or_else(|_| "10".to_string())
            .parse()
            .context("DATABASE_MAX_CONNECTIONS must be a valid number")?,
         min_connections: env::var("DATABASE_MIN_CONNECTIONS")
            .unwrap_or_else(|_| "2".to_string())
            .parse()
            .context("DATABASE_MIN_CONNECTIONS must be a valid number")?,
         connect_timeout: env::var("DATABASE_CONNECT_TIMEOUT")
            .unwrap_or_else(|_| "30".to_string())
            .parse()
            .context("DATABASE_CONNECT_TIMEOUT must be a valid number")?,
      };

      Ok(Config { server, app, database })
   }

   pub fn validate(&self) -> Result<()> {
      // Validate port range
      if self.server.port == 0 {
         anyhow::bail!("SERVER_PORT cannot be 0");
      }

      // Validate log level
      let valid_log_levels = ["trace", "debug", "info", "warn", "error"];
      if !valid_log_levels.contains(&self.app.log_level.as_str()) {
         anyhow::bail!("LOG_LEVEL must be one of: {}", valid_log_levels.join(", "));
      }

      // Validate database config
      if self.database.url.is_empty() {
         anyhow::bail!("DATABASE_URL cannot be empty");
      }

      if self.database.max_connections == 0 {
         anyhow::bail!("DATABASE_MAX_CONNECTIONS must be greater than 0");
      }

      if self.database.min_connections > self.database.max_connections {
         anyhow::bail!("DATABASE_MIN_CONNECTIONS cannot be greater than DATABASE_MAX_CONNECTIONS");
      }

      Ok(())
   }

   pub fn server_address(&self) -> String {
      format!("{}:{}", self.server.host, self.server.port)
   }
}

impl std::str::FromStr for Environment {
   type Err = anyhow::Error;

   fn from_str(s: &str) -> Result<Self, Self::Err> {
      match s.to_lowercase().as_str() {
         "development" | "dev" => Ok(Environment::Development),
         "staging" | "stage" => Ok(Environment::Staging),
         "production" | "prod" => Ok(Environment::Production),
         _ => anyhow::bail!("Invalid environment: {}", s),
      }
   }
}

#[cfg(test)]
mod tests {
   use super::*;

   #[test]
   fn test_environment_from_str() {
      assert_eq!("development".parse::<Environment>().unwrap(), Environment::Development);
      assert_eq!("dev".parse::<Environment>().unwrap(), Environment::Development);
      assert_eq!("production".parse::<Environment>().unwrap(), Environment::Production);
   }

   #[test]
   fn test_config_validation() {
      let config = Config {
         server: ServerConfig { host: "0.0.0.0".to_string(), port: 3000 },
         app: AppConfig {
            env: Environment::Development,
            log_level: "info".to_string(),
         },
         database: DatabaseConfig {
            url: "postgresql://localhost/test".to_string(),
            max_connections: 10,
            min_connections: 2,
            connect_timeout: 30,
         },
      };

      assert!(config.validate().is_ok());
   }

   #[test]
   fn test_invalid_port() {
      let config = Config {
         server: ServerConfig { host: "0.0.0.0".to_string(), port: 0 },
         app: AppConfig {
            env: Environment::Development,
            log_level: "info".to_string(),
         },
         database: DatabaseConfig {
            url: "postgresql://localhost/test".to_string(),
            max_connections: 10,
            min_connections: 2,
            connect_timeout: 30,
         },
      };

      assert!(config.validate().is_err());
   }
}
