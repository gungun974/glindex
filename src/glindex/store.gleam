import gleam/dynamic
import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option
import glindex.{type Query, type ReadWrite, type Value}
import glindex/cursor.{
  type Cursor, type CursorDirection, type CursorNext, type StoreCursor,
  type WithValue, type WithoutValue,
}
import glindex/transaction.{
  type Transaction, type TransactionError, type TransactionStore,
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

@external(javascript, "./transaction_ffi.mjs", "extract_store")
fn extract_store(store: TransactionStore(any, t, k)) -> glindex.Store(any, t, k)

/// Read the first record matching `query` from `store` and decode it.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn get(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
) -> Promise(Result(t, TransactionError)) {
  get_ffi(tx, store, query)
  |> promise.map(fn(result) {
    case result {
      Ok(raw) -> {
        case decode.run(raw, extract_store(store).decoder) {
          Ok(value) -> Ok(value)
          Error(errors) -> Error(UnableToDecode(errors))
        }
      }
      Error("NotFound") -> Error(NotFoundError)
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_get")
fn get_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
) -> Promise(Result(dynamic.Dynamic, String))

/// Read all records matching `query` from `store` and decode each one.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` records.
///
pub fn get_all(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
  count: option.Option(Int),
) -> Promise(Result(List(t), TransactionError)) {
  get_all_ffi(tx, store, query, count)
  |> promise.map(fn(result) {
    case result {
      Ok(raws) -> {
        let decoded =
          list.try_map(raws, fn(raw) {
            case decode.run(raw, extract_store(store).decoder) {
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

@external(javascript, "./transaction_ffi.mjs", "store_get_all")
fn get_all_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
  count: option.Option(Int),
) -> Promise(Result(List(dynamic.Dynamic), String))

/// Read the primary key of the first record matching `query` in `store`.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn get_key(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
) -> Promise(Result(k, TransactionError)) {
  get_key_ffi(tx, store, query)
  |> promise.map(fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, extract_store(store).key_decoder) {
          Ok(value) -> Ok(value)
          Error(errors) -> Error(UnableToDecode(errors))
        }
      Error("NotFound") -> Error(NotFoundError)
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_get_key")
fn get_key_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
) -> Promise(Result(dynamic.Dynamic, String))

/// Read the primary keys of all records matching `query` in `store`.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` keys.
///
pub fn get_all_keys(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
  count: option.Option(Int),
) -> Promise(Result(List(k), TransactionError)) {
  get_all_keys_ffi(tx, store, query, count)
  |> promise.map(fn(result) {
    case result {
      Ok(raws) -> {
        let decoded =
          list.try_map(raws, fn(raw) {
            case decode.run(raw, extract_store(store).key_decoder) {
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

@external(javascript, "./transaction_ffi.mjs", "store_get_all_keys")
fn get_all_keys_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
  count: option.Option(Int),
) -> Promise(Result(List(dynamic.Dynamic), String))

/// Count the records matching `query` in `store`.
///
pub fn count(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
) -> Promise(Result(Int, TransactionError)) {
  count_ffi(tx, store, query)
  |> promise.map(fn(result) {
    case result {
      Ok(n) -> Ok(n)
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_count")
fn count_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
) -> Promise(Result(Int, String))

/// Insert a new record into `store` and return its generated primary key.
///
/// Returns `Error(ConstraintError)` if the record's key already exists and
/// the store does not allow duplicates.
///
pub fn add(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any, t, k),
  value: t,
) -> Promise(Result(k, TransactionError)) {
  let store_config = extract_store(store)
  add_ffi(tx, store, store_config.to_value(value, glindex.Add))
  |> promise.map(fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, store_config.key_decoder) {
          Ok(key) -> Ok(key)
          Error(errors) -> Error(UnableToDecode(errors))
        }
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_add")
fn add_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any, t, k),
  value: Value,
) -> Promise(Result(dynamic.Dynamic, String))

/// Insert or replace a record in `store` and return its primary key.
///
/// If a record with the same key already exists it is overwritten. Use
/// `add` instead when you want an error on duplicate keys.
///
pub fn put(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any, t, k),
  value: t,
) -> Promise(Result(k, TransactionError)) {
  let store_config = extract_store(store)
  put_ffi(tx, store, store_config.to_value(value, glindex.Put))
  |> promise.map(fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, store_config.key_decoder) {
          Ok(key) -> Ok(key)
          Error(errors) -> Error(UnableToDecode(errors))
        }
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_put")
fn put_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any, t, k),
  value: Value,
) -> Promise(Result(dynamic.Dynamic, String))

/// Insert a new record with an explicit out-of-line key.
///
/// Use this when the store was created with `OutOfLineKey` and you manage
/// keys yourself rather than letting IndexedDB generate them.
///
pub fn add_with_out_of_line_key(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any, t, k),
  value: t,
  key: Value,
) -> Promise(Result(k, TransactionError)) {
  let store_config = extract_store(store)
  add_with_out_of_line_key_ffi(
    tx,
    store,
    store_config.to_value(value, glindex.AddOutOfLineKey),
    key,
  )
  |> promise.map(fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, store_config.key_decoder) {
          Ok(k) -> Ok(k)
          Error(errors) -> Error(UnableToDecode(errors))
        }
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_add_with_out_of_line_key")
fn add_with_out_of_line_key_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any, t, k),
  value: Value,
  key: Value,
) -> Promise(Result(dynamic.Dynamic, String))

/// Insert or replace a record with an explicit out-of-line key.
///
pub fn put_with_out_of_line_key(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any, t, k),
  value: t,
  key: Value,
) -> Promise(Result(k, TransactionError)) {
  let store_config = extract_store(store)
  put_with_out_of_line_key_ffi(
    tx,
    store,
    store_config.to_value(value, glindex.Put),
    key,
  )
  |> promise.map(fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, store_config.key_decoder) {
          Ok(k) -> Ok(k)
          Error(errors) -> Error(UnableToDecode(errors))
        }
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_put_with_out_of_line_key")
fn put_with_out_of_line_key_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any, t, k),
  value: Value,
  key: Value,
) -> Promise(Result(dynamic.Dynamic, String))

/// Delete all records matching `query` from `store`.
///
pub fn delete(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
) -> Promise(Result(Nil, TransactionError)) {
  delete_ffi(tx, store, query)
  |> promise.map(fn(result) {
    case result {
      Ok(_) -> Ok(Nil)
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_delete")
fn delete_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
) -> Promise(Result(Nil, String))

/// Delete every record in `store`.
///
pub fn clear(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any, t, k),
) -> Promise(Result(Nil, TransactionError)) {
  clear_ffi(tx, store)
  |> promise.map(fn(result) {
    case result {
      Ok(_) -> Ok(Nil)
      Error(name) -> Error(map_error(name))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_clear")
fn clear_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any, t, k),
) -> Promise(Result(Nil, String))

/// Open a full-value cursor over `store` and iterate with `handler`.
///
/// The `initial` value seeds the accumulator. The `handler` receives the
/// current accumulator, the cursor, and a `next` continuation. Call
/// `cursor.continue()` to advance, `cursor.stop()` to finish early, or
/// `cursor.advance(n)` to skip records.
///
/// On a `ReadWrite` transaction the cursor also supports `cursor.cursor_delete`
/// and `cursor.cursor_update`.
///
pub fn open_cursor(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(state, Cursor(WithValue, rw, StoreCursor)) ->
    Promise(#(state, CursorNext(StoreCursor))),
) -> Promise(Result(state, TransactionError)) {
  open_cursor_ffi(tx, store, query, direction, initial, fn(state, cursor, next) {
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

@external(javascript, "./transaction_ffi.mjs", "store_open_cursor")
fn open_cursor_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithValue, rw, StoreCursor),
    fn(state, CursorNext(StoreCursor)) -> Nil,
  ) -> Nil,
) -> Promise(Result(state, String))

/// Open a key-only cursor over `store` and iterate with `handler`.
///
/// Faster than `store_open_cursor` when you only need the key (e.g. for
/// counting or deleting by key). The cursor does not carry the record value,
/// so `cursor_value` is not available.
///
pub fn open_key_cursor(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(state, Cursor(WithoutValue, rw, StoreCursor)) ->
    Promise(#(state, CursorNext(StoreCursor))),
) -> Promise(Result(state, TransactionError)) {
  open_key_cursor_ffi(
    tx,
    store,
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

@external(javascript, "./transaction_ffi.mjs", "store_open_key_cursor")
fn open_key_cursor_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any, t, k),
  query: Query,
  direction: CursorDirection,
  initial: state,
  handler: fn(
    state,
    Cursor(WithoutValue, rw, StoreCursor),
    fn(state, CursorNext(StoreCursor)) -> Nil,
  ) -> Nil,
) -> Promise(Result(state, String))
