use crate::entities::account::{self, Entity as Account};
use crate::entities::conversation::{self, ConversationType, Entity as Conversation};
use crate::entities::conversation_member::{self, Entity as ConversationMember, MemberRole};
use crate::entities::user::{self, Entity as User};
use anyhow::Result;
use sea_orm::*;
use uuid::Uuid;

#[derive(Clone)]
pub struct ConversationRepository {
   db: DatabaseConnection,
}

impl ConversationRepository {
   pub fn new(db: DatabaseConnection) -> Self {
      Self { db }
   }

   /// Find existing direct conversation between two users
   pub async fn find_direct_conversation(
      &self,
      user_id1: &Uuid,
      user_id2: &Uuid,
   ) -> Result<Option<conversation::Model>> {
      // Find conversations where both users are members
      let conv = Conversation::find()
         .filter(conversation::Column::Type.eq(ConversationType::Direct))
         .filter(conversation::Column::DeletedAt.is_null())
         .inner_join(ConversationMember)
         .filter(
            Condition::any()
               .add(conversation_member::Column::UserId.eq(*user_id1))
               .add(conversation_member::Column::UserId.eq(*user_id2)),
         )
         .group_by(conversation::Column::Id)
         .having(sea_orm::sea_query::Expr::cust(
            "COUNT(DISTINCT conversation_member.user_id) = 2",
         ))
         .one(&self.db)
         .await?;

      Ok(conv)
   }

   /// Create a new direct conversation between two users
   pub async fn create_direct_conversation(
      &self,
      creator_id: &Uuid,
      friend_id: &Uuid,
   ) -> Result<conversation::Model> {
      let now = chrono::Utc::now().into();
      let conversation_id = Uuid::now_v7();

      // Create conversation
      let conversation = conversation::ActiveModel {
         id: Set(conversation_id),
         r#type: Set(ConversationType::Direct),
         title: Set(None),
         avatar_url: Set(None),
         description: Set(None),
         banner_url: Set(None),
         pinned_message_id: Set(None),
         created_by: Set(*creator_id),
         created_at: Set(now),
         updated_at: Set(now),
         deleted_at: Set(None),
      };

      let created_conv = conversation.insert(&self.db).await?;

      // Add both users as members
      let member1 = conversation_member::ActiveModel {
         id: Set(Uuid::now_v7()),
         conversation_id: Set(conversation_id),
         user_id: Set(*creator_id),
         role: Set(MemberRole::Member),
         last_read_message_id: Set(None),
         joined_at: Set(now),
         left_at: Set(None),
      };

      let member2 = conversation_member::ActiveModel {
         id: Set(Uuid::now_v7()),
         conversation_id: Set(conversation_id),
         user_id: Set(*friend_id),
         role: Set(MemberRole::Member),
         last_read_message_id: Set(None),
         joined_at: Set(now),
         left_at: Set(None),
      };

      member1.insert(&self.db).await?;
      member2.insert(&self.db).await?;

      Ok(created_conv)
   }

   /// Get all conversations for a user with last message and unread count
   pub async fn get_user_conversations(
      &self,
      user_id: &Uuid,
   ) -> Result<Vec<(conversation::Model, Option<user::Model>, Option<account::Model>)>> {
      // Get all conversation IDs where user is a member
      let member_convs = ConversationMember::find()
         .filter(conversation_member::Column::UserId.eq(*user_id))
         .filter(conversation_member::Column::LeftAt.is_null())
         .all(&self.db)
         .await?;

      let mut results = Vec::new();

      for member in member_convs {
         if let Some(conv) = Conversation::find_by_id(member.conversation_id)
            .filter(conversation::Column::DeletedAt.is_null())
            .one(&self.db)
            .await?
         {
            // For direct conversations, find the other user
            let mut other_user = None;
            let mut other_account = None;

            if conv.is_direct() {
               // Find the other member
               if let Some(other_member) = ConversationMember::find()
                  .filter(conversation_member::Column::ConversationId.eq(conv.id))
                  .filter(conversation_member::Column::UserId.ne(*user_id))
                  .one(&self.db)
                  .await?
               {
                  other_user = User::find_by_id(other_member.user_id)
                     .filter(user::Column::DeletedAt.is_null())
                     .one(&self.db)
                     .await?;

                  if let Some(ref u) = other_user {
                     other_account = Account::find()
                        .filter(account::Column::Id.eq(u.account_id))
                        .filter(account::Column::DeletedAt.is_null())
                        .one(&self.db)
                        .await?;
                  }
               }
            }

            results.push((conv, other_user, other_account));
         }
      }

      Ok(results)
   }

