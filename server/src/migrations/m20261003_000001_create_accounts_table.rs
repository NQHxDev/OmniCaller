use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
   async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .create_table(
            Table::create()
               .table(Account::Table)
               .if_not_exists()
               .col(ColumnDef::new(Account::Id).uuid().not_null().primary_key())
               .col(ColumnDef::new(Account::Username).string_len(30).not_null().unique_key())
               .col(ColumnDef::new(Account::Password).string_len(255).not_null())
               .col(
                  ColumnDef::new(Account::CreatedAt)
                     .timestamp_with_time_zone()
                     .not_null()
                     .default(Expr::current_timestamp()),
               )
               .col(
                  ColumnDef::new(Account::UpdatedAt)
                     .timestamp_with_time_zone()
                     .not_null()
                     .default(Expr::current_timestamp()),
               )
               .col(ColumnDef::new(Account::DeletedAt).timestamp_with_time_zone().null())
               .to_owned(),
         )
         .await?;

      // Create index for username lookup
      manager
         .create_index(
            Index::create()
               .name("idx_accounts_username")
               .table(Account::Table)
               .col(Account::Username)
               .to_owned(),
         )
         .await?;

      Ok(())
   }

   async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager.drop_table(Table::drop().table(Account::Table).to_owned()).await
   }
}

#[derive(DeriveIden)]
enum Account {
   Table,
   Id,
   Username,
   Password,
   CreatedAt,
   UpdatedAt,
   DeletedAt,
}
