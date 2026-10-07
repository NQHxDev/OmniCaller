use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
   async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .create_table(
            Table::create()
               .table(UserPresence::Table)
               .if_not_exists()
               .col(ColumnDef::new(UserPresence::UserId).uuid().not_null().primary_key())
               .col(ColumnDef::new(UserPresence::Status).string_len(20).not_null()) // 'online', 'offline', 'busy', 'in_call'
               .col(ColumnDef::new(UserPresence::LastSeenAt).timestamp_with_time_zone().not_null())
               .col(
                  ColumnDef::new(UserPresence::UpdatedAt)
                     .timestamp_with_time_zone()
                     .not_null()
                     .default(Expr::current_timestamp()),
               )
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_user_presence_user_id")
                     .from(UserPresence::Table, UserPresence::UserId)
                     .to(User::Table, User::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .to_owned(),
         )
         .await?;

      // Create index on status for filtering by presence
      manager
         .create_index(
            Index::create()
               .name("idx_user_presence_status")
               .table(UserPresence::Table)
               .col(UserPresence::Status)
               .to_owned(),
         )
         .await?;

      // Create index on last_seen_at for sorting
      manager
         .create_index(
            Index::create()
               .name("idx_user_presence_last_seen")
               .table(UserPresence::Table)
               .col(UserPresence::LastSeenAt)
               .to_owned(),
         )
         .await?;

      Ok(())
   }

   async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .drop_table(Table::drop().table(UserPresence::Table).to_owned())
         .await
   }
}

enum UserPresence {
   Table,
   UserId,
   Status,
   LastSeenAt,
   UpdatedAt,
}

impl Iden for UserPresence {
   fn unquoted(&self, s: &mut dyn std::fmt::Write) {
      write!(
         s,
         "{}",
         match self {
            Self::Table => "user_presence",
            Self::UserId => "user_id",
            Self::Status => "status",
            Self::LastSeenAt => "last_seen_at",
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
