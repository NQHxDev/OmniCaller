use crate::dtos::message_dtos::{
   ConversationDto, ConversationsResponse, CreateDirectConversationDto, GetMessagesQuery,
   MessageDto, MessagesResponse, SendMessageDto,
};
use crate::middlewares::auth_middleware::AuthUser;
use crate::services::message_service::MessageService;
use axum::{
   extract::{Path, Query, State},
   http::StatusCode,
   Json,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

#[derive(Clone)]
pub struct MessageHandler {
   message_service: MessageService,
}

#[derive(Debug, Serialize)]
pub struct ApiResponse<T> {
   pub success: bool,
   pub data: Option<T>,
   pub error: Option<String>,
}

impl MessageHandler {
   pub fn new(message_service: MessageService) -> Self {
      Self { message_service }
   }

   /// POST /api/conversations/direct - Find or create direct conversation
   pub async fn create_direct_conversation(
      auth_user: AuthUser,
      State(handler): State<MessageHandler>,
      Json(dto): Json<CreateDirectConversationDto>,
   ) -> Result<Json<ApiResponse<ConversationDto>>, (StatusCode, Json<ApiResponse<()>>)> {
      let user_id = Uuid::parse_str(&auth_user.user_id).map_err(|e| {
         (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse {
               success: false,
               data: None,
               error: Some(format!("Invalid user ID: {}", e)),
            }),
         )
      })?;

      match handler.message_service.find_or_create_direct_conversation(&user_id, dto).await {
         Ok(conversation) => Ok(Json(ApiResponse {
            success: true,
            data: Some(conversation),
            error: None,
         })),
         Err(e) => {
            let error_msg = e.to_string();
            let status = if error_msg.contains("not found") {
               StatusCode::NOT_FOUND
            } else if error_msg.contains("yourself") {
               StatusCode::BAD_REQUEST
            } else {
               StatusCode::INTERNAL_SERVER_ERROR
            };

            Err((
               status,
               Json(ApiResponse {
                  success: false,
                  data: None,
                  error: Some(error_msg),
               }),
            ))
         }
      }
   }

   /// POST /api/messages - Send a message
   pub async fn send_message(
      auth_user: AuthUser,
      State(handler): State<MessageHandler>,
      Json(mut dto): Json<SendMessageDto>,
   ) -> Result<Json<ApiResponse<MessageDto>>, (StatusCode, Json<ApiResponse<()>>)> {
      // Validate
      if let Err(validation_errors) = dto.validate() {
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
            Json(ApiResponse {
               success: false,
               data: None,
               error: Some(error_message),
            }),
         ));
      }

      let user_id = Uuid::parse_str(&auth_user.user_id).map_err(|e| {
         (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse {
               success: false,
               data: None,
               error: Some(format!("Invalid user ID: {}", e)),
            }),
         )
      })?;

      // Trim content
      dto.content = dto.content.trim().to_string();

      match handler.message_service.send_message(&user_id, dto).await {
         Ok(message) => Ok(Json(ApiResponse {
            success: true,
            data: Some(message),
            error: None,
         })),
         Err(e) => {
            let error_msg = e.to_string();
            let status = if error_msg.contains("not a member") {
               StatusCode::FORBIDDEN
            } else {
               StatusCode::INTERNAL_SERVER_ERROR
            };

            Err((
               status,
               Json(ApiResponse {
                  success: false,
                  data: None,
                  error: Some(error_msg),
               }),
            ))
         }
      }
   }

   /// GET /api/conversations - Get all conversations
   pub async fn get_conversations(
      auth_user: AuthUser,
      State(handler): State<MessageHandler>,
   ) -> Result<Json<ApiResponse<ConversationsResponse>>, (StatusCode, Json<ApiResponse<()>>)> {
      let user_id = Uuid::parse_str(&auth_user.user_id).map_err(|e| {
         (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse {
               success: false,
               data: None,
               error: Some(format!("Invalid user ID: {}", e)),
            }),
         )
      })?;

      match handler.message_service.get_conversations(&user_id).await {
         Ok(response) => Ok(Json(ApiResponse {
            success: true,
            data: Some(response),
            error: None,
         })),
         Err(e) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiResponse {
               success: false,
               data: None,
               error: Some(e.to_string()),
            }),
         )),
      }
   }

   /// GET /api/conversations/:id/messages - Get messages with pagination
   pub async fn get_messages(
      auth_user: AuthUser,
      State(handler): State<MessageHandler>,
      Path(conversation_id): Path<Uuid>,
      Query(query): Query<GetMessagesQuery>,
   ) -> Result<Json<ApiResponse<MessagesResponse>>, (StatusCode, Json<ApiResponse<()>>)> {
      let user_id = Uuid::parse_str(&auth_user.user_id).map_err(|e| {
         (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse {
               success: false,
               data: None,
               error: Some(format!("Invalid user ID: {}", e)),
            }),
         )
      })?;

      match handler
         .message_service
         .get_messages(&user_id, &conversation_id, query.cursor, query.limit)
         .await
      {
         Ok(response) => Ok(Json(ApiResponse {
            success: true,
            data: Some(response),
            error: None,
         })),
         Err(e) => {
            let error_msg = e.to_string();
            let status = if error_msg.contains("not a member") {
               StatusCode::FORBIDDEN
            } else {
               StatusCode::INTERNAL_SERVER_ERROR
            };

            Err((
               status,
               Json(ApiResponse {
                  success: false,
                  data: None,
                  error: Some(error_msg),
               }),
            ))
         }
      }
   }
}
