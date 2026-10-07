use crate::dtos::call_dtos::*;
use crate::dtos::message_dtos::{WsServerMessage, MessageDto};
use crate::entities::message::{MessageType, MessageStatus};
use crate::handlers::websocket_handler::ConnectionManager;
use crate::services::call_service::CallService;
use crate::utils::jwt::{verify_access_token, JwtConfig};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Deserialize;
use uuid::Uuid;

#[derive(Clone)]
pub struct CallState {
    pub call_service: CallService,
    pub jwt_config: JwtConfig,
    pub connections: ConnectionManager,
}

#[derive(Debug, Deserialize)]
pub struct PaginationQuery {
    #[serde(default = "default_limit")]
    pub limit: u64,
    #[serde(default)]
    pub offset: u64,
}

fn default_limit() -> u64 {
    20
}

/// POST /api/calls/initiate
/// POST /api/calls/initiate
pub async fn initiate_call(
    State(state): State<CallState>,
    headers: axum::http::HeaderMap,
    Json(dto): Json<InitiateCallDto>,
) -> Response {
    tracing::info!("=== Initiate call request received ===");
    tracing::info!("DTO: call_type={}, mode={}, participant_ids={:?}, conversation_id={:?}", 
        dto.call_type, dto.mode, dto.participant_ids, dto.conversation_id);
    
    // Extract and verify JWT token
    let token = match extract_token(&headers) {
        Ok(t) => t,
        Err(e) => {
            tracing::error!("Failed to extract token from headers");
            return e;
        }
    };

    let token_payload = match verify_access_token(&token, &state.jwt_config) {
        Ok(payload) => payload,
        Err(e) => {
            tracing::error!("Failed to verify token: {:?}", e);
            return (StatusCode::UNAUTHORIZED, "Invalid or expired token").into_response();
        }
    };

    let user_id = match Uuid::parse_str(&token_payload.sub) {
        Ok(id) => id,
        Err(e) => {
            tracing::error!("Failed to parse user ID: {:?}", e);
            return (StatusCode::BAD_REQUEST, "Invalid user ID").into_response();
        }
    };

    tracing::info!("Authenticated user_id: {}", user_id);

    // Initiate call
    match state.call_service.initiate_call(user_id, dto).await {
        Ok(response) => {
            tracing::info!("Call service returned success, call_id: {}", response.call.id);
            // Send WebSocket notification to all participants
            let call = &response.call;
            
            // Get initiator name from call service
            let initiator_name = match state.call_service.get_user_name(user_id).await {
                Ok(name) => name,
                Err(e) => {
                    tracing::warn!("Failed to get initiator name: {:?}", e);
                    "Unknown".to_string()
                }
            };

            tracing::info!("Initiator name: {}", initiator_name);

            let incoming_call_msg = WsServerMessage::IncomingCall {
                call_id: call.id,
                room_name: call.room_name.clone(),
                call_type: call.call_type.clone(),
                mode: call.mode.clone(),
                initiated_by: user_id,
                initiator_name,
                conversation_id: call.conversation_id,
            };

            // Send to all participants (excluding initiator)
            for participant in &call.participants {
                if participant.user_id != user_id {
                    if let Some(connection) = state.connections.get(&participant.user_id) {
                        let _ = connection.send(incoming_call_msg.clone());
                        tracing::info!("Sent IncomingCall notification to user: {}", participant.user_id);
                    } else {
                        tracing::warn!("User {} not connected via WebSocket", participant.user_id);
                    }
                }
            }

            tracing::info!("=== Call initiated successfully ===");
            (StatusCode::CREATED, Json(response)).into_response()
        }
        Err(e) => {
            tracing::error!("Failed to initiate call: {:?}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response()
        }
    }
}
pub async fn join_call(
    State(state): State<CallState>,
    headers: axum::http::HeaderMap,
    Path(call_id): Path<Uuid>,
) -> Response {
    // Extract and verify JWT token
    let token = match extract_token(&headers) {
        Ok(t) => t,
        Err(e) => return e,
    };

    let token_payload = match verify_access_token(&token, &state.jwt_config) {
        Ok(payload) => payload,
        Err(_) => {
            return (StatusCode::UNAUTHORIZED, "Invalid token").into_response();
        }
    };

    let user_id = match Uuid::parse_str(&token_payload.sub) {
        Ok(id) => id,
        Err(_) => {
            return (StatusCode::BAD_REQUEST, "Invalid user ID").into_response();
        }
    };

    // Join call
    match state.call_service.join_call(user_id, call_id).await {
        Ok(response) => {
            // Get username for notification
            let username = match state.call_service.get_user_name(user_id).await {
                Ok(name) => name,
                Err(_) => "Unknown".to_string(),
            };

            // Notify all participants that someone joined
            let participant_joined_msg = WsServerMessage::ParticipantJoined {
                call_id,
                user_id,
                username,
            };

            // Send to all participants in the call
            for participant in &response.call.participants {
                if let Some(connection) = state.connections.get(&participant.user_id) {
                    let _ = connection.send(participant_joined_msg.clone());
                }
            }

            // Update call status
            let status_msg = WsServerMessage::CallStatusUpdate {
                call_id,
                status: response.call.status.clone(),
            };

            for participant in &response.call.participants {
                if let Some(connection) = state.connections.get(&participant.user_id) {
                    let _ = connection.send(status_msg.clone());
                }
            }

            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            tracing::error!("Failed to join call: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response()
        }
    }
}

/// POST /api/calls/:id/end
pub async fn end_call(
    State(state): State<CallState>,
    headers: axum::http::HeaderMap,
    Path(call_id): Path<Uuid>,
) -> Response {
    // Extract and verify JWT token
    let token = match extract_token(&headers) {
        Ok(t) => t,
        Err(e) => return e,
    };

    let token_payload = match verify_access_token(&token, &state.jwt_config) {
        Ok(payload) => payload,
        Err(_) => {
            return (StatusCode::UNAUTHORIZED, "Invalid token").into_response();
        }
    };

    let user_id = match Uuid::parse_str(&token_payload.sub) {
        Ok(id) => id,
        Err(_) => {
            return (StatusCode::BAD_REQUEST, "Invalid user ID").into_response();
        }
    };

    // Get call details before ending
    let call_before = match state.call_service.get_call(call_id).await {
        Ok(call) => call,
        Err(e) => {
            tracing::error!("Failed to get call: {}", e);
            return (StatusCode::NOT_FOUND, e.to_string()).into_response();
        }
    };

    // End call
    match state.call_service.end_call(user_id, call_id).await {
        Ok((response, message_data)) => {
            // Get username
            let username = match state.call_service.get_user_name(user_id).await {
                Ok(name) => name,
                Err(_) => "Unknown".to_string(),
            };

            // Notify participant left
            let participant_left_msg = WsServerMessage::ParticipantLeft {
                call_id,
                user_id,
                username,
            };

            // Notify call ended
            let call_ended_msg = WsServerMessage::CallEnded {
                call_id,
                ended_by: user_id,
                duration: response.duration,
            };

            // Send to all participants from the original call
            for participant in &call_before.participants {
                if let Some(connection) = state.connections.get(&participant.user_id) {
                    let _ = connection.send(participant_left_msg.clone());
                    let _ = connection.send(call_ended_msg.clone());
                }
            }

            // Broadcast MessageNew if call_log was created
            if let Some((message, conversation_id)) = message_data {
                // Get sender info
                if let Ok((sender_username, sender_display_name)) = state.call_service.get_user_info(message.sender_id).await {
                    let message_dto = MessageDto {
                        id: message.id,
                        conversation_id,
                        sender_id: message.sender_id,
                        sender_username,
                        sender_display_name,
                        reply_to_message_id: message.reply_to_message_id,
                        message_type: MessageType::CallLog,
                        content: message.content,
                        status: MessageStatus::Sent,
                        created_at: message.created_at.to_utc(),
                        updated_at: message.updated_at.to_utc(),
                    };

                    let message_new_msg = WsServerMessage::MessageNew {
                        message: message_dto,
                    };

                    // Broadcast to all participants in the conversation
                    for participant in &call_before.participants {
                        if let Some(connection) = state.connections.get(&participant.user_id) {
                            let _ = connection.send(message_new_msg.clone());
                        }
                    }
                }
            }

            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            tracing::error!("Failed to end call: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response()
        }
    }
}

/// GET /api/calls/history
pub async fn get_call_history(
    State(state): State<CallState>,
    headers: axum::http::HeaderMap,
    Query(query): Query<PaginationQuery>,
) -> Response {
    // Extract and verify JWT token
    let token = match extract_token(&headers) {
        Ok(t) => t,
        Err(e) => return e,
    };

    let token_payload = match verify_access_token(&token, &state.jwt_config) {
        Ok(payload) => payload,
        Err(_) => {
            return (StatusCode::UNAUTHORIZED, "Invalid token").into_response();
        }
    };

    let user_id = match Uuid::parse_str(&token_payload.sub) {
        Ok(id) => id,
        Err(_) => {
            return (StatusCode::BAD_REQUEST, "Invalid user ID").into_response();
        }
    };

    // Get call history
    match state
        .call_service
        .get_call_history(user_id, query.limit, query.offset)
        .await
    {
        Ok(response) => (StatusCode::OK, Json(response)).into_response(),
        Err(e) => {
            tracing::error!("Failed to get call history: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response()
        }
    }
}

/// GET /api/calls/active
pub async fn get_active_calls(
    State(state): State<CallState>,
    headers: axum::http::HeaderMap,
) -> Response {
    // Extract and verify JWT token
    let token = match extract_token(&headers) {
        Ok(t) => t,
        Err(e) => return e,
    };

    let token_payload = match verify_access_token(&token, &state.jwt_config) {
        Ok(payload) => payload,
        Err(_) => {
            return (StatusCode::UNAUTHORIZED, "Invalid token").into_response();
        }
    };

    let user_id = match Uuid::parse_str(&token_payload.sub) {
        Ok(id) => id,
        Err(_) => {
            return (StatusCode::BAD_REQUEST, "Invalid user ID").into_response();
        }
    };

    // Get active calls
    match state.call_service.get_active_calls(user_id).await {
        Ok(response) => (StatusCode::OK, Json(response)).into_response(),
        Err(e) => {
            tracing::error!("Failed to get active calls: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response()
        }
    }
}

/// GET /api/calls/:id
pub async fn get_call(
    State(state): State<CallState>,
    headers: axum::http::HeaderMap,
    Path(call_id): Path<Uuid>,
) -> Response {
    // Extract and verify JWT token
    let token = match extract_token(&headers) {
        Ok(t) => t,
        Err(e) => return e,
    };

    let _token_payload = match verify_access_token(&token, &state.jwt_config) {
        Ok(payload) => payload,
        Err(_) => {
            return (StatusCode::UNAUTHORIZED, "Invalid token").into_response();
        }
    };

    // Get call
    match state.call_service.get_call(call_id).await {
        Ok(response) => (StatusCode::OK, Json(response)).into_response(),
        Err(e) => {
            tracing::error!("Failed to get call: {}", e);
            (StatusCode::NOT_FOUND, e.to_string()).into_response()
        }
    }
}

/// PUT /api/presence
pub async fn update_presence(
    State(state): State<CallState>,
    headers: axum::http::HeaderMap,
    Json(dto): Json<UpdatePresenceDto>,
) -> Response {
    // Extract and verify JWT token
    let token = match extract_token(&headers) {
        Ok(t) => t,
        Err(e) => return e,
    };

    let token_payload = match verify_access_token(&token, &state.jwt_config) {
        Ok(payload) => payload,
        Err(_) => {
            return (StatusCode::UNAUTHORIZED, "Invalid token").into_response();
        }
    };

    let user_id = match Uuid::parse_str(&token_payload.sub) {
        Ok(id) => id,
        Err(_) => {
            return (StatusCode::BAD_REQUEST, "Invalid user ID").into_response();
        }
    };

    // Update presence
    match state.call_service.update_presence(user_id, dto.status.clone()).await {
        Ok(response) => {
            // Broadcast presence update to all connected users
            let presence_msg = WsServerMessage::PresenceUpdate {
                user_id,
                status: dto.status,
            };

            // Send to all connections (can be optimized to send only to friends/contacts)
            for connection in state.connections.iter() {
                let _ = connection.send(presence_msg.clone());
            }

            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            tracing::error!("Failed to update presence: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response()
        }
    }
}

/// GET /api/presence/:user_id
pub async fn get_presence(
    State(state): State<CallState>,
    headers: axum::http::HeaderMap,
    Path(user_id): Path<Uuid>,
) -> Response {
    // Extract and verify JWT token
    let token = match extract_token(&headers) {
        Ok(t) => t,
        Err(e) => return e,
    };

    let _token_payload = match verify_access_token(&token, &state.jwt_config) {
        Ok(payload) => payload,
        Err(_) => {
            return (StatusCode::UNAUTHORIZED, "Invalid token").into_response();
        }
    };

    // Get presence
    match state.call_service.get_presence(user_id).await {
        Ok(response) => (StatusCode::OK, Json(response)).into_response(),
        Err(e) => {
            tracing::error!("Failed to get presence: {}", e);
            (StatusCode::NOT_FOUND, e.to_string()).into_response()
        }
    }
}

// Helper function to extract token from headers
fn extract_token(headers: &axum::http::HeaderMap) -> Result<String, Response> {
    let auth_header = headers
        .get("authorization")
        .and_then(|h| h.to_str().ok())
        .ok_or_else(|| {
            (StatusCode::UNAUTHORIZED, "Missing authorization header").into_response()
        })?;

    if let Some(token) = auth_header.strip_prefix("Bearer ") {
        Ok(token.to_string())
    } else {
        Err((StatusCode::UNAUTHORIZED, "Invalid authorization format").into_response())
    }
}

/// POST /api/calls/:id/reject
pub async fn reject_call(
    State(state): State<CallState>,
    headers: axum::http::HeaderMap,
    Path(call_id): Path<Uuid>,
) -> Response {
    // Extract and verify JWT token
    let token = match extract_token(&headers) {
        Ok(t) => t,
        Err(e) => return e,
    };

    let token_payload = match verify_access_token(&token, &state.jwt_config) {
        Ok(payload) => payload,
        Err(_) => {
            return (StatusCode::UNAUTHORIZED, "Invalid token").into_response();
        }
    };

    let user_id = match Uuid::parse_str(&token_payload.sub) {
        Ok(id) => id,
        Err(_) => {
            return (StatusCode::BAD_REQUEST, "Invalid user ID").into_response();
        }
    };

    // Get call details before rejecting
    let call_before = match state.call_service.get_call(call_id).await {
        Ok(call) => call,
        Err(e) => {
            tracing::error!("Failed to get call: {}", e);
            return (StatusCode::NOT_FOUND, e.to_string()).into_response();
        }
    };

    // Reject call
    match state.call_service.reject_call(user_id, call_id).await {
        Ok((response, message_data)) => {
            // Notify all participants about rejection
            let call_status_msg = WsServerMessage::CallStatusUpdate {
                call_id,
                status: "rejected".to_string(),
            };

            // If call is fully rejected, send CallEnded
            if response.status == "rejected" {
                let call_ended_msg = WsServerMessage::CallEnded {
                    call_id,
                    ended_by: user_id,
                    duration: None,
                };

                for participant in &call_before.participants {
                    if let Some(connection) = state.connections.get(&participant.user_id) {
                        let _ = connection.send(call_status_msg.clone());
                        let _ = connection.send(call_ended_msg.clone());
                    }
                }

                // Broadcast MessageNew if call_log was created
                if let Some((message, conversation_id)) = message_data {
                    if let Ok((sender_username, sender_display_name)) = state.call_service.get_user_info(message.sender_id).await {
                        let message_dto = MessageDto {
                            id: message.id,
                            conversation_id,
                            sender_id: message.sender_id,
                            sender_username,
                            sender_display_name,
                            reply_to_message_id: message.reply_to_message_id,
                            message_type: MessageType::CallLog,
                            content: message.content,
                            status: MessageStatus::Sent,
                            created_at: message.created_at.to_utc(),
                            updated_at: message.updated_at.to_utc(),
                        };

                        let message_new_msg = WsServerMessage::MessageNew {
                            message: message_dto,
                        };

                        for participant in &call_before.participants {
                            if let Some(connection) = state.connections.get(&participant.user_id) {
                                let _ = connection.send(message_new_msg.clone());
                            }
                        }
                    }
                }
            } else {
                // Just notify status update (partial rejection)
                for participant in &call_before.participants {
                    if let Some(connection) = state.connections.get(&participant.user_id) {
                        let _ = connection.send(call_status_msg.clone());
                    }
                }
            }

            tracing::info!("User {} rejected call {}", user_id, call_id);
            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            tracing::error!("Failed to reject call: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response()
        }
    }
}

/// POST /api/calls/:id/cancel
pub async fn cancel_call(
    State(state): State<CallState>,
    headers: axum::http::HeaderMap,
    Path(call_id): Path<Uuid>,
) -> Response {
    // Extract and verify JWT token
    let token = match extract_token(&headers) {
        Ok(t) => t,
        Err(e) => return e,
    };

    let token_payload = match verify_access_token(&token, &state.jwt_config) {
        Ok(payload) => payload,
        Err(_) => {
            return (StatusCode::UNAUTHORIZED, "Invalid token").into_response();
        }
    };

    let user_id = match Uuid::parse_str(&token_payload.sub) {
        Ok(id) => id,
        Err(_) => {
            return (StatusCode::BAD_REQUEST, "Invalid user ID").into_response();
        }
    };

    // Get call details before canceling
    let call_before = match state.call_service.get_call(call_id).await {
        Ok(call) => call,
        Err(e) => {
            tracing::error!("Failed to get call: {}", e);
            return (StatusCode::NOT_FOUND, e.to_string()).into_response();
        }
    };

    // Cancel call
    match state.call_service.cancel_call(user_id, call_id).await {
        Ok((response, message_data)) => {
            // Notify all participants that call was cancelled/missed
            let call_ended_msg = WsServerMessage::CallEnded {
                call_id,
                ended_by: user_id,
                duration: None,
            };

            let call_status_msg = WsServerMessage::CallStatusUpdate {
                call_id,
                status: "missed".to_string(),
            };

            for participant in &call_before.participants {
                if let Some(connection) = state.connections.get(&participant.user_id) {
                    let _ = connection.send(call_status_msg.clone());
                    let _ = connection.send(call_ended_msg.clone());
                }
            }

            // Broadcast MessageNew if call_log was created
            if let Some((message, conversation_id)) = message_data {
                if let Ok((sender_username, sender_display_name)) = state.call_service.get_user_info(message.sender_id).await {
                    let message_dto = MessageDto {
                        id: message.id,
                        conversation_id,
                        sender_id: message.sender_id,
                        sender_username,
                        sender_display_name,
                        reply_to_message_id: message.reply_to_message_id,
                        message_type: MessageType::CallLog,
                        content: message.content,
                        status: MessageStatus::Sent,
                        created_at: message.created_at.to_utc(),
                        updated_at: message.updated_at.to_utc(),
                    };

                    let message_new_msg = WsServerMessage::MessageNew {
                        message: message_dto,
                    };

                    for participant in &call_before.participants {
                        if let Some(connection) = state.connections.get(&participant.user_id) {
                            let _ = connection.send(message_new_msg.clone());
                        }
                    }
                }
            }

            tracing::info!("User {} cancelled call {}", user_id, call_id);
            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            tracing::error!("Failed to cancel call: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()).into_response()
        }
    }
}
