mod config;
mod database;
mod dtos;
mod entities;
mod handlers;
mod middlewares;
mod migrations;
mod repositories;
mod services;
mod utils;

use axum::{
   middleware,
   routing::{delete, get, post},
   Json, Router,
};
use config::Config;
use handlers::auth_handler::AuthHandler;
use handlers::friend_handler::FriendHandler;
use handlers::user_handler::UserHandler;
use middlewares::auth_middleware::AuthState;
use repositories::account_repository::AccountRepository;
use repositories::friend_repository::FriendRepository;
use repositories::user_repository::UserRepository;
use sea_orm::DatabaseConnection;
use sea_orm_migration::prelude::*;
use serde::{Deserialize, Serialize};
use services::auth_service::AuthService;
use services::friend_service::FriendService;
use services::user_service::UserService;
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
   let friend_repo = FriendRepository::new(db.clone());

   // Initialize services
   let auth_service = AuthService::new(account_repo, user_repo.clone(), jwt_config.clone());
   let user_service = UserService::new(user_repo.clone());
   let friend_service = FriendService::new(friend_repo, user_repo.clone());

   // Initialize handlers
   let auth_handler = AuthHandler::new(auth_service);
   let user_handler = UserHandler::new(user_service);
   let friend_handler = FriendHandler::new(friend_service);

   // Configure CORS
   let cors = CorsLayer::new().allow_origin(Any).allow_methods(Any).allow_headers(Any);

   // Create app state
   let state = AppState { db: db.clone(), config: config.clone() };

   // Create auth states for middlewares
   let auth_state_auth = AuthState { jwt_config: jwt_config.clone() };
   let auth_state_user = AuthState { jwt_config: jwt_config.clone() };
   let auth_state_friend = AuthState { jwt_config: jwt_config.clone() };

   // Build public auth routes
   let public_auth_routes = Router::new()
      .route("/register", post(AuthHandler::register))
      .route("/login", post(AuthHandler::login))
      .route("/refresh", post(AuthHandler::refresh_token))
      .with_state(auth_handler.clone());

   // Build protected auth routes (require authentication)
   let protected_auth_routes = Router::new()
      .route("/logout", post(AuthHandler::logout))
      .with_state(auth_handler)
      .layer(middleware::from_fn(
         move |mut req: axum::extract::Request, next: axum::middleware::Next| {
            let auth_state = auth_state_auth.clone();
            async move {
               req.extensions_mut().insert(auth_state);
               next.run(req).await
            }
         },
      ));

   // Merge auth routes
   let auth_routes = Router::new().merge(public_auth_routes).merge(protected_auth_routes);

   // Build user routes (all require authentication)
   let user_routes = Router::new()
      .route("/search", get(UserHandler::search_users))
      .route("/:username", get(UserHandler::get_user_profile))
      .with_state(user_handler)
      .layer(middleware::from_fn(
         move |mut req: axum::extract::Request, next: axum::middleware::Next| {
            let auth_state = auth_state_user.clone();
            async move {
               req.extensions_mut().insert(auth_state);
               next.run(req).await
            }
         },
      ));

   // Build friend routes (all require authentication)
   let friend_routes = Router::new()
      .route("/", get(FriendHandler::get_friends))
      .route("/request", post(FriendHandler::send_friend_request))
      .route(
         "/requests",
         post(FriendHandler::send_friend_request).get(FriendHandler::get_pending_requests),
      )
      .route("/requests/received", get(FriendHandler::get_received_requests))
      .route("/requests/sent", get(FriendHandler::get_sent_requests))
      .route("/requests/:id/accept", post(FriendHandler::accept_friend_request_by_path))
      .route("/requests/:id/reject", post(FriendHandler::reject_friend_request_by_path))
      .route(
         "/requests/:id/cancel",
         delete(FriendHandler::cancel_friend_request_by_path)
            .post(FriendHandler::cancel_friend_request_by_path),
      )
      .route("/requests/:id", delete(FriendHandler::cancel_friend_request_by_path))
      .route("/respond", post(FriendHandler::respond_to_friend_request))
      .route("/status/:user_id", get(FriendHandler::get_friendship_status))
      .route("/pending", get(FriendHandler::get_pending_requests))
      .route("/:friendship_id", delete(FriendHandler::remove_friend))
      .route("/:friendship_id/block", post(FriendHandler::block_user))
      .with_state(friend_handler)
      .layer(middleware::from_fn(
         move |mut req: axum::extract::Request, next: axum::middleware::Next| {
            let auth_state = auth_state_friend.clone();
            async move {
               req.extensions_mut().insert(auth_state);
               next.run(req).await
            }
         },
      ));

   // Build application routes
   let app = Router::new()
      .route("/", get(root_handler))
      .route("/health", get(health_handler))
      .route("/api/echo", post(echo_handler))
      .nest("/api/auth", auth_routes)
      .nest("/api/users", user_routes)
      .nest("/api/friends", friend_routes)
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
