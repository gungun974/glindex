//// Single-index shortcuts for common read operations.
////
//// Every function in this module opens its own dedicated read-only transaction,
//// performs one index operation, and passes the result to `next`. Use these
//// when you only need to query a single index in one shot.
////
//// Because indexes are read-only in IndexedDB (you write through the store,
//// not the index), all cursor variants here are read-only by default. A
//// read-write cursor variant is provided for cases where you need to
//// delete or update records while iterating by index key.
////
//// When you need to combine index lookups with writes - for example fetching
//// records by index and then updating them - use
//// [`glindex/transaction`](./transaction.html) directly so everything runs in
//// the same transaction.
////
//// ## Example
////
//// ```gleam
//// import glindex
//// import glindex/index
////
//// use tracks <- index.get_all(
////   db,
////   track_store,
////   track_artist_index,
////   glindex.Only(glindex.string("Queen")),
////   option.None,
////   track_decoder(),
//// )
//// ```

import gleam/dynamic/decode
import gleam/option
import glindex.{
  type Database, type Index, type Query, type ReadOnly, type ReadWrite,
  type Store,
}
import glindex/cursor.{
  type Cursor, type CursorDirection, type CursorNext, type IndexCursor,
  type WithValue, type WithoutValue,
}
import glindex/transaction.{type TransactionError}

/// Read the first record matching `query` via `index`.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn get(
  db: Database,
  store: Store(store_type),
  index: Index(store_type),
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  let idx = transaction.index(s, index)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.index_get(tx, idx, query, decoder, next)
    Error(e) -> next(Error(e))
  }
}

/// Read all records matching `query` via `index`.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` records.
///
pub fn get_all(
  db: Database,
  store: Store(store_type),
  index: Index(store_type),
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  let idx = transaction.index(s, index)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.index_get_all(tx, idx, query, count, decoder, next)
    Error(e) -> next(Error(e))
  }
}

/// Read the primary key of the first record matching `query` via `index`.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn get_key(
  db: Database,
  store: Store(store_type),
  index: Index(store_type),
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  let idx = transaction.index(s, index)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.index_get_key(tx, idx, query, decoder, next)
    Error(e) -> next(Error(e))
  }
}

/// Read the primary keys of all records matching `query` via `index`.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` keys.
///
pub fn get_all_keys(
  db: Database,
  store: Store(store_type),
  index: Index(store_type),
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  let idx = transaction.index(s, index)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) ->
      transaction.index_get_all_keys(tx, idx, query, count, decoder, next)
    Error(e) -> next(Error(e))
  }
}

/// Count the records matching `query` via `index`.
///
pub fn count(
  db: Database,
  store: Store(store_type),
  index: Index(store_type),
  query: Query,
  next: fn(Result(Int, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  let idx = transaction.index(s, index)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.index_count(tx, idx, query, next)
    Error(e) -> next(Error(e))
  }
}

/// Iterate over records matching `query` via `index` with a read-only cursor.
///
/// See [`glindex/cursor`](./cursor.html) for details on the iteration model.
///
pub fn open_cursor(
  db: Database,
  store: Store(store_type),
  index: Index(store_type),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithValue, ReadOnly, IndexCursor),
    fn(state, CursorNext(IndexCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  let idx = transaction.index(s, index)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) ->
      transaction.index_open_cursor(
        tx,
        idx,
        query,
        direction,
        initial,
        handler,
        next,
      )
    Error(e) -> next(Error(e))
  }
}

/// Iterate over records matching `query` via `index` with a read-write cursor.
///
/// Allows `cursor.cursor_delete` and `cursor.cursor_update` inside the handler.
///
pub fn open_cursor_rw(
  db: Database,
  store: Store(store_type),
  index: Index(store_type),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithValue, ReadWrite, IndexCursor),
    fn(state, CursorNext(IndexCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store)
  let idx = transaction.index(s, index)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) ->
      transaction.index_open_cursor(
        tx,
        idx,
        query,
        direction,
        initial,
        handler,
        next,
      )
    Error(e) -> next(Error(e))
  }
}

/// Iterate over keys matching `query` via `index` with a read-only key cursor.
///
/// Faster than `open_cursor` when the record value is not needed.
///
pub fn open_key_cursor(
  db: Database,
  store: Store(store_type),
  index: Index(store_type),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithoutValue, ReadOnly, IndexCursor),
    fn(state, CursorNext(IndexCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  let idx = transaction.index(s, index)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) ->
      transaction.index_open_key_cursor(
        tx,
        idx,
        query,
        direction,
        initial,
        handler,
        next,
      )
    Error(e) -> next(Error(e))
  }
}

/// Iterate over keys matching `query` via `index` with a read-write key cursor.
///
pub fn open_key_cursor_rw(
  db: Database,
  store: Store(store_type),
  index: Index(store_type),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithoutValue, ReadWrite, IndexCursor),
    fn(state, CursorNext(IndexCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store)
  let idx = transaction.index(s, index)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) ->
      transaction.index_open_key_cursor(
        tx,
        idx,
        query,
        direction,
        initial,
        handler,
        next,
      )
    Error(e) -> next(Error(e))
  }
}
