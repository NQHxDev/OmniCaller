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
   extract::State,
   middleware,
   routing::{delete, get, post, put},
   Json, Router,
};
use config::Config;
use dashmap::DashMap;
use handlers::auth_handler::AuthHandler;
use handlers::call_handler::{self, CallState};
use handlers::friend_handler::FriendHandler;
use handlers::group_handler::GroupHandler;
use handlers::message_handler::MessageHandler;
use handlers::user_handler::UserHandler;
use handlers::websocket_handler::{websocket_handler, ConnectionManager, WebSocketState};
use middlewares::auth_middleware::AuthState;
use repositories::account_repository::AccountRepository;
use repositories::conversation_repository::ConversationRepository;
use repositories::friend_repository::FriendRepository;
use repositories::message_repository::MessageRepository;
use repositories::user_repository::UserRepository;
use sea_orm::DatabaseConnection;
use sea_orm_migration::prelude::*;
use serde::{Deserialize, Serialize};
use services::auth_service::AuthService;
use services::call_service::CallService;
use services::friend_service::FriendService;
use services::group_service::GroupService;
use services::message_service::MessageService;
use services::user_service::UserService;
use std::net::SocketAddr;
use std::sync::Arc;
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
   let conversation_repo = ConversationRepository::new(db.clone());
   let message_repo = MessageRepository::new(db.clone());

   // Initialize services
   let auth_service = AuthService::new(account_repo, user_repo.clone(), jwt_config.clone());
   let user_service = UserService::new(user_repo.clone());
   let friend_service = FriendService::new(friend_repo.clone(), user_repo.clone());
   let message_service = MessageService::new(conversation_repo.clone(), message_repo, user_repo.clone());
   let group_service = GroupService::new(conversation_repo.clone(), friend_repo.clone());
   let call_service = CallService::new(db.clone());

   // Initialize handlers
   let auth_handler = AuthHandler::new(auth_service);
   let user_handler = UserHandler::new(user_service);
   let friend_handler = FriendHandler::new(friend_service);
   let message_handler = MessageHandler::new(message_service.clone());
   let group_handler = GroupHandler::new(group_service);

   // WebSocket connection manager
   let connections: ConnectionManager = Arc::new(DashMap::new());

   let call_state = CallState {
      call_service,
      jwt_config: jwt_config.clone(),
      connections: connections.clone(),
   };
   let ws_state = WebSocketState {
      jwt_config: jwt_config.clone(),
      message_service: message_service.clone(),
      connections: connections.clone(),
   };

   // Configure CORS
   let cors = CorsLayer::new().allow_origin(Any).allow_methods(Any).allow_headers(Any);

   // Create app state
   let state = AppState { db: db.clone(), config: config.clone() };

   // Create auth states for middlewares
   let auth_state_auth = AuthState { jwt_config: jwt_config.clone() };
   let auth_state_user = AuthState { jwt_config: jwt_config.clone() };
   let auth_state_friend = AuthState { jwt_config: jwt_config.clone() };
   let auth_state_message = AuthState { jwt_config: jwt_config.clone() };
   let auth_state_group = AuthState { jwt_config: jwt_config.clone() };
   let auth_state_call = AuthState { jwt_config: jwt_config.clone() };

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
      .route("/requests", post(FriendHandler::send_friend_request).get(FriendHandler::get_pending_requests))
      .route("/requests/received", get(FriendHandler::get_received_requests))
      .route("/requests/sent", get(FriendHandler::get_sent_requests))
      .route("/requests/:id/accept", post(FriendHandler::accept_friend_request_by_path))
      .route("/requests/:id/reject", post(FriendHandler::reject_friend_request_by_path))
      .route("/requests/:id/cancel", delete(FriendHandler::cancel_friend_request_by_path))
      .route("/requests/:id", delete(FriendHandler::cancel_friend_request_by_path))
      .route("/respond", post(FriendHandler::respond_to_friend_request))
      .route("/pending", get(FriendHandler::get_pending_requests))
      .route("/status/:user_id", get(FriendHandler::get_friendship_status))
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

   // Build message routes (all require authentication)
   let message_routes = Router::new()
      .route("/conversations/direct", post(MessageHandler::create_direct_conversation))
      .route("/conversations", get(MessageHandler::get_conversations))
      .route("/conversations/:id/messages", get(MessageHandler::get_messages))
      .route("/messages", post(MessageHandler::send_message))
      .with_state(message_handler)
      .layer(middleware::from_fn(
         move |mut req: axum::extract::Request, next: axum::middleware::Next| {
            let auth_state = auth_state_message.clone();
            async move {
               req.extensions_mut().insert(auth_state);
               next.run(req).await
            }
         },
      ));

   // Build group routes (all require authentication)
   let group_routes = Router::new()
      .route("/", post(GroupHandler::create_group).get(GroupHandler::get_user_groups))
      .route("/:id/members/promote", post(GroupHandler::promote_member))
      .route("/:id/members/demote", post(GroupHandler::demote_member))
      .route("/:id/transfer-ownership", post(GroupHandler::transfer_ownership))
      .with_state(group_handler)
      .layer(middleware::from_fn(
         move |mut req: axum::extract::Request, next: axum::middleware::Next| {
            let auth_state = auth_state_group.clone();
            async move {
               req.extensions_mut().insert(auth_state);
               next.run(req).await
            }
         },
      ));

   // Build call routes (all require authentication)
   let call_routes = Router::new()
      .route("/initiate", post(call_handler::initiate_call))
      .route("/:id/join", post(call_handler::join_call))
      .route("/:id/end", post(call_handler::end_call))
      .route("/:id/reject", post(call_handler::reject_call))
      .route("/:id/cancel", post(call_handler::cancel_call))
      .route("/history", get(call_handler::get_call_history))
      .route("/active", get(call_handler::get_active_calls))
      .route("/:id", get(call_handler::get_call))
      .with_state(call_state.clone())
      .layer(middleware::from_fn(
         move |mut req: axum::extract::Request, next: axum::middleware::Next| {
            let auth_state = auth_state_call.clone();
            async move {
               req.extensions_mut().insert(auth_state);
               next.run(req).await
            }
         },
      ));

   // Build presence routes (all require authentication)
   let presence_routes = Router::new()
      .route("/", put(call_handler::update_presence))
      .route("/:user_id", get(call_handler::get_presence))
      .with_state(call_state);

   // WebSocket route (separate router with its own state)
   let ws_router = Router::new().route("/ws", get(websocket_handler)).with_state(ws_state);

   // Build application routes
   let app = Router::new()
      .route("/", get(root_handler))
      .route("/health", get(health_handler))
      .route("/api/echo", post(echo_handler))
      .nest("/api/auth", auth_routes)
      .nest("/api/users", user_routes)
      .nest("/api/friends", friend_routes)
      .nest("/api/groups", group_routes)
      .nest("/api/calls", call_routes)
      .nest("/api/presence", presence_routes)
      .nest("/api", message_routes)
      .with_state(state)
      .merge(ws_router)
      .layer(cors)
      .layer(tower_http::trace::TraceLayer::new_for_http());

   // Start server
   let addr: SocketAddr = config.server_address().parse().expect("Invalid server address");
   tracing::info!("🚀 Server listening on {}", addr);
   tracing::info!("📡 WebSocket available at ws://{}/ws?token=YOUR_JWT_TOKEN", addr);

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

async fn health_handler(State(state): State<AppState>) -> Json<HealthResponse> {
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
