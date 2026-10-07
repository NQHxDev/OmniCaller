use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
   async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .create_table(
            Table::create()
               .table(CallParticipant::Table)
               .if_not_exists()
               .col(ColumnDef::new(CallParticipant::Id).uuid().not_null().primary_key())
               .col(ColumnDef::new(CallParticipant::CallId).uuid().not_null())
               .col(ColumnDef::new(CallParticipant::UserId).uuid().not_null())
               .col(ColumnDef::new(CallParticipant::Status).string_len(20).not_null()) // 'invited', 'ringing', 'joined', 'left', 'rejected', 'missed'
               .col(
                  ColumnDef::new(CallParticipant::JoinedAt)
                     .timestamp_with_time_zone()
                     .null(),
               )
               .col(
                  ColumnDef::new(CallParticipant::LeftAt)
                     .timestamp_with_time_zone()
                     .null(),
               )
               .col(ColumnDef::new(CallParticipant::Duration).integer().null()) // Duration in seconds
               .col(
                  ColumnDef::new(CallParticipant::CreatedAt)
                     .timestamp_with_time_zone()
                     .not_null()
                     .default(Expr::current_timestamp()),
               )
               .col(
                  ColumnDef::new(CallParticipant::UpdatedAt)
                     .timestamp_with_time_zone()
                     .not_null()
                     .default(Expr::current_timestamp()),
               )
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_call_participants_call_id")
                     .from(CallParticipant::Table, CallParticipant::CallId)
                     .to(Call::Table, Call::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_call_participants_user_id")
                     .from(CallParticipant::Table, CallParticipant::UserId)
                     .to(User::Table, User::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .to_owned(),
         )
         .await?;

      // Create unique constraint on (call_id, user_id) - BCNF: One user can only be in a call once
      manager
         .create_index(
            Index::create()
               .name("idx_call_participants_unique")
               .table(CallParticipant::Table)
               .col(CallParticipant::CallId)
               .col(CallParticipant::UserId)
               .unique()
               .to_owned(),
         )
         .await?;

      // Create index on user_id for user's call history
      manager
         .create_index(
            Index::create()
               .name("idx_call_participants_user_id")
               .table(CallParticipant::Table)
               .col(CallParticipant::UserId)
               .to_owned(),
         )
         .await?;

      // Create index on call_id for participants lookup
      manager
         .create_index(
            Index::create()
               .name("idx_call_participants_call_id")
               .table(CallParticipant::Table)
               .col(CallParticipant::CallId)
               .to_owned(),
         )
         .await?;

      // Create composite index for status queries
      manager
         .create_index(
            Index::create()
               .name("idx_call_participants_status")
               .table(CallParticipant::Table)
               .col(CallParticipant::CallId)
               .col(CallParticipant::Status)
               .to_owned(),
         )
         .await?;

      Ok(())
   }

   async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .drop_table(Table::drop().table(CallParticipant::Table).to_owned())
         .await
   }
}

enum CallParticipant {
   Table,
   Id,
   CallId,
   UserId,
   Status,
   JoinedAt,
   LeftAt,
   Duration,
   CreatedAt,
   UpdatedAt,
}

impl Iden for CallParticipant {
   fn unquoted(&self, s: &mut dyn std::fmt::Write) {
      write!(
         s,
         "{}",
         match self {
            Self::Table => "call_participants",
            Self::Id => "id",
            Self::CallId => "call_id",
            Self::UserId => "user_id",
            Self::Status => "status",
            Self::JoinedAt => "joined_at",
            Self::LeftAt => "left_at",
            Self::Duration => "duration",
            Self::CreatedAt => "created_at",
            Self::UpdatedAt => "updated_at",
         }
      )
      .unwrap()
   }
}

enum Call {
   Table,
   Id,
}

impl Iden for Call {
   fn unquoted(&self, s: &mut dyn std::fmt::Write) {
      write!(
         s,
         "{}",
         match self {
            Self::Table => "calls",
            Self::Id => "id",
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
