use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
   async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .create_table(
            Table::create()
               .table(ConversationMember::Table)
               .if_not_exists()
               .col(ColumnDef::new(ConversationMember::Id).uuid().not_null().primary_key())
               .col(ColumnDef::new(ConversationMember::ConversationId).uuid().not_null())
               .col(ColumnDef::new(ConversationMember::UserId).uuid().not_null())
               .col(ColumnDef::new(ConversationMember::Role).string_len(20).not_null())
               .col(ColumnDef::new(ConversationMember::LastReadMessageId).uuid().null())
               .col(
                  ColumnDef::new(ConversationMember::JoinedAt)
                     .timestamp_with_time_zone()
                     .not_null(),
               )
               .col(ColumnDef::new(ConversationMember::LeftAt).timestamp_with_time_zone().null())
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_conversation_member_conversation")
                     .from(ConversationMember::Table, ConversationMember::ConversationId)
                     .to(Conversation::Table, Conversation::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_conversation_member_user")
                     .from(ConversationMember::Table, ConversationMember::UserId)
                     .to(User::Table, User::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .to_owned(),
         )
         .await?;

      // Create unique constraint on (conversation_id, user_id)
      manager
         .create_index(
            Index::create()
               .name("idx_conversation_members_unique")
               .table(ConversationMember::Table)
               .col(ConversationMember::ConversationId)
               .col(ConversationMember::UserId)
               .unique()
               .to_owned(),
         )
         .await?;

      // Create composite index for user's conversations query
      manager
         .create_index(
            Index::create()
               .name("idx_conv_members_user")
               .table(ConversationMember::Table)
               .col(ConversationMember::UserId)
               .col(ConversationMember::ConversationId)
               .to_owned(),
         )
         .await?;

      // Create index on conversation_id for members lookup
      manager
         .create_index(
            Index::create()
               .name("idx_conversation_members_conv_id")
               .table(ConversationMember::Table)
               .col(ConversationMember::ConversationId)
               .to_owned(),
         )
         .await?;

      Ok(())
   }

   async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .drop_table(Table::drop().table(ConversationMember::Table).to_owned())
         .await
   }
}

#[derive(DeriveIden)]
enum ConversationMember {
   Table,
   Id,
   ConversationId,
   UserId,
   Role,
   LastReadMessageId,
   JoinedAt,
   LeftAt,
}

#[derive(DeriveIden)]
enum Conversation {
   Table,
   Id,
}

#[derive(DeriveIden)]
enum User {
   Table,
   Id,
}
