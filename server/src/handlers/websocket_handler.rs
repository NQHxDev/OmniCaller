use crate::dtos::message_dtos::{SendMessageDto, WsClientMessage, WsServerMessage};
use crate::entities::message::MessageStatus;
use crate::services::message_service::MessageService;
use crate::utils::jwt::{verify_access_token, JwtConfig};
use axum::{
   extract::{
      ws::{Message, WebSocket, WebSocketUpgrade},
      Query, State,
   },
   response::Response,
};
use dashmap::DashMap;
use futures::{sink::SinkExt, stream::StreamExt};
use sea_orm::EntityTrait;
use serde::Deserialize;
use std::sync::Arc;
use tokio::sync::broadcast;
use uuid::Uuid;

// Global connection manager
pub type ConnectionManager = Arc<DashMap<Uuid, broadcast::Sender<WsServerMessage>>>;

#[derive(Clone)]
pub struct WebSocketState {
   pub jwt_config: JwtConfig,
   pub message_service: MessageService,
   pub connections: ConnectionManager,
}

#[derive(Debug, Deserialize)]
pub struct WsQuery {
   pub token: String,
}

/// WebSocket handler
pub async fn websocket_handler(
   ws: WebSocketUpgrade,
   Query(query): Query<WsQuery>,
   State(state): State<WebSocketState>,
) -> Response {
   // Verify JWT token
   let token_payload = match verify_access_token(&query.token, &state.jwt_config) {
      Ok(payload) => payload,
      Err(_) => {
         return Response::builder().status(401).body("Unauthorized".into()).unwrap();
      }
   };

   let user_id = match Uuid::parse_str(&token_payload.sub) {
      Ok(id) => id,
      Err(_) => {
         return Response::builder().status(400).body("Invalid user ID".into()).unwrap();
      }
   };

   // Upgrade to WebSocket
   ws.on_upgrade(move |socket| handle_socket(socket, user_id, state))
}

async fn handle_socket(socket: WebSocket, user_id: Uuid, state: WebSocketState) {
   let (mut sender, mut receiver) = socket.split();

   // Create broadcast channel for this user
   let (tx, mut rx) = broadcast::channel::<WsServerMessage>(100);
   state.connections.insert(user_id, tx.clone());

   tracing::info!("WebSocket connected: user_id={}", user_id);

   // Send connected message
   let connected_msg = WsServerMessage::Connected { user_id };
   if let Ok(json) = serde_json::to_string(&connected_msg) {
      let _ = sender.send(Message::Text(json)).await;
   }

   // Spawn task to forward broadcast messages to WebSocket
   let mut send_task = tokio::spawn(async move {
      while let Ok(msg) = rx.recv().await {
         if let Ok(json) = serde_json::to_string(&msg) {
            if sender.send(Message::Text(json)).await.is_err() {
               break;
            }
         }
      }
   });

   // Handle incoming messages
   let state_clone = state.clone();
   let mut recv_task = tokio::spawn(async move {
      while let Some(Ok(msg)) = receiver.next().await {
         if let Message::Text(text) = msg {
            if let Err(e) = handle_client_message(&text, user_id, &state_clone).await {
               tracing::error!("Error handling message: {}", e);

               let error_msg = WsServerMessage::Error { message: e.to_string() };

               if let Some(tx) = state_clone.connections.get(&user_id) {
                  let _ = tx.send(error_msg);
               }
            }
         } else if let Message::Close(_) = msg {
            break;
         }
      }
   });

   // Wait for either task to finish
   tokio::select! {
       _ = (&mut send_task) => recv_task.abort(),
       _ = (&mut recv_task) => send_task.abort(),
   }

   // Cleanup
   state.connections.remove(&user_id);
   tracing::info!("WebSocket disconnected: user_id={}", user_id);
}

async fn handle_client_message(
   text: &str,
   user_id: Uuid,
   state: &WebSocketState,
) -> anyhow::Result<()> {
   let client_msg: WsClientMessage = serde_json::from_str(text)?;

   match client_msg {
      WsClientMessage::SendMessage {
         conversation_id,
         content,
         reply_to_message_id,
      } => {
         // Send message via service
         let dto = SendMessageDto {
            conversation_id,
            content: content.trim().to_string(),
            reply_to_message_id,
         };

         let message = state.message_service.send_message(&user_id, dto).await?;

         // Get conversation members
         let members =
            state.message_service.conversation_repo().get_members(&conversation_id).await?;

         // Broadcast to all members
         let server_msg = WsServerMessage::MessageNew { message: message.clone() };

         for member in members {
            if let Some(tx) = state.connections.get(&member.user_id) {
               let _ = tx.send(server_msg.clone());
            }
         }
      }

      WsClientMessage::TypingStart { conversation_id } => {
         // Get user info
         let user_repo = state.message_service.user_repo();
         if let Some(user) = user_repo.find_by_id(&user_id).await? {
            // Get account info
            let account = crate::entities::account::Entity::find_by_id(user.account_id)
               .one(user_repo.db())
               .await?;

            if let Some(account) = account {
               // Broadcast to other members
               let members =
                  state.message_service.conversation_repo().get_members(&conversation_id).await?;

               let server_msg = WsServerMessage::TypingStart {
                  conversation_id,
                  user_id,
                  username: account.username,
               };

               for member in members {
                  if member.user_id != user_id {
                     if let Some(tx) = state.connections.get(&member.user_id) {
                        let _ = tx.send(server_msg.clone());
                     }
                  }
               }
            }
         }
      }

      WsClientMessage::TypingStop { conversation_id } => {
         // Broadcast to other members
         let members =
            state.message_service.conversation_repo().get_members(&conversation_id).await?;

         let server_msg = WsServerMessage::TypingStop { conversation_id, user_id };

         for member in members {
            if member.user_id != user_id {
               if let Some(tx) = state.connections.get(&member.user_id) {
                  let _ = tx.send(server_msg.clone());
               }
            }
         }
      }

      WsClientMessage::MessageDelivered { message_id } => {
         // Update message status
         state
            .message_service
            .update_message_status(&message_id, MessageStatus::Delivered)
            .await?;

         // Get message to find sender
         if let Some((msg, _, _)) =
            state.message_service.message_repo().find_by_id(&message_id).await?
         {
            // Notify sender
            let server_msg = WsServerMessage::MessageStatus {
               message_id,
               status: MessageStatus::Delivered,
            };

            if let Some(tx) = state.connections.get(&msg.sender_id) {
               let _ = tx.send(server_msg);
            }
         }
      }

      WsClientMessage::MessageRead { message_id } => {
         // Update message status
         state
            .message_service
            .update_message_status(&message_id, MessageStatus::Read)
            .await?;

         // Get message to find sender and conversation
         if let Some((msg, _, _)) =
            state.message_service.message_repo().find_by_id(&message_id).await?
         {
            // Update last_read for this user
            state
               .message_service
               .mark_as_read(&msg.conversation_id, &user_id, &message_id)
               .await?;

            // Notify sender
            let server_msg =
               WsServerMessage::MessageStatus { message_id, status: MessageStatus::Read };

            if let Some(tx) = state.connections.get(&msg.sender_id) {
               let _ = tx.send(server_msg);
            }
         }
      }
   }

   Ok(())
}
