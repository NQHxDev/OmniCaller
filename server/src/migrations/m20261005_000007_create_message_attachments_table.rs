use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
   async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .create_table(
            Table::create()
               .table(MessageAttachment::Table)
               .if_not_exists()
               .col(ColumnDef::new(MessageAttachment::Id).uuid().not_null().primary_key())
               .col(ColumnDef::new(MessageAttachment::MessageId).uuid().not_null())
               .col(ColumnDef::new(MessageAttachment::FileUrl).text().not_null())
               .col(ColumnDef::new(MessageAttachment::ThumbnailUrl).text().null())
               .col(ColumnDef::new(MessageAttachment::FileType).string_len(50).not_null())
               .col(ColumnDef::new(MessageAttachment::FileSizeBytes).big_integer().not_null())
               .col(ColumnDef::new(MessageAttachment::Width).integer().null())
               .col(ColumnDef::new(MessageAttachment::Height).integer().null())
               .col(ColumnDef::new(MessageAttachment::DurationSeconds).integer().null())
               .col(
                  ColumnDef::new(MessageAttachment::CreatedAt)
                     .timestamp_with_time_zone()
                     .not_null(),
               )
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_message_attachment_message")
                     .from(MessageAttachment::Table, MessageAttachment::MessageId)
                     .to(Message::Table, Message::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .to_owned(),
         )
         .await?;

      // Create index on message_id for quick attachment lookup
      manager
         .create_index(
            Index::create()
               .name("idx_message_attachments_message_id")
               .table(MessageAttachment::Table)
               .col(MessageAttachment::MessageId)
               .to_owned(),
         )
         .await?;

      Ok(())
   }

   async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .drop_table(Table::drop().table(MessageAttachment::Table).to_owned())
         .await
   }
}

#[derive(DeriveIden)]
enum MessageAttachment {
   Table,
   Id,
   MessageId,
   FileUrl,
   ThumbnailUrl,
   FileType,
   FileSizeBytes,
   Width,
   Height,
   DurationSeconds,
   CreatedAt,
}

#[derive(DeriveIden)]
enum Message {
   Table,
   Id,
}
