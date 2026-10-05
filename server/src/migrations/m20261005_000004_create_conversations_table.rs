use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
   async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .create_table(
            Table::create()
               .table(Conversation::Table)
               .if_not_exists()
               .col(ColumnDef::new(Conversation::Id).uuid().not_null().primary_key())
               .col(ColumnDef::new(Conversation::Type).string_len(20).not_null())
               .col(ColumnDef::new(Conversation::Title).string_len(100).null())
               .col(ColumnDef::new(Conversation::AvatarUrl).string_len(255).null())
               .col(ColumnDef::new(Conversation::CreatedBy).uuid().not_null())
               .col(ColumnDef::new(Conversation::CreatedAt).timestamp_with_time_zone().not_null())
               .col(ColumnDef::new(Conversation::UpdatedAt).timestamp_with_time_zone().not_null())
               .col(ColumnDef::new(Conversation::DeletedAt).timestamp_with_time_zone().null())
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_conversation_created_by")
                     .from(Conversation::Table, Conversation::CreatedBy)
                     .to(User::Table, User::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .to_owned(),
         )
         .await?;

      // Create index on type for filtering
      manager
         .create_index(
            Index::create()
               .name("idx_conversations_type")
               .table(Conversation::Table)
               .col(Conversation::Type)
               .to_owned(),
         )
         .await?;

      // Create index on created_by for user's created conversations
      manager
         .create_index(
            Index::create()
               .name("idx_conversations_created_by")
               .table(Conversation::Table)
               .col(Conversation::CreatedBy)
               .to_owned(),
         )
         .await?;

      Ok(())
   }

   async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager.drop_table(Table::drop().table(Conversation::Table).to_owned()).await
   }
}

#[derive(DeriveIden)]
enum Conversation {
   Table,
   Id,
   Type,
   Title,
   AvatarUrl,
   CreatedBy,
   CreatedAt,
   UpdatedAt,
   DeletedAt,
}

#[derive(DeriveIden)]
enum User {
   Table,
   Id,
}
