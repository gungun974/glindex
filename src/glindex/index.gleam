//// Read operations on indexes within a transaction.
////
//// All functions accept an active `Transaction` and a `TransactionIndex` handle
//// obtained from [`glindex/transaction.index`](./transaction.html#index), and
//// return a `Promise`. Use [`glindex/transaction`](./transaction.html) to build
//// and start the transaction first.
////
//// ## Example
////
//// ```gleam
//// import gleam/javascript/promise
//// import gleam/option
//// import glindex
//// import glindex/index
//// import glindex/transaction
////
//// pub fn get_tracks_by_artist(db, artist) {
////   let tx = transaction.prepare(db, transaction.read_only)
////   let #(tx, s) = transaction.store(tx, track_store())
////   let idx = transaction.index(s, track_artist_index())
////   use tx <- promise.await(transaction.begin(tx))
////   case tx {
////     Ok(tx) -> index.get_all(tx, idx, glindex.Only(artist), option.None)
////     Error(e) -> promise.resolve(Error(e))
////   }
//// }
//// ```

import gleam/dynamic
import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
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
  index: TransactionIndex(t, k, i),
) -> #(decode.Decoder(t), decode.Decoder(k))

/// Read the first record matching `query` via `index` and decode it.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn get(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
) -> Promise(Result(t, TransactionError)) {
  get_ffi(tx, index, query)
  |> promise.map(fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, extract_index(index).0) {
          Ok(value) -> Ok(value)
          Error(errors) -> Error(UnableToDecode(errors))
        }
      Error("NotFound") -> Error(NotFoundError)
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_get")
fn get_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
) -> Promise(Result(dynamic.Dynamic, String))

/// Read the primary key of the first record matching `query` via `index`.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn get_key(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
) -> Promise(Result(k, TransactionError)) {
  get_key_ffi(tx, index, query)
  |> promise.map(fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, extract_index(index).1) {
          Ok(value) -> Ok(value)
          Error(errors) -> Error(UnableToDecode(errors))
        }
      Error("NotFound") -> Error(NotFoundError)
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_get_key")
fn get_key_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
) -> Promise(Result(dynamic.Dynamic, String))

/// Read the primary keys of all records matching `query` via `index`.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` keys.
///
pub fn get_all_keys(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
  count: option.Option(Int),
) -> Promise(Result(List(k), TransactionError)) {
  get_all_keys_ffi(tx, index, query, count)
  |> promise.map(fn(result) {
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
          Ok(values) -> Ok(values)
          Error(e) -> Error(e)
        }
      }
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_get_all_keys")
fn get_all_keys_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
  count: option.Option(Int),
) -> Promise(Result(List(dynamic.Dynamic), String))

/// Count the records matching `query` via `index`.
///
pub fn count(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
) -> Promise(Result(Int, TransactionError)) {
  count_ffi(tx, index, query)
  |> promise.map(fn(result) {
    case result {
      Ok(n) -> Ok(n)
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_count")
fn count_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
) -> Promise(Result(Int, String))

/// Read all records matching `query` via `index` and decode each one.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` records.
///
pub fn get_all(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
  count: option.Option(Int),
) -> Promise(Result(List(t), TransactionError)) {
  get_all_ffi(tx, index, query, count)
  |> promise.map(fn(result) {
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
          Ok(values) -> Ok(values)
          Error(e) -> Error(e)
        }
      }
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_get_all")
fn get_all_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
  count: option.Option(Int),
) -> Promise(Result(List(dynamic.Dynamic), String))

/// Open a full-value cursor over `index` and iterate with `handler`.
///
/// Same semantics as `store.open_cursor` but walks records sorted by the
/// index key rather than by primary key. Supports `cursor.continue_primary_key`
/// for efficient seeks within the index.
///
pub fn open_cursor(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
  direction: CursorDirection,
  initial: state,
  handler: fn(state, Cursor(WithValue, rw, IndexCursor, t, k, i)) ->
    Promise(#(state, CursorNext(IndexCursor, k, i))),
) -> Promise(Result(state, TransactionError)) {
  open_cursor_ffi(tx, index, query, direction, initial, fn(state, cursor, next) {
    handler(state, cursor)
    |> promise.map(fn(entry) { next(entry.0, entry.1) })
    Nil
  })
  |> promise.map(fn(result) {
    case result {
      Ok(state) -> Ok(state)
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_open_cursor")
fn open_cursor_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithValue, rw, IndexCursor, t, k, i),
    fn(state, CursorNext(IndexCursor, k, i)) -> Nil,
  ) -> Nil,
) -> Promise(Result(state, String))

/// Open a key-only cursor over `index` and iterate with `handler`.
///
/// Faster than `open_cursor` when you only need the index key or primary key,
/// without fetching the full record value.
///
pub fn open_key_cursor(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
  direction: CursorDirection,
  initial: state,
  handler: fn(state, Cursor(WithoutValue, rw, IndexCursor, t, k, i)) ->
    Promise(#(state, CursorNext(IndexCursor, k, i))),
) -> Promise(Result(state, TransactionError)) {
  open_key_cursor_ffi(
    tx,
    index,
    query,
    direction,
    initial,
    fn(state, cursor, next) {
      handler(state, cursor)
      |> promise.map(fn(entry) { next(entry.0, entry.1) })
      Nil
    },
  )
  |> promise.map(fn(result) {
    case result {
      Ok(state) -> Ok(state)
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_open_key_cursor")
fn open_key_cursor_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex(t, k, i),
  query: Query(i),
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithoutValue, rw, IndexCursor, t, k, i),
    fn(state, CursorNext(IndexCursor, k, i)) -> Nil,
  ) -> Nil,
) -> Promise(Result(state, String))
