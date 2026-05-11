//// Single-store shortcuts for common operations.
////
//// Every function in this module opens its own dedicated transaction, performs
//// one operation, and passes the result to `next`. Use these when you only
//// need to touch a single store in one shot and do not need to compose
//// multiple operations inside the same transaction.
////
//// When you need to perform several operations atomically - for example reading
//// a record and then writing an updated version - use
//// [`glindex/transaction`](./transaction.html) directly so that all operations
//// share the same transaction.
////
//// ## Example
////
//// ```gleam
//// import glindex
//// import glindex/store
////
//// use track <- store.get(db, track_store, glindex.Only(glindex.int(id)), track_decoder())
//// ```

import gleam/dynamic/decode
import gleam/option
import glindex.{
  type Database, type Query, type ReadOnly, type ReadWrite, type Store,
  type Value,
}
import glindex/cursor.{
  type Cursor, type CursorDirection, type CursorNext, type StoreCursor,
  type WithValue, type WithoutValue,
}
import glindex/transaction.{type TransactionError}

/// Read the first record matching `query` from `store`.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn get(
  db: Database,
  store: Store(any),
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_get(tx, s, query, decoder, next)
    Error(e) -> next(Error(e))
  }
}

/// Read all records matching `query` from `store`.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` records.
///
pub fn get_all(
  db: Database,
  store: Store(any),
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_get_all(tx, s, query, count, decoder, next)
    Error(e) -> next(Error(e))
  }
}

/// Read the primary key of the first record matching `query` in `store`.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn get_key(
  db: Database,
  store: Store(any),
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_get_key(tx, s, query, decoder, next)
    Error(e) -> next(Error(e))
  }
}

/// Read the primary keys of all records matching `query` in `store`.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` keys.
///
pub fn get_all_keys(
  db: Database,
  store: Store(any),
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_get_all_keys(tx, s, query, count, decoder, next)
    Error(e) -> next(Error(e))
  }
}

/// Count the records matching `query` in `store`.
///
pub fn count(
  db: Database,
  store: Store(any),
  query: Query,
  next: fn(Result(Int, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_count(tx, s, query, next)
    Error(e) -> next(Error(e))
  }
}

/// Insert a new record into `store` and return its generated primary key.
///
/// Returns `Error(ConstraintError)` if the key already exists.
///
pub fn add(
  db: Database,
  store: Store(any),
  value: Value,
  key_decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_add(tx, s, value, key_decoder, next)
    Error(e) -> next(Error(e))
  }
}

/// Insert or replace a record in `store` and return its primary key.
///
pub fn put(
  db: Database,
  store: Store(any),
  value: Value,
  key_decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_put(tx, s, value, key_decoder, next)
    Error(e) -> next(Error(e))
  }
}

/// Insert a new record with an explicit out-of-line key.
///
pub fn add_with_out_of_line_key(
  db: Database,
  store: Store(any),
  value: Value,
  key: Value,
  key_decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) ->
      transaction.store_add_with_out_of_line_key(
        tx,
        s,
        value,
        key,
        key_decoder,
        next,
      )
    Error(e) -> next(Error(e))
  }
}

/// Insert or replace a record with an explicit out-of-line key.
///
pub fn put_with_out_of_line_key(
  db: Database,
  store: Store(any),
  value: Value,
  key: Value,
  key_decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) ->
      transaction.store_put_with_out_of_line_key(
        tx,
        s,
        value,
        key,
        key_decoder,
        next,
      )
    Error(e) -> next(Error(e))
  }
}

/// Delete all records matching `query` from `store`.
///
pub fn delete(
  db: Database,
  store: Store(any),
  query: Query,
  next: fn(Result(Nil, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_delete(tx, s, query, next)
    Error(e) -> next(Error(e))
  }
}

/// Delete every record in `store`.
///
pub fn clear(
  db: Database,
  store: Store(any),
  next: fn(Result(Nil, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_clear(tx, s, next)
    Error(e) -> next(Error(e))
  }
}

/// Iterate over records matching `query` in `store` with a read-only cursor.
///
/// See [`glindex/cursor`](./cursor.html) for details on the iteration model.
///
pub fn open_cursor(
  db: Database,
  store: Store(any),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithValue, ReadOnly, StoreCursor),
    fn(state, CursorNext(StoreCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) ->
      transaction.store_open_cursor(
        tx,
        s,
        query,
        direction,
        initial,
        handler,
        next,
      )
    Error(e) -> next(Error(e))
  }
}

/// Iterate over records matching `query` in `store` with a read-write cursor.
///
/// Allows `cursor.cursor_delete` and `cursor.cursor_update` inside the handler.
///
pub fn open_cursor_rw(
  db: Database,
  store: Store(any),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithValue, ReadWrite, StoreCursor),
    fn(state, CursorNext(StoreCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) ->
      transaction.store_open_cursor(
        tx,
        s,
        query,
        direction,
        initial,
        handler,
        next,
      )
    Error(e) -> next(Error(e))
  }
}

/// Iterate over keys matching `query` in `store` with a read-only key cursor.
///
/// Faster than `open_cursor` when the record value is not needed.
///
pub fn open_key_cursor(
  db: Database,
  store: Store(any),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithoutValue, ReadOnly, StoreCursor),
    fn(state, CursorNext(StoreCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) ->
      transaction.store_open_key_cursor(
        tx,
        s,
        query,
        direction,
        initial,
        handler,
        next,
      )
    Error(e) -> next(Error(e))
  }
}

/// Iterate over keys matching `query` in `store` with a read-write key cursor.
///
pub fn open_key_cursor_rw(
  db: Database,
  store: Store(any),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithoutValue, ReadWrite, StoreCursor),
    fn(state, CursorNext(StoreCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) ->
      transaction.store_open_key_cursor(
        tx,
        s,
        query,
        direction,
        initial,
        handler,
        next,
      )
    Error(e) -> next(Error(e))
  }
}
