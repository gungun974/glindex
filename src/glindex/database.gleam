import glindex.{type Database, type IdbError}
import glindex/transaction

pub type DatabaseBuilder

pub fn new(name: String, version: Int) -> DatabaseBuilder {
  todo
}

pub fn add_version(
  builder: DatabaseBuilder,
  version: Int,
  migrate: fn(transaction.Transaction(glindex.ReadWrite, glindex.VersionChange)) ->
    Nil,
) -> DatabaseBuilder {
  todo
}

pub fn open(builder: DatabaseBuilder, next: fn(Result(Database, IdbError)) -> a) {
  todo
}

pub fn close(db: Database) -> Nil {
  Nil
}
