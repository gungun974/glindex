import gleam/dynamic/decode
import gleam/option
import glindex.{
  type Database, type IdbError, type Normal, type Query, type ReadOnly,
  type ReadWrite, type Value,
}
import glindex/cursor.{
  type Cursor, type CursorDirection, type CursorNext, type IndexCursor,
  type StoreCursor, type WithValue, type WithoutValue,
}
import glindex/index.{type Index}
import glindex/store.{type Store}

pub type TransactionMode(readonly) {
  TransactionReadOnly
  TransactionReadWrite
}

pub const read_only: TransactionMode(ReadOnly) = TransactionReadOnly

pub const read_write: TransactionMode(ReadWrite) = TransactionReadWrite

pub type TransactionBuilder(readonly)

pub type Transaction(readonly, upgrade)

pub type TransactionStore(store_type)

pub type TransactionIndex

pub fn prepare(
  db: Database,
  mode: TransactionMode(readonly),
) -> TransactionBuilder(readonly) {
  todo
}

pub fn store(
  builder: TransactionBuilder(readonly),
  store: Store(store_type),
) -> #(TransactionBuilder(readonly), TransactionStore(store_type)) {
  todo
}

pub fn index(
  store: TransactionStore(store_type),
  name: Index(store_type),
) -> TransactionIndex {
  todo
}

pub fn begin(
  builder: TransactionBuilder(readonly),
  next: fn(Result(Transaction(readonly, Normal), IdbError)) -> a,
) -> a {
  todo
}

pub fn abort(tx: Transaction(rw, upgrade)) -> Nil {
  todo
}

pub fn commit(tx: Transaction(rw, upgrade)) -> Nil {
  todo
}

pub fn store_get(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, IdbError)) -> a,
) -> a {
  todo
}

pub fn store_get_all(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), IdbError)) -> a,
) -> a {
  todo
}

pub fn store_get_key(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, IdbError)) -> a,
) -> a {
  todo
}

pub fn store_get_all_keys(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), IdbError)) -> a,
) -> a {
  todo
}

pub fn store_count(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  next: fn(Result(Int, IdbError)) -> a,
) -> a {
  todo
}

pub fn store_add(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  value: Value,
  key_decoder: decode.Decoder(t),
  next: fn(Result(t, IdbError)) -> a,
) -> a {
  todo
}

pub fn store_put(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  value: Value,
  key_decoder: decode.Decoder(t),
  next: fn(Result(t, IdbError)) -> a,
) -> a {
  todo
}

pub fn store_delete(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  query: Query,
  next: fn(Result(Nil, IdbError)) -> a,
) -> a {
  todo
}

pub fn store_clear(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  next: fn(Result(Nil, IdbError)) -> a,
) -> a {
  todo
}

pub fn index_get(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, IdbError)) -> a,
) -> a {
  todo
}

pub fn index_get_key(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, IdbError)) -> a,
) -> a {
  todo
}

pub fn index_get_all_keys(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), IdbError)) -> a,
) -> a {
  todo
}

pub fn index_count(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  next: fn(Result(Int, IdbError)) -> a,
) -> a {
  todo
}

pub fn index_get_all(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), IdbError)) -> a,
) -> a {
  todo
}

pub fn store_open_cursor(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithValue, rw, StoreCursor),
    fn(state, CursorNext(StoreCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, IdbError)) -> a,
) -> a {
  todo
}

pub fn index_open_cursor(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithValue, rw, IndexCursor),
    fn(state, CursorNext(IndexCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, IdbError)) -> a,
) -> a {
  todo
}

pub fn store_open_key_cursor(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithoutValue, rw, StoreCursor),
    fn(state, CursorNext(StoreCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, IdbError)) -> a,
) -> a {
  todo
}

pub fn index_open_key_cursor(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithoutValue, rw, IndexCursor),
    fn(state, CursorNext(IndexCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, IdbError)) -> a,
) -> a {
  todo
}
