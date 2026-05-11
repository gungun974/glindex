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

pub fn get(
  db: Database,
  store_ref: Store(store_type),
  index_ref: Index(store_type),
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store_ref)
  let idx = transaction.index(s, index_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.index_get(tx, idx, query, decoder, next)
    Error(e) -> next(Error(e))
  }
}

pub fn get_all(
  db: Database,
  store_ref: Store(store_type),
  index_ref: Index(store_type),
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store_ref)
  let idx = transaction.index(s, index_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.index_get_all(tx, idx, query, count, decoder, next)
    Error(e) -> next(Error(e))
  }
}

pub fn get_key(
  db: Database,
  store_ref: Store(store_type),
  index_ref: Index(store_type),
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store_ref)
  let idx = transaction.index(s, index_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.index_get_key(tx, idx, query, decoder, next)
    Error(e) -> next(Error(e))
  }
}

pub fn get_all_keys(
  db: Database,
  store_ref: Store(store_type),
  index_ref: Index(store_type),
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store_ref)
  let idx = transaction.index(s, index_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) ->
      transaction.index_get_all_keys(tx, idx, query, count, decoder, next)
    Error(e) -> next(Error(e))
  }
}

pub fn count(
  db: Database,
  store_ref: Store(store_type),
  index_ref: Index(store_type),
  query: Query,
  next: fn(Result(Int, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store_ref)
  let idx = transaction.index(s, index_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.index_count(tx, idx, query, next)
    Error(e) -> next(Error(e))
  }
}

pub fn open_cursor(
  db: Database,
  store_ref: Store(store_type),
  index_ref: Index(store_type),
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
  let #(tx, s) = transaction.store(tx, store_ref)
  let idx = transaction.index(s, index_ref)
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

pub fn open_cursor_rw(
  db: Database,
  store_ref: Store(store_type),
  index_ref: Index(store_type),
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
  let #(tx, s) = transaction.store(tx, store_ref)
  let idx = transaction.index(s, index_ref)
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

pub fn open_key_cursor(
  db: Database,
  store_ref: Store(store_type),
  index_ref: Index(store_type),
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
  let #(tx, s) = transaction.store(tx, store_ref)
  let idx = transaction.index(s, index_ref)
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

pub fn open_key_cursor_rw(
  db: Database,
  store_ref: Store(store_type),
  index_ref: Index(store_type),
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
  let #(tx, s) = transaction.store(tx, store_ref)
  let idx = transaction.index(s, index_ref)
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
