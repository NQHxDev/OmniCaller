mod config;
mod database;
mod dtos;
mod entities;
mod handlers;
mod migrations;
mod repositories;
mod services;
mod utils;

use axum::{
    routing::{get, post},
    Json, Router,
};
use config::Config;
use handlers::auth_handler::AuthHandler;
use repositories::account_repository::AccountRepository;
use repositories::user_repository::UserRepository;
use sea_orm::DatabaseConnection;
use sea_orm_migration::prelude::*;
use serde::{Deserialize, Serialize};
use services::auth_service::AuthService;
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use utils::jwt::JwtConfig;

#[derive(Debug, Serialize, Deserialize)]
struct HealthResponse {
    status: String,
    message: String,
    environment: String,
    database: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct ApiResponse<T> {
    success: bool,
    data: Option<T>,
    error: Option<String>,
}

#[derive(Clone)]
struct AppState {
    db: DatabaseConnection,
    config: Config,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Load and validate configuration
    let config = Config::from_env()?;
    config.validate()?;

    // Initialize tracing with log level from config
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| {
            format!("omnicaller_server={},tower_http=debug,axum=trace", config.app.log_level).into()
        }))
        .with(tracing_subscriber::fmt::layer())
        .init();

    tracing::info!("🚀 Starting OmniCaller Server");
    tracing::info!("Environment: {:?}", config.app.env);
    tracing::info!("Log level: {}", config.app.log_level);

    // Establish database connection
    tracing::info!("Connecting to database...");
    let db = database::establish_connection(&config.database).await?;

    // Run migrations
    tracing::info!("Running database migrations...");
    migrations::Migrator::up(&db, None).await?;
    tracing::info!("✅ Migrations completed");

    // Load JWT config
    let jwt_config = JwtConfig::from_env()?;

    // Initialize repositories
    let account_repo = AccountRepository::new(db.clone());
    let user_repo = UserRepository::new(db.clone());

    // Initialize services
    let auth_service = AuthService::new(account_repo, user_repo, jwt_config);

    // Initialize handlers
    let auth_handler = AuthHandler::new(auth_service);

    // Configure CORS
    let cors = CorsLayer::new().allow_origin(Any).allow_methods(Any).allow_headers(Any);

    // Create app state
    let state = AppState { 
        db: db.clone(), 
        config: config.clone(),
    };

    // Build auth routes
    let auth_routes = Router::new()
        .route("/register", post(AuthHandler::register))
        .route("/login", post(AuthHandler::login))
        .with_state(auth_handler);

    // Build application routes
    let app = Router::new()
        .route("/", get(root_handler))
        .route("/health", get(health_handler))
        .route("/api/echo", post(echo_handler))
        .nest("/api/auth", auth_routes)
        .with_state(state)
        .layer(cors)
        .layer(tower_http::trace::TraceLayer::new_for_http());

    // Start server
    let addr: SocketAddr = config.server_address().parse().expect("Invalid server address");
    tracing::info!("🚀 Server listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn root_handler() -> Json<ApiResponse<String>> {
    Json(ApiResponse {
        success: true,
        data: Some("OmniCaller Server".to_string()),
        error: None,
    })
}

async fn health_handler(
    axum::extract::State(state): axum::extract::State<AppState>,
) -> Json<HealthResponse> {
    let db_status = match state.db.ping().await {
        Ok(_) => "connected",
        Err(_) => "disconnected",
    };

    Json(HealthResponse {
        status: "healthy".to_string(),
        message: "Server is running".to_string(),
        environment: format!("{:?}", state.config.app.env),
        database: db_status.to_string(),
    })
}

async fn echo_handler(
    Json(payload): Json<serde_json::Value>,
) -> Json<ApiResponse<serde_json::Value>> {
    Json(ApiResponse {
        success: true,
        data: Some(payload),
        error: None,
    })
}
