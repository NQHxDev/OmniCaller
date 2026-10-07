use crate::dtos::group_dtos::{CreateGroupRequest, GroupProfileResponse};
use crate::repositories::conversation_repository::ConversationRepository;
use crate::repositories::friend_repository::FriendRepository;
use anyhow::{bail, Result};
use uuid::Uuid;

#[derive(Clone)]
pub struct GroupService {
   conversation_repo: ConversationRepository,
   friend_repo: FriendRepository,
}

impl GroupService {
   pub fn new(conversation_repo: ConversationRepository, friend_repo: FriendRepository) -> Self {
      Self { conversation_repo, friend_repo }
   }

   /// Create a new group
   pub async fn create_group(
      &self,
      creator_id: &Uuid,
      request: CreateGroupRequest,
   ) -> Result<GroupProfileResponse> {
      // Validate that all members are friends with creator
      for member_id in &request.member_ids {
         if member_id == creator_id {
            continue;
         }

         let are_friends = self.friend_repo.are_friends(creator_id, member_id).await?;
         if !are_friends {
            bail!("You can only add friends to a group. User {} is not your friend", member_id);
         }
      }

      // Create the group conversation
      let conversation = self
         .conversation_repo
         .create_group_conversation(
            creator_id,
            request.name,
            request.description,
            request.avatar_url,
            request.banner_url,
            request.member_ids,
         )
         .await?;

      // Get member count
      let member_count = self.conversation_repo.get_member_count(&conversation.id).await?;

      Ok(GroupProfileResponse {
         id: conversation.id,
         name: conversation.title.unwrap_or_default(),
         description: conversation.description,
         avatar_url: conversation.avatar_url,
         banner_url: conversation.banner_url,
         pinned_message_id: conversation.pinned_message_id,
         created_by: conversation.created_by,
         member_count,
         created_at: conversation.created_at.to_string(),
      })
   }

   /// Get all groups the user is a member of
   pub async fn get_user_groups(&self, user_id: &Uuid) -> Result<Vec<GroupProfileResponse>> {
      let conversations = self.conversation_repo.get_user_conversations(user_id).await?;

      let mut groups = Vec::new();

      for (conv, _, _) in conversations {
         // Only include groups, not direct conversations
         if conv.is_group() {
            let member_count = self.conversation_repo.get_member_count(&conv.id).await?;

            groups.push(GroupProfileResponse {
               id: conv.id,
               name: conv.title.unwrap_or_default(),
               description: conv.description,
               avatar_url: conv.avatar_url,
               banner_url: conv.banner_url,
               pinned_message_id: conv.pinned_message_id,
               created_by: conv.created_by,
               member_count,
               created_at: conv.created_at.to_string(),
            });
         }
      }

      Ok(groups)
   }

   /// Promote a member to admin (only owner can do this)
   pub async fn promote_member_to_admin(
      &self,
      group_id: &Uuid,
      requester_id: &Uuid,
      target_user_id: &Uuid,
   ) -> Result<()> {
      // Check if requester is the owner
      let requester_role = self.conversation_repo.get_member_role(group_id, requester_id).await?;
      if requester_role != Some(crate::entities::conversation_member::MemberRole::Owner) {
         bail!("Only the group owner can promote members to admin");
      }

      // Check if target user is a member
      let target_role = self.conversation_repo.get_member_role(group_id, target_user_id).await?;
      if target_role.is_none() {
         bail!("Target user is not a member of this group");
      }

      if target_role == Some(crate::entities::conversation_member::MemberRole::Owner) {
         bail!("Cannot change the owner's role");
      }

      if target_role == Some(crate::entities::conversation_member::MemberRole::Admin) {
         bail!("User is already an admin");
      }

      // Promote to admin
      self
         .conversation_repo
         .update_member_role(
            group_id,
            target_user_id,
            crate::entities::conversation_member::MemberRole::Admin,
         )
         .await?;

      Ok(())
   }

   /// Demote an admin to member (only owner can do this)
   pub async fn demote_admin_to_member(
      &self,
      group_id: &Uuid,
      requester_id: &Uuid,
      target_user_id: &Uuid,
   ) -> Result<()> {
      // Check if requester is the owner
      let requester_role = self.conversation_repo.get_member_role(group_id, requester_id).await?;
      if requester_role != Some(crate::entities::conversation_member::MemberRole::Owner) {
         bail!("Only the group owner can demote admins");
      }

      // Check if target user is an admin
      let target_role = self.conversation_repo.get_member_role(group_id, target_user_id).await?;
      if target_role != Some(crate::entities::conversation_member::MemberRole::Admin) {
         bail!("Target user is not an admin");
      }

      // Demote to member
      self
         .conversation_repo
         .update_member_role(
            group_id,
            target_user_id,
            crate::entities::conversation_member::MemberRole::Member,
         )
         .await?;

      Ok(())
   }

   /// Transfer ownership to an admin (only owner can do this)
   pub async fn transfer_ownership(
      &self,
      group_id: &Uuid,
      current_owner_id: &Uuid,
      new_owner_id: &Uuid,
   ) -> Result<()> {
      // Check if requester is the owner
      let requester_role =
         self.conversation_repo.get_member_role(group_id, current_owner_id).await?;
      if requester_role != Some(crate::entities::conversation_member::MemberRole::Owner) {
         bail!("Only the group owner can transfer ownership");
      }

      // Check if target user is an admin
      let target_role = self.conversation_repo.get_member_role(group_id, new_owner_id).await?;
      if target_role != Some(crate::entities::conversation_member::MemberRole::Admin) {
         bail!("Can only transfer ownership to an admin");
      }

      // Transfer ownership
      self
         .conversation_repo
         .transfer_ownership(group_id, current_owner_id, new_owner_id)
         .await?;

      Ok(())
   }
}
