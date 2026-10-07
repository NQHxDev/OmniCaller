use crate::dtos::message_dtos::{
   ConversationDto, ConversationUserDto, ConversationsResponse, CreateDirectConversationDto,
   MessageDto, MessagesResponse, SendMessageDto,
};
use crate::repositories::conversation_repository::ConversationRepository;
use crate::repositories::message_repository::MessageRepository;
use crate::repositories::user_repository::UserRepository;
use anyhow::{Context, Result};
use uuid::Uuid;

#[derive(Clone)]
pub struct MessageService {
   conversation_repo: ConversationRepository,
   message_repo: MessageRepository,
   user_repo: UserRepository,
}

impl MessageService {
   pub fn new(
      conversation_repo: ConversationRepository,
      message_repo: MessageRepository,
      user_repo: UserRepository,
   ) -> Self {
      Self {
         conversation_repo,
         message_repo,
         user_repo,
      }
   }

   // Expose repositories for WebSocket handler
   pub fn conversation_repo(&self) -> &ConversationRepository {
      &self.conversation_repo
   }

   pub fn message_repo(&self) -> &MessageRepository {
      &self.message_repo
   }

   pub fn user_repo(&self) -> &UserRepository {
      &self.user_repo
   }

   /// Find or create direct conversation with another user
   pub async fn find_or_create_direct_conversation(
      &self,
      current_user_id: &Uuid,
      dto: CreateDirectConversationDto,
   ) -> Result<ConversationDto> {
      // Find friend user by username
      let (friend_user, friend_account) = self
         .user_repo
         .find_by_username(&dto.friend_username)
         .await
         .context("Failed to query user")?
         .ok_or_else(|| anyhow::anyhow!("User not found"))?;

      // Cannot create conversation with yourself
      if friend_user.id == *current_user_id {
         anyhow::bail!("Cannot create conversation with yourself");
      }

      // Try to find existing conversation
      let conversation = if let Some(existing) = self
         .conversation_repo
         .find_direct_conversation(current_user_id, &friend_user.id)
         .await?
      {
         existing
      } else {
         // Create new conversation
         self
            .conversation_repo
            .create_direct_conversation(current_user_id, &friend_user.id)
            .await?
      };

      // Get last message
      let last_message = if let Some((msg, sender_user, sender_account)) =
         self.message_repo.get_last_message(&conversation.id).await?
      {
         Some(MessageDto {
            id: msg.id,
            conversation_id: msg.conversation_id,
            sender_id: msg.sender_id,
            sender_username: sender_account.username,
            sender_display_name: sender_user.display_name,
            reply_to_message_id: msg.reply_to_message_id,
            message_type: msg.message_type,
            content: msg.content,
            status: msg.status,
            created_at: msg.created_at.into(),
            updated_at: msg.updated_at.into(),
         })
      } else {
         None
      };

      // Get unread count
      let unread_count = self
         .conversation_repo
         .get_unread_count(&conversation.id, current_user_id)
         .await?;

      Ok(ConversationDto {
         id: conversation.id,
         r#type: conversation.r#type,
         title: conversation.title,
         avatar_url: conversation.avatar_url,
         other_user: Some(ConversationUserDto {
            user_id: friend_user.id,
            username: friend_account.username,
            display_name: friend_user.display_name,
         }),
         last_message,
         unread_count,
         created_at: conversation.created_at.into(),
         updated_at: conversation.updated_at.into(),
      })
   }

   /// Send a text message
   pub async fn send_message(&self, sender_id: &Uuid, dto: SendMessageDto) -> Result<MessageDto> {
      // Check if user is member of conversation
      let is_member = self.conversation_repo.is_member(&dto.conversation_id, sender_id).await?;

      if !is_member {
         anyhow::bail!("User is not a member of this conversation");
      }

      // Create message
      let message = self
         .message_repo
         .create_message(
            &dto.conversation_id,
            sender_id,
            &dto.content,
            dto.reply_to_message_id.as_ref(),
         )
         .await?;

      // Update sender last read message ID
      let _ = self
         .conversation_repo
         .update_last_read(&dto.conversation_id, sender_id, &message.id)
         .await;

      // Get message with sender info
      let (_, sender_user, sender_account) = self
         .message_repo
         .find_by_id(&message.id)
         .await?
         .ok_or_else(|| anyhow::anyhow!("Message not found after creation"))?;

      Ok(MessageDto {
         id: message.id,
         conversation_id: message.conversation_id,
         sender_id: message.sender_id,
         sender_username: sender_account.username,
         sender_display_name: sender_user.display_name,
         reply_to_message_id: message.reply_to_message_id,
         message_type: message.message_type,
         content: message.content,
         status: message.status,
         created_at: message.created_at.into(),
         updated_at: message.updated_at.into(),
      })
   }

