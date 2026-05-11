import gleam/bool
import gleam/int
import gleam/list
import glindex.{type Database}
import glindex/transaction

pub type DatabaseError {
  Blocked
  UnknownError(String)
  VersionError
}

pub opaque type DatabaseMigration {
  DatabaseMigration(
    version: Int,
    migrate: fn(
      transaction.Transaction(glindex.ReadWrite, glindex.VersionChange),
    ) -> Nil,
  )
}

pub opaque type DatabaseBuilder {
  DatabaseBuilder(
    name: String,
    version: Int,
    migrations: List(DatabaseMigration),
  )
}

pub fn new(name: String, version: Int) -> DatabaseBuilder {
  DatabaseBuilder(name:, version:, migrations: [])
}

pub fn add_version(
  builder: DatabaseBuilder,
  version: Int,
  migrate: fn(transaction.Transaction(glindex.ReadWrite, glindex.VersionChange)) ->
    Nil,
) -> DatabaseBuilder {
  DatabaseBuilder(..builder, migrations: [
    DatabaseMigration(version:, migrate:),
    ..builder.migrations
  ])
}

pub fn open(
  builder: DatabaseBuilder,
  next: fn(Result(Database, DatabaseError)) -> a,
) {
  use <- bool.lazy_guard(builder.version <= 0, fn() {
    next(Error(VersionError))
    Nil
  })

  use <- bool.lazy_guard(
    list.any(builder.migrations, fn(migration) { migration.version <= 0 }),
    fn() {
      next(Error(VersionError))
      Nil
    },
  )

  let migrations =
    builder.migrations
    |> list.sort(fn(a, b) { int.compare(a.version, b.version) })

  use <- bool.lazy_guard(
    list.window_by_2(migrations)
      |> list.any(fn(pair) { pair.0.version == pair.1.version }),
    fn() {
      next(Error(VersionError))
      Nil
    },
  )

  open_database(
    builder.name,
    builder.version,
    fn(old_version, tx) {
      list.each(migrations, fn(migration) {
        case
          migration.version > old_version
          && migration.version <= builder.version
        {
          True -> {
            migration.migrate(tx)
            Nil
          }
          False -> Nil
        }
      })
    },
    fn(result) {
      case result {
        Ok(db) -> next(Ok(db))
        Error("BlockedError") -> next(Error(Blocked))
        Error("VersionError") -> next(Error(VersionError))
        Error(name) -> next(Error(UnknownError(name)))
      }
    },
  )
}

@external(javascript, "./database_ffi.mjs", "open_database")
fn open_database(
  name: String,
  version: Int,
  on_upgrade_needed: fn(
    Int,
    transaction.Transaction(glindex.ReadWrite, glindex.VersionChange),
  ) -> Nil,
  next: fn(Result(Database, String)) -> a,
) -> Nil

pub fn close(db: Database) -> Nil {
  close_database(db)
}

@external(javascript, "./database_ffi.mjs", "close_database")
fn close_database(db: Database) -> Nil
