use crate::config::DatabaseConfig;
use anyhow::Result;
use sea_orm::{ConnectOptions, Database, DatabaseConnection};
use std::time::Duration;

pub async fn establish_connection(config: &DatabaseConfig) -> Result<DatabaseConnection> {
   let mut opt = ConnectOptions::new(&config.url);
   opt.max_connections(config.max_connections)
      .min_connections(config.min_connections)
      .connect_timeout(Duration::from_secs(config.connect_timeout))
      .acquire_timeout(Duration::from_secs(config.connect_timeout))
      .idle_timeout(Duration::from_secs(600))
      .max_lifetime(Duration::from_secs(3600))
      .sqlx_logging(true)
      .sqlx_logging_level(log::LevelFilter::Debug);

   let db = Database::connect(opt).await?;

   tracing::info!("Database connection established");

   Ok(db)
}

#[cfg(test)]
mod tests {
   use super::*;

   #[test]
   fn test_connect_options() {
      let config = DatabaseConfig {
         url: "postgresql://localhost/test".to_string(),
         max_connections: 10,
         min_connections: 2,
         connect_timeout: 30,
      };

      let mut opt = ConnectOptions::new(&config.url);
      opt.max_connections(config.max_connections)
         .min_connections(config.min_connections);

      assert_eq!(opt.get_max_connections(), Some(10));
      assert_eq!(opt.get_min_connections(), Some(2));
   }
}
