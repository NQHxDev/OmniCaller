use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
   async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .create_table(
            Table::create()
               .table(User::Table)
               .if_not_exists()
               .col(ColumnDef::new(User::Id).uuid().not_null().primary_key())
               .col(ColumnDef::new(User::AccountId).uuid().not_null().unique_key())
               .col(ColumnDef::new(User::DisplayName).string_len(100).not_null())
               .col(
                  ColumnDef::new(User::CreatedAt)
                     .timestamp_with_time_zone()
                     .not_null()
                     .default(Expr::current_timestamp()),
               )
               .col(
                  ColumnDef::new(User::UpdatedAt)
                     .timestamp_with_time_zone()
                     .not_null()
                     .default(Expr::current_timestamp()),
               )
               .col(ColumnDef::new(User::DeletedAt).timestamp_with_time_zone().null())
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_users_account_id")
                     .from(User::Table, User::AccountId)
                     .to(Account::Table, Account::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .to_owned(),
         )
         .await?;

      // Create index for account_id lookup
      manager
         .create_index(
            Index::create()
               .name("idx_users_account_id")
               .table(User::Table)
               .col(User::AccountId)
               .to_owned(),
         )
         .await?;

      Ok(())
   }

   async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager.drop_table(Table::drop().table(User::Table).to_owned()).await
   }
}

#[derive(DeriveIden)]
enum User {
   Table,
   Id,
   AccountId,
   DisplayName,
   CreatedAt,
   UpdatedAt,
   DeletedAt,
}

#[derive(DeriveIden)]
enum Account {
   Table,
   Id,
}
