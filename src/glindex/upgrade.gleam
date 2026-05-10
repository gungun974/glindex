import glindex.{type ReadWrite, type VersionChange}
import glindex/transaction.{
  type Transaction, type TransactionIndex, type TransactionStore,
}

pub type KeyPath {
  NoKeyPath
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
  StoreOptions(key_path: NoKeyPath, auto_increment: False)
}

pub fn index_options() -> IndexOptions {
  IndexOptions(unique: False, multi_entry: False)
}

pub fn store(
  tx: Transaction(ReadWrite, VersionChange),
  name: String,
) -> TransactionStore(Nil) {
  todo
}

pub fn index(
  store: TransactionStore(store_type),
  name: String,
) -> TransactionIndex {
  todo
}

pub fn create_store(
  tx: Transaction(ReadWrite, VersionChange),
  name: String,
  options: StoreOptions,
) -> TransactionStore(Nil) {
  todo
}

pub fn delete_store(
  tx: Transaction(ReadWrite, VersionChange),
  name: String,
) -> Nil {
  todo
}

pub fn create_index(
  tx: Transaction(ReadWrite, VersionChange),
  index: TransactionIndex,
  key_path: KeyPath,
  options: IndexOptions,
) -> Nil {
  todo
}

pub fn delete_index(
  tx: Transaction(ReadWrite, VersionChange),
  index: TransactionIndex,
) -> Nil {
  todo
}
