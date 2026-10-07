use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
   async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .create_table(
            Table::create()
               .table(Call::Table)
               .if_not_exists()
               .col(ColumnDef::new(Call::Id).uuid().not_null().primary_key())
               .col(ColumnDef::new(Call::RoomName).string_len(100).not_null().unique_key())
               .col(ColumnDef::new(Call::Type).string_len(20).not_null()) // 'voice' or 'video'
               .col(ColumnDef::new(Call::Mode).string_len(20).not_null()) // 'direct' or 'group'
               .col(ColumnDef::new(Call::ConversationId).uuid().null()) // Link to conversation if group call
               .col(ColumnDef::new(Call::InitiatedBy).uuid().not_null())
               .col(ColumnDef::new(Call::Status).string_len(20).not_null()) // 'ringing', 'active', 'ended', 'missed', 'rejected'
               .col(
                  ColumnDef::new(Call::StartedAt)
                     .timestamp_with_time_zone()
                     .not_null()
                     .default(Expr::current_timestamp()),
               )
               .col(ColumnDef::new(Call::EndedAt).timestamp_with_time_zone().null())
               .col(ColumnDef::new(Call::Duration).integer().null()) // Duration in seconds
               .col(
                  ColumnDef::new(Call::CreatedAt)
                     .timestamp_with_time_zone()
                     .not_null()
                     .default(Expr::current_timestamp()),
               )
               .col(
                  ColumnDef::new(Call::UpdatedAt)
                     .timestamp_with_time_zone()
                     .not_null()
                     .default(Expr::current_timestamp()),
               )
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_calls_initiated_by")
                     .from(Call::Table, Call::InitiatedBy)
                     .to(User::Table, User::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_calls_conversation_id")
                     .from(Call::Table, Call::ConversationId)
                     .to(Conversation::Table, Conversation::Id)
                     .on_delete(ForeignKeyAction::SetNull)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .to_owned(),
         )
         .await?;

      // Create index on room_name for quick lookup
      manager
         .create_index(
            Index::create()
               .name("idx_calls_room_name")
               .table(Call::Table)
               .col(Call::RoomName)
               .to_owned(),
         )
         .await?;

      // Create index on initiated_by for user's call history
      manager
         .create_index(
            Index::create()
               .name("idx_calls_initiated_by")
               .table(Call::Table)
               .col(Call::InitiatedBy)
               .to_owned(),
         )
         .await?;

      // Create index on status for filtering active calls
      manager
         .create_index(
            Index::create()
               .name("idx_calls_status")
               .table(Call::Table)
               .col(Call::Status)
               .to_owned(),
         )
         .await?;

      // Create index on started_at for sorting by time
      manager
         .create_index(
            Index::create()
               .name("idx_calls_started_at")
               .table(Call::Table)
               .col(Call::StartedAt)
               .to_owned(),
         )
         .await?;

      // Create composite index for conversation calls
      manager
         .create_index(
            Index::create()
               .name("idx_calls_conversation")
               .table(Call::Table)
               .col(Call::ConversationId)
               .col(Call::StartedAt)
               .to_owned(),
         )
         .await?;

      Ok(())
   }

   async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager.drop_table(Table::drop().table(Call::Table).to_owned()).await
   }
}

enum Call {
   Table,
   Id,
   RoomName,
   Type,
   Mode,
   ConversationId,
   InitiatedBy,
   Status,
   StartedAt,
   EndedAt,
   Duration,
   CreatedAt,
   UpdatedAt,
}

impl Iden for Call {
   fn unquoted(&self, s: &mut dyn std::fmt::Write) {
      write!(
         s,
         "{}",
         match self {
            Self::Table => "calls",
            Self::Id => "id",
            Self::RoomName => "room_name",
            Self::Type => "type",
            Self::Mode => "mode",
            Self::ConversationId => "conversation_id",
            Self::InitiatedBy => "initiated_by",
            Self::Status => "status",
            Self::StartedAt => "started_at",
            Self::EndedAt => "ended_at",
            Self::Duration => "duration",
            Self::CreatedAt => "created_at",
            Self::UpdatedAt => "updated_at",
         }
      )
      .unwrap()
   }
}

#[derive(DeriveIden)]
enum User {
   Table,
   Id,
}

#[derive(DeriveIden)]
enum Conversation {
   Table,
   Id,
}
