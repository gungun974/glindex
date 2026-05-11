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

pub fn get(
  db: Database,
  store_ref: Store(any),
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_get(tx, s, query, decoder, next)
    Error(e) -> next(Error(e))
  }
}

pub fn get_all(
  db: Database,
  store_ref: Store(any),
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_get_all(tx, s, query, count, decoder, next)
    Error(e) -> next(Error(e))
  }
}

pub fn get_key(
  db: Database,
  store_ref: Store(any),
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_get_key(tx, s, query, decoder, next)
    Error(e) -> next(Error(e))
  }
}

pub fn get_all_keys(
  db: Database,
  store_ref: Store(any),
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_get_all_keys(tx, s, query, count, decoder, next)
    Error(e) -> next(Error(e))
  }
}

pub fn count(
  db: Database,
  store_ref: Store(any),
  query: Query,
  next: fn(Result(Int, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, store_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_count(tx, s, query, next)
    Error(e) -> next(Error(e))
  }
}

pub fn add(
  db: Database,
  store_ref: Store(any),
  value: Value,
  key_decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_add(tx, s, value, key_decoder, next)
    Error(e) -> next(Error(e))
  }
}

pub fn put(
  db: Database,
  store_ref: Store(any),
  value: Value,
  key_decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_put(tx, s, value, key_decoder, next)
    Error(e) -> next(Error(e))
  }
}

pub fn delete(
  db: Database,
  store_ref: Store(any),
  query: Query,
  next: fn(Result(Nil, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_delete(tx, s, query, next)
    Error(e) -> next(Error(e))
  }
}

pub fn clear(
  db: Database,
  store_ref: Store(any),
  next: fn(Result(Nil, TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, store_ref)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> transaction.store_clear(tx, s, next)
    Error(e) -> next(Error(e))
  }
}

pub fn open_cursor(
  db: Database,
  store_ref: Store(any),
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
  let #(tx, s) = transaction.store(tx, store_ref)
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

pub fn open_cursor_rw(
  db: Database,
  store_ref: Store(any),
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
  let #(tx, s) = transaction.store(tx, store_ref)
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

pub fn open_key_cursor(
  db: Database,
  store_ref: Store(any),
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
  let #(tx, s) = transaction.store(tx, store_ref)
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

pub fn open_key_cursor_rw(
  db: Database,
  store_ref: Store(any),
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
  let #(tx, s) = transaction.store(tx, store_ref)
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
