pub use sea_orm_migration::prelude::*;

mod m20261003_000001_create_accounts_table;
mod m20261003_000002_create_users_table;
mod m20261004_000003_create_friendships_table;
mod m20261005_000004_create_conversations_table;
mod m20261005_000005_create_conversation_members_table;
mod m20261005_000006_create_messages_table;
mod m20261005_000007_create_message_attachments_table;

pub struct Migrator;

#[async_trait::async_trait]
impl MigratorTrait for Migrator {
   fn migrations() -> Vec<Box<dyn MigrationTrait>> {
      vec![
         Box::new(m20261003_000001_create_accounts_table::Migration),
         Box::new(m20261003_000002_create_users_table::Migration),
         Box::new(m20261004_000003_create_friendships_table::Migration),
         Box::new(m20261005_000004_create_conversations_table::Migration),
         Box::new(m20261005_000005_create_conversation_members_table::Migration),
         Box::new(m20261005_000006_create_messages_table::Migration),
         Box::new(m20261005_000007_create_message_attachments_table::Migration),
      ]
   }
}
