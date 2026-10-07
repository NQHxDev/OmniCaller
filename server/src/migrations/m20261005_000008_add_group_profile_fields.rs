use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
   async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      // Add group profile fields to conversations table
      manager
         .alter_table(
            Table::alter()
               .table(Conversation::Table)
               .add_column(ColumnDef::new(Conversation::Description).string_len(500).null())
               .add_column(ColumnDef::new(Conversation::BannerUrl).string_len(255).null())
               .add_column(ColumnDef::new(Conversation::PinnedMessageId).uuid().null())
               .to_owned(),
         )
         .await?;

      // Add foreign key for pinned_message_id
      manager
         .alter_table(
            Table::alter()
               .table(Conversation::Table)
               .add_foreign_key(
                  TableForeignKey::new()
                     .name("fk_conversation_pinned_message")
                     .from_tbl(Conversation::Table)
                     .from_col(Conversation::PinnedMessageId)
                     .to_tbl(Message::Table)
                     .to_col(Message::Id)
                     .on_delete(ForeignKeyAction::SetNull)
                     .on_update(ForeignKeyAction::Cascade)
               )
               .to_owned(),
         )
         .await?;

      Ok(())
   }

   async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .alter_table(
            Table::alter()
               .table(Conversation::Table)
               .drop_foreign_key(Alias::new("fk_conversation_pinned_message"))
               .to_owned(),
         )
         .await?;

      manager
         .alter_table(
            Table::alter()
               .table(Conversation::Table)
               .drop_column(Conversation::PinnedMessageId)
               .drop_column(Conversation::BannerUrl)
               .drop_column(Conversation::Description)
               .to_owned(),
         )
         .await?;

      Ok(())
   }
}

#[derive(DeriveIden)]
enum Conversation {
   Table,
   Description,
   BannerUrl,
   PinnedMessageId,
}

#[derive(DeriveIden)]
enum Message {
   Table,
   Id,
}
