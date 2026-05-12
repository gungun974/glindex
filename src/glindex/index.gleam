import gleam/dynamic
import gleam/dynamic/decode
import gleam/list
import gleam/option
import glindex.{type Query}
import glindex/cursor.{
  type Cursor, type CursorDirection, type CursorNext, type IndexCursor,
  type WithValue, type WithoutValue,
}
import glindex/transaction.{
  type Transaction, type TransactionError, type TransactionIndex,
  ConstraintError, DataError, InvalidStateError, NotFoundError,
  QuotaExceededError, TransactionInactiveError, UnableToDecode, UnknownError,
}

fn map_error(name: String) -> TransactionError {
  case name {
    "ConstraintError" -> ConstraintError
    "DataError" -> DataError
    "InvalidStateError" -> InvalidStateError
    "QuotaExceededError" -> QuotaExceededError
    "TransactionInactiveError" -> TransactionInactiveError
    _ -> UnknownError(name)
  }
}

@external(javascript, "./transaction_ffi.mjs", "extract_index")
fn extract_index(
  index: TransactionIndex(t, k),
) -> #(decode.Decoder(t), decode.Decoder(k))

/// Read the first record matching `query` via `index` and decode it.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn get(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  get_ffi(tx, index, query, fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, extract_index(index).0) {
          Ok(value) -> next(Ok(value))
          Error(errors) -> next(Error(UnableToDecode(errors)))
        }
      Error("NotFound") -> next(Error(NotFoundError))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_get")
fn get_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  next: fn(Result(dynamic.Dynamic, String)) -> a,
) -> a

/// Read the primary key of the first record matching `query` via `index`.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn get_key(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  next: fn(Result(k, TransactionError)) -> a,
) -> a {
  get_key_ffi(tx, index, query, fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, extract_index(index).1) {
          Ok(value) -> next(Ok(value))
          Error(errors) -> next(Error(UnableToDecode(errors)))
        }
      Error("NotFound") -> next(Error(NotFoundError))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_get_key")
fn get_key_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  next: fn(Result(dynamic.Dynamic, String)) -> a,
) -> a

/// Read the primary keys of all records matching `query` via `index`.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` keys.
///
pub fn get_all_keys(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  count: option.Option(Int),
  next: fn(Result(List(k), TransactionError)) -> a,
) -> a {
  get_all_keys_ffi(tx, index, query, count, fn(result) {
    case result {
      Ok(raws) -> {
        let decoded =
          list.try_map(raws, fn(raw) {
            case decode.run(raw, extract_index(index).1) {
              Ok(v) -> Ok(v)
              Error(e) -> Error(UnableToDecode(e))
            }
          })
        case decoded {
          Ok(values) -> next(Ok(values))
          Error(e) -> next(Error(e))
        }
      }
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_get_all_keys")
fn get_all_keys_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  count: option.Option(Int),
  next: fn(Result(List(dynamic.Dynamic), String)) -> a,
) -> a

/// Count the records matching `query` via `index`.
///
pub fn count(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  next: fn(Result(Int, TransactionError)) -> a,
) -> a {
  count_ffi(tx, index, query, fn(result) {
    case result {
      Ok(n) -> next(Ok(n))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_count")
fn count_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  next: fn(Result(Int, String)) -> a,
) -> a

/// Read all records matching `query` via `index` and decode each one.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` records.
///
pub fn get_all(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  count: option.Option(Int),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  get_all_ffi(tx, index, query, count, fn(result) {
    case result {
      Ok(raws) -> {
        let decoded =
          list.try_map(raws, fn(raw) {
            case decode.run(raw, extract_index(index).0) {
              Ok(v) -> Ok(v)
              Error(e) -> Error(UnableToDecode(e))
            }
          })
        case decoded {
          Ok(values) -> next(Ok(values))
          Error(e) -> next(Error(e))
        }
      }
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_get_all")
fn get_all_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  count: option.Option(Int),
  next: fn(Result(List(dynamic.Dynamic), String)) -> a,
) -> a

/// Open a full-value cursor over `index` and iterate with `handler`.
///
/// Same semantics as `store_open_cursor` but walks records sorted by the
/// index key rather than by primary key.
///
pub fn open_cursor(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithValue, rw, IndexCursor),
    fn(state, CursorNext(IndexCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  open_cursor_ffi(tx, index, query, direction, initial, handler, fn(result) {
    case result {
      Ok(state) -> next(Ok(state))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_open_cursor")
fn open_cursor_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithValue, rw, IndexCursor),
    fn(state, CursorNext(IndexCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, String)) -> a,
) -> a

/// Open a key-only cursor over `index` and iterate with `handler`.
///
/// Faster than `index_open_cursor` when only the index key or primary key is
/// needed.
///
pub fn open_key_cursor(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithoutValue, rw, IndexCursor),
    fn(state, CursorNext(IndexCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  open_key_cursor_ffi(tx, index, query, direction, initial, handler, fn(result) {
    case result {
      Ok(state) -> next(Ok(state))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_open_key_cursor")
fn open_key_cursor_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithoutValue, rw, IndexCursor),
    fn(state, CursorNext(IndexCursor)) -> Nil,
  ) -> Nil,
  next: fn(Result(state, String)) -> a,
) -> a