   /// Get conversation by ID
   pub async fn find_by_id(&self, conversation_id: &Uuid) -> Result<Option<conversation::Model>> {
      let conv = Conversation::find_by_id(*conversation_id)
         .filter(conversation::Column::DeletedAt.is_null())
         .one(&self.db)
         .await?;

      Ok(conv)
   }

   /// Check if user is member of conversation
   pub async fn is_member(&self, conversation_id: &Uuid, user_id: &Uuid) -> Result<bool> {
      let member = ConversationMember::find()
         .filter(conversation_member::Column::ConversationId.eq(*conversation_id))
         .filter(conversation_member::Column::UserId.eq(*user_id))
         .filter(conversation_member::Column::LeftAt.is_null())
         .one(&self.db)
         .await?;

      Ok(member.is_some())
   }

   /// Get all members of a conversation
   pub async fn get_members(
      &self,
      conversation_id: &Uuid,
   ) -> Result<Vec<conversation_member::Model>> {
      let members = ConversationMember::find()
         .filter(conversation_member::Column::ConversationId.eq(*conversation_id))
         .filter(conversation_member::Column::LeftAt.is_null())
         .all(&self.db)
         .await?;

      Ok(members)
   }

   /// Update last read message for a user in a conversation
   pub async fn update_last_read(
      &self,
      conversation_id: &Uuid,
      user_id: &Uuid,
      message_id: &Uuid,
   ) -> Result<()> {
      ConversationMember::update_many()
         .col_expr(
            conversation_member::Column::LastReadMessageId,
            sea_orm::sea_query::Expr::value(*message_id),
         )
         .filter(conversation_member::Column::ConversationId.eq(*conversation_id))
         .filter(conversation_member::Column::UserId.eq(*user_id))
         .exec(&self.db)
         .await?;

      Ok(())
   }

   /// Get unread count for a conversation
   pub async fn get_unread_count(&self, conversation_id: &Uuid, user_id: &Uuid) -> Result<u64> {
      // Get last read message ID
      let member = ConversationMember::find()
         .filter(conversation_member::Column::ConversationId.eq(*conversation_id))
         .filter(conversation_member::Column::UserId.eq(*user_id))
         .one(&self.db)
         .await?;

      if let Some(member) = member {
         if let Some(last_read_id) = member.last_read_message_id {
            // Count messages after last read, excluding messages sent by the user
            let count = crate::entities::message::Entity::find()
               .filter(crate::entities::message::Column::ConversationId.eq(*conversation_id))
               .filter(crate::entities::message::Column::SenderId.ne(*user_id))
               .filter(crate::entities::message::Column::Id.gt(last_read_id))
               .filter(crate::entities::message::Column::DeletedAt.is_null())
               .count(&self.db)
               .await?;

            return Ok(count);
         } else {
            // No last read, count all messages not sent by the user
            let count = crate::entities::message::Entity::find()
               .filter(crate::entities::message::Column::ConversationId.eq(*conversation_id))
               .filter(crate::entities::message::Column::SenderId.ne(*user_id))
               .filter(crate::entities::message::Column::DeletedAt.is_null())
               .count(&self.db)
               .await?;

            return Ok(count);
         }
      }

      Ok(0)
   }

