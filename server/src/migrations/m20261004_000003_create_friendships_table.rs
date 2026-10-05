use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
   async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager
         .create_table(
            Table::create()
               .table(Friendship::Table)
               .if_not_exists()
               .col(ColumnDef::new(Friendship::Id).uuid().not_null().primary_key())
               .col(ColumnDef::new(Friendship::UserId).uuid().not_null())
               .col(ColumnDef::new(Friendship::FriendId).uuid().not_null())
               .col(ColumnDef::new(Friendship::Status).string_len(20).not_null().default("pending"))
               .col(ColumnDef::new(Friendship::RequestedAt).timestamp_with_time_zone().not_null())
               .col(ColumnDef::new(Friendship::RespondedAt).timestamp_with_time_zone())
               .col(ColumnDef::new(Friendship::CreatedAt).timestamp_with_time_zone().not_null())
               .col(ColumnDef::new(Friendship::UpdatedAt).timestamp_with_time_zone().not_null())
               .col(ColumnDef::new(Friendship::DeletedAt).timestamp_with_time_zone())
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_friendship_user_id")
                     .from(Friendship::Table, Friendship::UserId)
                     .to(User::Table, User::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .foreign_key(
                  ForeignKey::create()
                     .name("fk_friendship_friend_id")
                     .from(Friendship::Table, Friendship::FriendId)
                     .to(User::Table, User::Id)
                     .on_delete(ForeignKeyAction::Cascade)
                     .on_update(ForeignKeyAction::Cascade),
               )
               .to_owned(),
         )
         .await?;

      // Create unique constraint: one friendship per user pair
      manager
         .create_index(
            Index::create()
               .name("idx_friendship_user_friend_unique")
               .table(Friendship::Table)
               .col(Friendship::UserId)
               .col(Friendship::FriendId)
               .unique()
               .to_owned(),
         )
         .await?;

      // Create index for querying friendships by user_id
      manager
         .create_index(
            Index::create()
               .name("idx_friendship_user_id")
               .table(Friendship::Table)
               .col(Friendship::UserId)
               .to_owned(),
         )
         .await?;

      // Create index for querying friendships by friend_id
      manager
         .create_index(
            Index::create()
               .name("idx_friendship_friend_id")
               .table(Friendship::Table)
               .col(Friendship::FriendId)
               .to_owned(),
         )
         .await?;

      // Create index for querying by status
      manager
         .create_index(
            Index::create()
               .name("idx_friendship_status")
               .table(Friendship::Table)
               .col(Friendship::Status)
               .to_owned(),
         )
         .await?;

      Ok(())
   }

   async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
      manager.drop_table(Table::drop().table(Friendship::Table).to_owned()).await
   }
}

#[derive(DeriveIden)]
enum Friendship {
   Table,
   Id,
   UserId,
   FriendId,
   Status,
   RequestedAt,
   RespondedAt,
   CreatedAt,
   UpdatedAt,
   DeletedAt,
}

#[derive(DeriveIden)]
enum User {
   Table,
   Id,
}
