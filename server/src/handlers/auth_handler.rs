use crate::dtos::auth::{AuthResponse, LoginRequest, LoginResponse, RegisterRequest, RegisterResponse};
use crate::services::auth_service::AuthService;
use axum::{extract::State, http::StatusCode, Json};
use validator::Validate;

#[derive(Clone)]
pub struct AuthHandler {
    auth_service: AuthService,
}

impl AuthHandler {
    pub fn new(auth_service: AuthService) -> Self {
        Self { auth_service }
    }

    pub async fn register(
        State(handler): State<AuthHandler>,
        Json(mut payload): Json<RegisterRequest>,
    ) -> Result<Json<AuthResponse<RegisterResponse>>, (StatusCode, Json<AuthResponse<()>>)> {
        // Normalize username to lowercase before validation
        payload.normalize_username();
        
        // Validate request
        if let Err(validation_errors) = payload.validate() {
            let error_message = validation_errors
                .field_errors()
                .iter()
                .map(|(field, errors)| {
                    let messages: Vec<String> = errors
                        .iter()
                        .filter_map(|e| e.message.as_ref().map(|m| m.to_string()))
                        .collect();
                    format!("{}: {}", field, messages.join(", "))
                })
                .collect::<Vec<_>>()
                .join("; ");

            return Err((
                StatusCode::BAD_REQUEST,
                Json(AuthResponse {
                    success: false,
                    data: None,
                    error: Some(error_message),
                }),
            ));
        }

        // Process registration
        match handler.auth_service.register(payload).await {
            Ok(response) => Ok(Json(AuthResponse {
                success: true,
                data: Some(response),
                error: None,
            })),
            Err(e) => {
                let error_msg = e.to_string();
                let status_code = if error_msg.contains("already exists") {
                    StatusCode::CONFLICT
                } else {
                    StatusCode::INTERNAL_SERVER_ERROR
                };

                Err((
                    status_code,
                    Json(AuthResponse {
                        success: false,
                        data: None,
                        error: Some(error_msg),
                    }),
                ))
            }
        }
    }

    pub async fn login(
        State(handler): State<AuthHandler>,
        Json(mut payload): Json<LoginRequest>,
    ) -> Result<Json<AuthResponse<LoginResponse>>, (StatusCode, Json<AuthResponse<()>>)> {
        // Normalize username to lowercase before validation
        payload.normalize_username();
        
        // Validate request
        if let Err(validation_errors) = payload.validate() {
            let error_message = validation_errors
                .field_errors()
                .iter()
                .map(|(field, errors)| {
                    let messages: Vec<String> = errors
                        .iter()
                        .filter_map(|e| e.message.as_ref().map(|m| m.to_string()))
                        .collect();
                    format!("{}: {}", field, messages.join(", "))
                })
                .collect::<Vec<_>>()
                .join("; ");

            return Err((
                StatusCode::BAD_REQUEST,
                Json(AuthResponse {
                    success: false,
                    data: None,
                    error: Some(error_message),
                }),
            ));
        }

        // Process login
        match handler.auth_service.login(payload).await {
            Ok(response) => Ok(Json(AuthResponse {
                success: true,
                data: Some(response),
                error: None,
            })),
            Err(e) => {
                let error_msg = e.to_string();
                let status_code = if error_msg.contains("Invalid username or password") {
                    StatusCode::UNAUTHORIZED
                } else {
                    StatusCode::INTERNAL_SERVER_ERROR
                };

                Err((
                    status_code,
                    Json(AuthResponse {
                        success: false,
                        data: None,
                        error: Some(error_msg),
                    }),
                ))
            }
        }
    }
}
