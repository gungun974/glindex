import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{type Option}
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
    on_blocked: Option(fn(Int, Int) -> Nil),
    on_blocking: Option(fn(Int, Int) -> Nil),
    on_close: Option(fn() -> Nil),
  )
}

pub fn new(name: String, version: Int) -> DatabaseBuilder {
  DatabaseBuilder(
    name:,
    version:,
    migrations: [],
    on_blocked: option.None,
    on_blocking: option.None,
    on_close: option.None,
  )
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

pub fn on_blocked(
  builder: DatabaseBuilder,
  handler: fn(Int, Int) -> a,
) -> DatabaseBuilder {
  DatabaseBuilder(
    ..builder,
    on_blocked: option.Some(fn(old, new) {
      let _ = handler(old, new)
      Nil
    }),
  )
}

pub fn on_blocking(
  builder: DatabaseBuilder,
  handler: fn(Int, Int) -> a,
) -> DatabaseBuilder {
  DatabaseBuilder(
    ..builder,
    on_blocking: option.Some(fn(old, new) {
      let _ = handler(old, new)
      Nil
    }),
  )
}

pub fn on_close(
  builder: DatabaseBuilder,
  handler: fn() -> a,
) -> DatabaseBuilder {
  DatabaseBuilder(
    ..builder,
    on_close: option.Some(fn() {
      let _ = handler()
      Nil
    }),
  )
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
    builder.on_blocked,
    builder.on_blocking,
    builder.on_close,
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
  on_blocked: Option(fn(Int, Int) -> Nil),
  on_blocking: Option(fn(Int, Int) -> Nil),
  on_terminated: Option(fn() -> Nil),
  next: fn(Result(Database, String)) -> a,
) -> Nil

pub fn close(db: Database) -> Nil {
  close_database(db)
}

@external(javascript, "./database_ffi.mjs", "close_database")
fn close_database(db: Database) -> Nil

pub type DatabaseInfo {
  DatabaseInfo(name: String, version: Int)
}

pub fn databases(
  next: fn(Result(List(DatabaseInfo), DatabaseError)) -> a,
) -> a {
  databases_ffi(fn(result) {
    case result {
      Ok(infos) ->
        next(
          Ok(
            list.map(infos, fn(info) {
              DatabaseInfo(name: info.0, version: info.1)
            }),
          ),
        )
      Error(e) -> next(Error(UnknownError(e)))
    }
  })
}

@external(javascript, "./database_ffi.mjs", "databases")
fn databases_ffi(next: fn(Result(List(#(String, Int)), String)) -> a) -> a

pub fn delete(name: String, next: fn(Result(Nil, DatabaseError)) -> a) -> a {
  delete_ffi(name, fn(result) {
    case result {
      Ok(_) -> next(Ok(Nil))
      Error("BlockedError") -> next(Error(Blocked))
      Error(e) -> next(Error(UnknownError(e)))
    }
  })
}

@external(javascript, "./database_ffi.mjs", "delete_database")
fn delete_ffi(name: String, next: fn(Result(Nil, String)) -> a) -> a
