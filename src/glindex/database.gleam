//// Open and manage IndexedDB databases.
////
//// Use `new` to create a builder, chain `add_version` calls to register
//// incremental migrations, then call `open` to connect. Each migration runs
//// only when upgrading from a lower version, so it is safe to add new versions
//// as your schema evolves without touching earlier ones.
////
//// ## Example
////
//// ```gleam
//// import glindex/database
//// import glindex/upgrade
////
//// database.new("MyApp", 2)
//// |> database.add_version(1, fn(tx) {
////   let assert Ok(store) =
////     upgrade.create_store(
////       tx,
////       "tracks",
////       upgrade.StoreOptions(
////         key_path: upgrade.KeyPath("id"),
////         auto_increment: True,
////       ),
////     )
////   let assert Ok(_) =
////     upgrade.create_index(
////       tx,
////       upgrade.index(store, "tracks_artist"),
////       upgrade.KeyPath("artist"),
////       upgrade.index_options(),
////     )
////   Nil
//// })
//// |> database.add_version(2, fn(tx) {
////   let store = upgrade.store(tx, "tracks")
////   let assert Ok(_) =
////     upgrade.delete_index(tx, upgrade.index(store, "tracks_artist"))
////   let assert Ok(_) =
////     upgrade.create_index(
////       tx,
////       upgrade.index(store, "tracks_artist_and_album"),
////       upgrade.CompositeKeyPath(["artist", "album"]),
////       upgrade.index_options(),
////     )
////   Nil
//// })
//// |> database.open(fn(result) {
////   case result {
////     Ok(db) -> use_db(db)
////     Error(_) -> Nil
////   }
//// })
//// ```

import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{type Option}
import glindex.{type Database}
import glindex/transaction

/// Errors that can occur when opening or deleting a database.
///
/// - `Blocked` - the open request was blocked by an existing connection that
///   has not been closed or upgraded yet.
/// - `VersionError` - the requested version is invalid (<= 0) or a migration
///   was registered with a duplicate or invalid version number.
/// - `UnknownError` - an unexpected browser error occurred.
///
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

/// Create a new database builder for the given name and target version.
///
/// The version must be a non zero positive integer. Use `add_version` to register
/// migrations before calling `open`.
///
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

/// Register a migration for a specific schema version.
///
/// The `migrate` callback receives a `VersionChange` transaction and is only
/// called when the database is being upgraded past `version`.
///
/// Register one call per version number, starting at `1`.
///
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

/// Register a handler called when the open request is blocked by an existing
/// connection that has not closed yet.
///
/// The handler receives the old version and the new target version.
///
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

/// Register a handler called when this connection is blocking another open
/// request that needs a higher version.
///
/// The handler receives the current version and the requested version.
/// Close the database inside this handler to unblock the pending upgrade.
///
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

/// Register a handler called when the database connection is terminated
/// unexpectedly by the browser (e.g. the storage is deleted externally).
///
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

/// Open the database, running any pending migrations, and pass the result to
/// `next`.
///
/// Returns `Error(VersionError)` immediately without touching the browser if
/// the target version is <= 0 or any migration has an invalid or duplicate
/// version number.
///
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

/// Close the database connection.
///
/// Any in-progress transactions will complete before the connection is
/// actually closed. After calling this, the `Database` handle must not be
/// used again.
///
pub fn close(db: Database) -> Nil {
  close_database(db)
}

@external(javascript, "./database_ffi.mjs", "close_database")
fn close_database(db: Database) -> Nil

/// Metadata about an existing IndexedDB database on this origin.
///
pub type DatabaseInfo {
  DatabaseInfo(name: String, version: Int)
}

/// List all IndexedDB databases available on the current origin.
///
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

/// Delete the named IndexedDB database entirely.
///
/// Returns `Error(Blocked)` if an existing connection is preventing deletion.
///
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
