use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
   async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .create_table(
            Table::create()
               .table(GroupInvite::Table)
               .if_not_exists()
               .col(ColumnDef::new(GroupInvite::Id).uuid().not_null().primary_key())
               .col(ColumnDef::new(GroupInvite::ConversationId).uuid().not_null())
               .col(ColumnDef::new(GroupInvite::InviterId).uuid().not_null())
               .col(ColumnDef::new(GroupInvite::Code).string_len(32).not_null().unique_key())
               .col(ColumnDef::new(GroupInvite::MaxUses).integer().null())
               .col(ColumnDef::new(GroupInvite::UsesCount).integer().not_null().default(0))
               .col(ColumnDef::new(GroupInvite::ExpiresAt).timestamp_with_time_zone().null())
               .col(ColumnDef::new(GroupInvite::CreatedAt).timestamp_with_time_zone().not_null())
               .col(ColumnDef::new(GroupInvite::RevokedAt).timestamp_with_time_zone().null())
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_group_invite_conversation")
                     .from(GroupInvite::Table, GroupInvite::ConversationId)
                     .to(Conversation::Table, Conversation::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_group_invite_inviter")
                     .from(GroupInvite::Table, GroupInvite::InviterId)
                     .to(User::Table, User::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .to_owned(),
         )
         .await?;

      // Create index on conversation_id for listing group invites
      manager
         .create_index(
            Index::create()
               .name("idx_group_invites_conversation_id")
               .table(GroupInvite::Table)
               .col(GroupInvite::ConversationId)
               .to_owned(),
         )
         .await?;

      // Create unique index on code for fast lookup
      manager
         .create_index(
            Index::create()
               .name("idx_group_invites_code")
               .table(GroupInvite::Table)
               .col(GroupInvite::Code)
               .unique()
               .to_owned(),
         )
         .await?;

      // Create index on inviter_id
      manager
         .create_index(
            Index::create()
               .name("idx_group_invites_inviter_id")
               .table(GroupInvite::Table)
               .col(GroupInvite::InviterId)
               .to_owned(),
         )
         .await?;

      Ok(())
   }

   async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager.drop_table(Table::drop().table(GroupInvite::Table).to_owned()).await
   }
}

#[derive(DeriveIden)]
enum GroupInvite {
   Table,
   Id,
   ConversationId,
   InviterId,
   Code,
   MaxUses,
   UsesCount,
   ExpiresAt,
   CreatedAt,
   RevokedAt,
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
