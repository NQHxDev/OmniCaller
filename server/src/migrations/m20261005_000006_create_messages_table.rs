use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
   async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .create_table(
            Table::create()
               .table(Message::Table)
               .if_not_exists()
               .col(ColumnDef::new(Message::Id).uuid().not_null().primary_key())
               .col(ColumnDef::new(Message::ConversationId).uuid().not_null())
               .col(ColumnDef::new(Message::SenderId).uuid().not_null())
               .col(ColumnDef::new(Message::ReplyToMessageId).uuid().null())
               .col(ColumnDef::new(Message::MessageType).string_len(20).not_null())
               .col(ColumnDef::new(Message::Content).text().null())
               .col(ColumnDef::new(Message::Status).string_len(20).not_null())
               .col(ColumnDef::new(Message::CreatedAt).timestamp_with_time_zone().not_null())
               .col(ColumnDef::new(Message::UpdatedAt).timestamp_with_time_zone().not_null())
               .col(ColumnDef::new(Message::DeletedAt).timestamp_with_time_zone().null())
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_message_conversation")
                     .from(Message::Table, Message::ConversationId)
                     .to(Conversation::Table, Conversation::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_message_sender")
                     .from(Message::Table, Message::SenderId)
                     .to(User::Table, User::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_message_reply_to")
                     .from(Message::Table, Message::ReplyToMessageId)
                     .to(Message::Table, Message::Id)
                     .on_delete(ForeignKeyAction::SetNull)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .to_owned(),
         )
         .await?;

      // Critical composite index for cursor-based pagination (DESC for latest messages first)
      manager
         .create_index(
            Index::create()
               .name("idx_messages_conv_id_desc")
               .table(Message::Table)
               .col(Message::ConversationId)
               .col((Message::Id, IndexOrder::Desc))
               .to_owned(),
         )
         .await?;

      // Index on sender_id for user's sent messages
      manager
         .create_index(
            Index::create()
               .name("idx_messages_sender")
               .table(Message::Table)
               .col(Message::SenderId)
               .to_owned(),
         )
         .await?;

      // Index on reply_to for threading
      manager
         .create_index(
            Index::create()
               .name("idx_messages_reply_to")
               .table(Message::Table)
               .col(Message::ReplyToMessageId)
               .to_owned(),
         )
         .await?;

      Ok(())
   }

   async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager.drop_table(Table::drop().table(Message::Table).to_owned()).await
   }
}

#[derive(DeriveIden)]
enum Message {
   Table,
   Id,
   ConversationId,
   SenderId,
   ReplyToMessageId,
   MessageType,
   Content,
   Status,
   CreatedAt,
   UpdatedAt,
   DeletedAt,
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
