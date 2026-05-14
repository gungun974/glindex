//// Schema migration operations for IndexedDB.
////
//// All functions in this module are only meaningful inside a `VersionChange`
//// transaction, which is provided to each callback registered with
//// [`glindex/database.add_version`](./database.html#add_version).
////
//// All store and index operations of [`glindex/transaction`](./glindex/transaction.html) do work inside a `VersionChange`
////
//// A typical migration creates stores and indexes:
////
//// ```gleam
//// database.add_version(1, fn(tx) {
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
//// ```
////
//// Later versions can modify the schema without touching earlier migrations:
////
//// ```gleam
//// database.add_version(2, fn(tx) {
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
//// ```

///
import gleam/result
import glindex.{type ReadWrite, type VersionChange}
import glindex/transaction.{
  type Transaction, type TransactionIndex, type TransactionStore,
}

/// Describes how the primary key is extracted from a stored object.
///
/// - `OutOfLineKey` - the key is stored separately and must be supplied
///   explicitly via `store_add_with_out_of_line_key` /
///   `store_put_with_out_of_line_key`.
/// - `KeyPath(field)` - the key is a property of the stored object.
/// - `CompositeKeyPath(fields)` - the key is an array built from multiple
///   properties, useful for compound indexes.
///
pub type KeyPath {
  OutOfLineKey
  KeyPath(String)
  CompositeKeyPath(List(String))
}

/// Options passed to `create_store`.
///
/// - `key_path` - see `KeyPath`.
/// - `auto_increment` - when `True`, IndexedDB generates an integer key
///   automatically for each new record. Usually combined with
///   `KeyPath("id")`.
///
pub type StoreOptions {
  StoreOptions(key_path: KeyPath, auto_increment: Bool)
}

/// Options passed to `create_index`.
///
/// - `unique` - when `True`, IndexedDB rejects records whose indexed value
///   duplicates an existing key.
/// - `multi_entry` - when `True` and the indexed property is an array,
///   each element of the array is indexed separately.
///
pub type IndexOptions {
  IndexOptions(unique: Bool, multi_entry: Bool)
}

/// Errors that can occur during schema migration operations.
///
/// - `ConstraintError` - a store or index with that name already exists.
/// - `InvalidStateError` - the transaction is not in a valid state for this operation.
/// - `NotFoundError` - the store or index does not exist.
/// - `UnknownError` - an unexpected browser error occurred.
///
pub type UpgradeError {
  ConstraintError
  InvalidStateError
  NotFoundError
  UnknownError(String)
}

fn map_error(name: String) -> UpgradeError {
  case name {
    "ConstraintError" -> ConstraintError
    "InvalidStateError" -> InvalidStateError
    "NotFoundError" -> NotFoundError
    _ -> UnknownError(name)
  }
}

/// Default `StoreOptions`: out-of-line key, no auto-increment.
///
pub fn store_options() -> StoreOptions {
  StoreOptions(key_path: OutOfLineKey, auto_increment: False)
}

/// Default `IndexOptions`: non-unique, single-entry.
///
pub fn index_options() -> IndexOptions {
  IndexOptions(unique: False, multi_entry: False)
}

/// Get a handle to an existing object store by name inside a migration.
///
/// Use this in later version migrations to access a store that was created in
/// an earlier migration so you can modify its indexes.
///
pub fn store(
  _: Transaction(ReadWrite, VersionChange),
  name: String,
) -> TransactionStore(Nil, Nil, Nil) {
  store_ffi(name)
}

@external(javascript, "./upgrade_ffi.mjs", "store")
fn store_ffi(name: String) -> TransactionStore(Nil, Nil, Nil)

/// Get a handle to an existing index by name on the given store.
///
pub fn index(
  store: TransactionStore(store_type, t, k),
  name: String,
) -> TransactionIndex(t, k, i) {
  index_ffi(store, name)
}

@external(javascript, "./upgrade_ffi.mjs", "index")
fn index_ffi(
  store: TransactionStore(store_type, t, k),
  name: String,
) -> TransactionIndex(t, k, i)

/// Create a new object store and return a handle to it.
///
/// Must be called inside a `VersionChange` transaction. The `name` must be
/// unique among all stores in the database.
///
pub fn create_store(
  tx: Transaction(ReadWrite, VersionChange),
  name: String,
  options: StoreOptions,
) -> Result(TransactionStore(Nil, t, k), UpgradeError) {
  create_store_ffi(tx, name, options) |> result.map_error(map_error)
}

@external(javascript, "./upgrade_ffi.mjs", "create_store")
fn create_store_ffi(
  tx: Transaction(ReadWrite, VersionChange),
  name: String,
  options: StoreOptions,
) -> Result(TransactionStore(Nil, t, k), String)

/// Delete an existing object store and all records it contains.
///
pub fn delete_store(
  tx: Transaction(ReadWrite, VersionChange),
  name: String,
) -> Result(Nil, UpgradeError) {
  delete_store_ffi(tx, name) |> result.map_error(map_error)
}

@external(javascript, "./upgrade_ffi.mjs", "delete_store")
fn delete_store_ffi(
  tx: Transaction(ReadWrite, VersionChange),
  name: String,
) -> Result(Nil, String)

