use crate::entities::account::{self, Entity as Account};
use crate::entities::message::{self, Entity as Message, MessageStatus, MessageType};
use crate::entities::user::{self, Entity as User};
use anyhow::Result;
use sea_orm::*;
use uuid::Uuid;

#[derive(Clone)]
pub struct MessageRepository {
   db: DatabaseConnection,
}

impl MessageRepository {
   pub fn new(db: DatabaseConnection) -> Self {
      Self { db }
   }

   /// Create a new text message
   pub async fn create_message(
      &self,
      conversation_id: &Uuid,
      sender_id: &Uuid,
      content: &str,
      reply_to_message_id: Option<&Uuid>,
   ) -> Result<message::Model> {
      let now = chrono::Utc::now().into();
      let message_id = Uuid::now_v7(); // UUIDv7 for time-ordered sorting

      let message = message::ActiveModel {
         id: Set(message_id),
         conversation_id: Set(*conversation_id),
         sender_id: Set(*sender_id),
         reply_to_message_id: Set(reply_to_message_id.copied()),
         message_type: Set(MessageType::Text),
         content: Set(Some(content.to_string())),
         status: Set(MessageStatus::Sent),
         created_at: Set(now),
         updated_at: Set(now),
         deleted_at: Set(None),
      };

      let created = message.insert(&self.db).await?;
      Ok(created)
   }

   /// Get messages with cursor-based pagination (newest to oldest)
   pub async fn get_messages(
      &self,
      conversation_id: &Uuid,
      cursor: Option<&Uuid>,
      limit: u64,
   ) -> Result<(Vec<(message::Model, user::Model, account::Model)>, bool)> {
      let mut query = Message::find()
         .filter(message::Column::ConversationId.eq(*conversation_id))
         .filter(message::Column::DeletedAt.is_null())
         .order_by_desc(message::Column::Id); // DESC for newest first

      // Apply cursor if provided
      if let Some(cursor_id) = cursor {
         query = query.filter(message::Column::Id.lt(*cursor_id));
      }

      // Fetch limit + 1 to check if there are more
      let messages = query.limit(limit + 1).all(&self.db).await?;

      let has_more = messages.len() > limit as usize;
      let messages = if has_more {
         messages.into_iter().take(limit as usize).collect()
      } else {
         messages
      };

      // Fetch sender info for each message
      let mut results = Vec::new();
      for msg in messages {
         if let Some(user) = User::find_by_id(msg.sender_id)
            .filter(user::Column::DeletedAt.is_null())
            .one(&self.db)
            .await?
         {
            if let Some(account) = Account::find()
               .filter(account::Column::Id.eq(user.account_id))
               .filter(account::Column::DeletedAt.is_null())
               .one(&self.db)
               .await?
            {
               results.push((msg, user, account));
            }
         }
      }

      Ok((results, has_more))
   }

   /// Get a single message by ID
   pub async fn find_by_id(
      &self,
      message_id: &Uuid,
   ) -> Result<Option<(message::Model, user::Model, account::Model)>> {
      if let Some(msg) = Message::find_by_id(*message_id)
         .filter(message::Column::DeletedAt.is_null())
         .one(&self.db)
         .await?
      {
         if let Some(user) = User::find_by_id(msg.sender_id)
            .filter(user::Column::DeletedAt.is_null())
            .one(&self.db)
            .await?
         {
            if let Some(account) = Account::find()
               .filter(account::Column::Id.eq(user.account_id))
               .filter(account::Column::DeletedAt.is_null())
               .one(&self.db)
               .await?
            {
               return Ok(Some((msg, user, account)));
            }
         }
      }

      Ok(None)
   }

   /// Update message status (delivered/read)
   pub async fn update_status(&self, message_id: &Uuid, status: MessageStatus) -> Result<()> {
      Message::update_many()
         .col_expr(message::Column::Status, sea_orm::sea_query::Expr::value(status))
         .col_expr(message::Column::UpdatedAt, sea_orm::sea_query::Expr::value(chrono::Utc::now()))
         .filter(message::Column::Id.eq(*message_id))
         .exec(&self.db)
         .await?;

      Ok(())
   }

   /// Get last message of a conversation
   pub async fn get_last_message(
      &self,
      conversation_id: &Uuid,
   ) -> Result<Option<(message::Model, user::Model, account::Model)>> {
      if let Some(msg) = Message::find()
         .filter(message::Column::ConversationId.eq(*conversation_id))
         .filter(message::Column::DeletedAt.is_null())
         .order_by_desc(message::Column::Id)
         .one(&self.db)
         .await?
      {
         if let Some(user) = User::find_by_id(msg.sender_id)
            .filter(user::Column::DeletedAt.is_null())
            .one(&self.db)
            .await?
         {
            if let Some(account) = Account::find()
               .filter(account::Column::Id.eq(user.account_id))
               .filter(account::Column::DeletedAt.is_null())
               .one(&self.db)
               .await?
            {
               return Ok(Some((msg, user, account)));
            }
         }
      }

      Ok(None)
   }

   /// Delete a message (soft delete)
   pub async fn delete_message(&self, message_id: &Uuid) -> Result<()> {
      Message::update_many()
         .col_expr(message::Column::DeletedAt, sea_orm::sea_query::Expr::value(chrono::Utc::now()))
         .filter(message::Column::Id.eq(*message_id))
         .exec(&self.db)
         .await?;

      Ok(())
   }
}
