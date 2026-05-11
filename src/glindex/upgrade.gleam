import glindex.{type ReadWrite, type VersionChange}
import glindex/transaction.{
  type Transaction, type TransactionIndex, type TransactionStore,
}

pub type KeyPath {
  OutOfLineKey
  KeyPath(String)
  CompositeKeyPath(List(String))
}

pub type StoreOptions {
  StoreOptions(key_path: KeyPath, auto_increment: Bool)
}

pub type IndexOptions {
  IndexOptions(unique: Bool, multi_entry: Bool)
}

pub fn store_options() -> StoreOptions {
  StoreOptions(key_path: OutOfLineKey, auto_increment: False)
}

pub fn index_options() -> IndexOptions {
  IndexOptions(unique: False, multi_entry: False)
}

pub fn store(
  _: Transaction(ReadWrite, VersionChange),
  name: String,
) -> TransactionStore(Nil) {
  store_ffi(name)
}

@external(javascript, "./upgrade_ffi.mjs", "store")
fn store_ffi(name: String) -> TransactionStore(Nil)

pub fn index(
  store: TransactionStore(store_type),
  name: String,
) -> TransactionIndex {
  index_ffi(store, name)
}

@external(javascript, "./upgrade_ffi.mjs", "index")
fn index_ffi(
  store: TransactionStore(store_type),
  name: String,
) -> TransactionIndex

pub fn create_store(
  tx: Transaction(ReadWrite, VersionChange),
  name: String,
  options: StoreOptions,
) -> TransactionStore(Nil) {
  create_store_ffi(tx, name, options)
}

@external(javascript, "./upgrade_ffi.mjs", "create_store")
fn create_store_ffi(
  tx: Transaction(ReadWrite, VersionChange),
  name: String,
  options: StoreOptions,
) -> TransactionStore(Nil)

pub fn delete_store(
  tx: Transaction(ReadWrite, VersionChange),
  name: String,
) -> Nil {
  delete_store_ffi(tx, name)
}

@external(javascript, "./upgrade_ffi.mjs", "delete_store")
fn delete_store_ffi(
  tx: Transaction(ReadWrite, VersionChange),
  name: String,
) -> Nil

pub fn create_index(
  tx: Transaction(ReadWrite, VersionChange),
  index: TransactionIndex,
  key_path: KeyPath,
  options: IndexOptions,
) -> TransactionIndex {
  create_index_ffi(tx, index, key_path, options)
}

@external(javascript, "./upgrade_ffi.mjs", "create_index")
pub fn create_index_ffi(
  tx: Transaction(ReadWrite, VersionChange),
  index: TransactionIndex,
  key_path: KeyPath,
  options: IndexOptions,
) -> TransactionIndex

pub fn delete_index(
  tx: Transaction(ReadWrite, VersionChange),
  index: TransactionIndex,
) -> Nil {
  delete_index_ffi(tx, index)
}

@external(javascript, "./upgrade_ffi.mjs", "delete_index")
pub fn delete_index_ffi(
  tx: Transaction(ReadWrite, VersionChange),
  index: TransactionIndex,
) -> Nil