/// Create a new index on an object store and return a handle to it.
///
/// The `index` argument is a `TransactionIndex` obtained from `upgrade.index`
/// with the desired name, not from `transaction.index`.
///
pub fn create_index(
  tx: Transaction(ReadWrite, VersionChange),
  index: TransactionIndex(t, k, i),
  key_path: KeyPath,
  options: IndexOptions,
) -> Result(TransactionIndex(t, k, i), UpgradeError) {
  create_index_ffi(tx, index, key_path, options) |> result.map_error(map_error)
}

@external(javascript, "./upgrade_ffi.mjs", "create_index")
fn create_index_ffi(
  tx: Transaction(ReadWrite, VersionChange),
  index: TransactionIndex(t, k, i),
  key_path: KeyPath,
  options: IndexOptions,
) -> Result(TransactionIndex(t, k, i), String)

/// Delete an existing index from its object store.
///
pub fn delete_index(
  tx: Transaction(ReadWrite, VersionChange),
  index: TransactionIndex(t, k, i),
) -> Result(Nil, UpgradeError) {
  delete_index_ffi(tx, index) |> result.map_error(map_error)
}

@external(javascript, "./upgrade_ffi.mjs", "delete_index")
fn delete_index_ffi(
  tx: Transaction(ReadWrite, VersionChange),
  index: TransactionIndex(t, k, i),
) -> Result(Nil, String)

/// Return the key path configuration of a store.
///
pub fn store_key_path(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
) -> Result(KeyPath, UpgradeError) {
  store_key_path_ffi(tx, store) |> result.map_error(map_error)
}

@external(javascript, "./upgrade_ffi.mjs", "store_key_path")
fn store_key_path_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
) -> Result(KeyPath, String)

/// Return whether the store uses auto-incrementing keys.
///
pub fn store_auto_increment(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
) -> Result(Bool, UpgradeError) {
  store_auto_increment_ffi(tx, store) |> result.map_error(map_error)
}

@external(javascript, "./upgrade_ffi.mjs", "store_auto_increment")
fn store_auto_increment_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
) -> Result(Bool, String)

/// Return the key path configuration of an index.
///
pub fn index_key_path(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
) -> Result(KeyPath, UpgradeError) {
  index_key_path_ffi(tx, index) |> result.map_error(map_error)
}

@external(javascript, "./upgrade_ffi.mjs", "index_key_path")
fn index_key_path_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
) -> Result(KeyPath, String)

/// Return whether the index enforces uniqueness.
///
pub fn index_unique(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
) -> Result(Bool, UpgradeError) {
  index_unique_ffi(tx, index) |> result.map_error(map_error)
}

@external(javascript, "./upgrade_ffi.mjs", "index_unique")
fn index_unique_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
) -> Result(Bool, String)

/// Return whether the index uses multi-entry mode.
///
pub fn index_multi_entry(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
) -> Result(Bool, UpgradeError) {
  index_multi_entry_ffi(tx, index) |> result.map_error(map_error)
}

@external(javascript, "./upgrade_ffi.mjs", "index_multi_entry")
fn index_multi_entry_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
) -> Result(Bool, String)

/// Rename an object store. Returns a handle with the new name.
///
pub fn rename_store(
  tx: Transaction(ReadWrite, VersionChange),
  store: TransactionStore(any, t, k),
  new_name: String,
) -> Result(TransactionStore(Nil, t, k), UpgradeError) {
  rename_store_ffi(tx, store, new_name) |> result.map_error(map_error)
}

@external(javascript, "./upgrade_ffi.mjs", "rename_store")
fn rename_store_ffi(
  tx: Transaction(ReadWrite, VersionChange),
  store: TransactionStore(any, t, k),
  new_name: String,
) -> Result(TransactionStore(Nil, t, k), String)

/// Rename an index. Returns a handle with the new name.
///
pub fn rename_index(
  tx: Transaction(ReadWrite, VersionChange),
  index: TransactionIndex(t, k, i),
  new_name: String,
) -> Result(TransactionIndex(t, k, i), UpgradeError) {
  rename_index_ffi(tx, index, new_name) |> result.map_error(map_error)
}

@external(javascript, "./upgrade_ffi.mjs", "rename_index")
fn rename_index_ffi(
  tx: Transaction(ReadWrite, VersionChange),
  index: TransactionIndex(t, k, i),
  new_name: String,
) -> Result(TransactionIndex(t, k, i), String)

/// Return the names of all object stores in the database.
///
pub fn object_store_names(tx: Transaction(rw, upgrade)) -> List(String) {
  object_store_names_ffi(tx)
}

@external(javascript, "./upgrade_ffi.mjs", "object_store_names")
fn object_store_names_ffi(tx: Transaction(rw, upgrade)) -> List(String)

/// Return the names of all indexes on the given store.
///
pub fn index_names(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
) -> Result(List(String), UpgradeError) {
  index_names_ffi(tx, store) |> result.map_error(map_error)
}

@external(javascript, "./upgrade_ffi.mjs", "index_names")
fn index_names_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
) -> Result(List(String), String)