   /// Create a new group conversation
   pub async fn create_group_conversation(
      &self,
      creator_id: &Uuid,
      title: String,
      description: Option<String>,
      avatar_url: Option<String>,
      banner_url: Option<String>,
      member_ids: Vec<Uuid>,
   ) -> Result<conversation::Model> {
      let now = chrono::Utc::now().into();
      let conversation_id = Uuid::now_v7();

      // Create group conversation
      let conversation = conversation::ActiveModel {
         id: Set(conversation_id),
         r#type: Set(ConversationType::Group),
         title: Set(Some(title)),
         avatar_url: Set(avatar_url),
         description: Set(description),
         banner_url: Set(banner_url),
         pinned_message_id: Set(None),
         created_by: Set(*creator_id),
         created_at: Set(now),
         updated_at: Set(now),
         deleted_at: Set(None),
      };

      let created_conv = conversation.insert(&self.db).await?;

      // Add creator as owner
      let creator_member = conversation_member::ActiveModel {
         id: Set(Uuid::now_v7()),
         conversation_id: Set(conversation_id),
         user_id: Set(*creator_id),
         role: Set(MemberRole::Owner),
         last_read_message_id: Set(None),
         joined_at: Set(now),
         left_at: Set(None),
      };
      creator_member.insert(&self.db).await?;

      // Add other members
      for member_id in member_ids {
         if member_id != *creator_id {
            let member = conversation_member::ActiveModel {
               id: Set(Uuid::now_v7()),
               conversation_id: Set(conversation_id),
               user_id: Set(member_id),
               role: Set(MemberRole::Member),
               last_read_message_id: Set(None),
               joined_at: Set(now),
               left_at: Set(None),
            };
            member.insert(&self.db).await?;
         }
      }

      Ok(created_conv)
   }

   /// Get member count for a conversation
   pub async fn get_member_count(&self, conversation_id: &Uuid) -> Result<i64> {
      let count = ConversationMember::find()
         .filter(conversation_member::Column::ConversationId.eq(*conversation_id))
         .filter(conversation_member::Column::LeftAt.is_null())
         .count(&self.db)
         .await?;

      Ok(count as i64)
   }

   /// Get member role in a conversation
   pub async fn get_member_role(
      &self,
      conversation_id: &Uuid,
      user_id: &Uuid,
   ) -> Result<Option<MemberRole>> {
      let member = ConversationMember::find()
         .filter(conversation_member::Column::ConversationId.eq(*conversation_id))
         .filter(conversation_member::Column::UserId.eq(*user_id))
         .filter(conversation_member::Column::LeftAt.is_null())
         .one(&self.db)
         .await?;

      Ok(member.map(|m| m.role))
   }

   /// Update member role
   pub async fn update_member_role(
      &self,
      conversation_id: &Uuid,
      user_id: &Uuid,
      new_role: MemberRole,
   ) -> Result<()> {
      ConversationMember::update_many()
         .col_expr(conversation_member::Column::Role, sea_orm::sea_query::Expr::value(new_role))
         .filter(conversation_member::Column::ConversationId.eq(*conversation_id))
         .filter(conversation_member::Column::UserId.eq(*user_id))
         .filter(conversation_member::Column::LeftAt.is_null())
         .exec(&self.db)
         .await?;

      Ok(())
   }

   /// Transfer ownership from current owner to new owner
   pub async fn transfer_ownership(
      &self,
      conversation_id: &Uuid,
      current_owner_id: &Uuid,
      new_owner_id: &Uuid,
   ) -> Result<()> {
      // Demote current owner to admin
      self
         .update_member_role(conversation_id, current_owner_id, MemberRole::Admin)
         .await?;

      // Promote new owner
      self
         .update_member_role(conversation_id, new_owner_id, MemberRole::Owner)
         .await?;

      Ok(())
   }
}