   /// Get messages with cursor-based pagination
   pub async fn get_messages(
      &self,
      current_user_id: &Uuid,
      conversation_id: &Uuid,
      cursor: Option<Uuid>,
      limit: Option<u64>,
   ) -> Result<MessagesResponse> {
      // Check if user is member of conversation
      let is_member = self.conversation_repo.is_member(conversation_id, current_user_id).await?;

      if !is_member {
         anyhow::bail!("User is not a member of this conversation");
      }

      let limit = limit.unwrap_or(30);

      let (messages, has_more) =
         self.message_repo.get_messages(conversation_id, cursor.as_ref(), limit).await?;

      let message_dtos: Vec<MessageDto> = messages
         .into_iter()
         .map(|(msg, user, account)| MessageDto {
            id: msg.id,
            conversation_id: msg.conversation_id,
            sender_id: msg.sender_id,
            sender_username: account.username,
            sender_display_name: user.display_name,
            reply_to_message_id: msg.reply_to_message_id,
            message_type: msg.message_type,
            content: msg.content,
            status: msg.status,
            created_at: msg.created_at.into(),
            updated_at: msg.updated_at.into(),
         })
         .collect();

      let next_cursor = if has_more {
         message_dtos.last().map(|m| m.id)
      } else {
         None
      };

      Ok(MessagesResponse {
         messages: message_dtos,
         next_cursor,
         has_more,
      })
   }

   /// Get all conversations for a user
   pub async fn get_conversations(&self, user_id: &Uuid) -> Result<ConversationsResponse> {
      let conversations = self.conversation_repo.get_user_conversations(user_id).await?;

      let mut conversation_dtos = Vec::new();

      for (conv, other_user, other_account) in conversations {
         // Get last message
         let last_message = if let Some((msg, sender_user, sender_account)) =
            self.message_repo.get_last_message(&conv.id).await?
         {
            Some(MessageDto {
               id: msg.id,
               conversation_id: msg.conversation_id,
               sender_id: msg.sender_id,
               sender_username: sender_account.username,
               sender_display_name: sender_user.display_name,
               reply_to_message_id: msg.reply_to_message_id,
               message_type: msg.message_type,
               content: msg.content,
               status: msg.status,
               created_at: msg.created_at.into(),
               updated_at: msg.updated_at.into(),
            })
         } else {
            None
         };

         // Get unread count
         let unread_count = self.conversation_repo.get_unread_count(&conv.id, user_id).await?;

         conversation_dtos.push(ConversationDto {
            id: conv.id,
            r#type: conv.r#type,
            title: conv.title.clone(),
            avatar_url: conv.avatar_url.clone(),
            other_user: if let (Some(user), Some(account)) = (other_user, other_account) {
               Some(ConversationUserDto {
                  user_id: user.id,
                  username: account.username,
                  display_name: user.display_name,
               })
            } else {
               None
            },
            last_message,
            unread_count,
            created_at: conv.created_at.into(),
            updated_at: conv.updated_at.into(),
         });
      }

      let total = conversation_dtos.len();

      Ok(ConversationsResponse { conversations: conversation_dtos, total })
   }

   /// Update message status (for delivered/read receipts)
   pub async fn update_message_status(
      &self,
      message_id: &Uuid,
      status: crate::entities::message::MessageStatus,
   ) -> Result<()> {
      self.message_repo.update_status(message_id, status).await?;
      Ok(())
   }

   /// Mark conversation as read (update last_read_message_id)
   pub async fn mark_as_read(
      &self,
      conversation_id: &Uuid,
      user_id: &Uuid,
      message_id: &Uuid,
   ) -> Result<()> {
      self
         .conversation_repo
         .update_last_read(conversation_id, user_id, message_id)
         .await?;
      Ok(())
   }
}
