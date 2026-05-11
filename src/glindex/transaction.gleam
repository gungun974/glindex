//// Classic IndexedDB-style transactions over one or more object stores.
////
//// All database operations run inside a transaction. Build one with
//// `prepare`, register the stores you need with `store`, then call `begin`
//// to start it. Every operation takes a `next` continuation so calls chain
//// naturally with Gleam's `use` syntax.
////
//// ## Example
////
//// ```gleam
//// import glindex
//// import glindex/transaction
////
//// pub fn get_track(db, id, next) {
////   let tx = transaction.prepare(db, transaction.read_only)
////   let #(tx, store) = transaction.store(tx, track_store)
////   use tx <- transaction.begin(tx)
////   case tx {
////     Ok(tx) -> {
////       use result <- transaction.store_get(
////         tx,
////         store,
////         glindex.Only(glindex.int(id)),
////         track_decoder(),
////       )
////       next(result)
////     }
////     Error(e) -> next(Error(e))
////   }
//// }
//// ```
////
//// IndexedDB auto-commits a transaction as soon as no more requests are
//// pending, so you generally do not need to call `commit` explicitly. Call
//// `abort` to roll back all changes made in the transaction.

import gleam/dynamic
import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option}
import glindex.{
  type Database, type Index, type Normal, type Query, type ReadOnly,
  type ReadWrite, type Store, type Value,
}
import glindex/cursor.{
  type Cursor, type CursorDirection, type CursorNext, type IndexCursor,
  type StoreCursor, type WithValue, type WithoutValue,
}

/// The access mode of a transaction, carried as a phantom type.
///
/// Use the pre-built constants `read_only` and `read_write` instead of
/// constructing these directly.
///
pub type TransactionMode(readonly) {
  TransactionReadOnly
  TransactionReadWrite
}

/// Pre-built constant for a read-only transaction.
///
/// Multiple read-only transactions can run concurrently; prefer this mode
/// whenever you do not need to write.
///
pub const read_only: TransactionMode(ReadOnly) = TransactionReadOnly

/// Pre-built constant for a read-write transaction.
///
pub const read_write: TransactionMode(ReadWrite) = TransactionReadWrite

pub type TransactionBuilder(readonly)

/// Durability hint passed to the browser when creating the transaction.
///
/// - `DurabilityDefault` - let the browser choose.
/// - `DurabilityStrict` - guarantee writes are flushed to disk before
///   `on_complete` fires (slower, safer).
/// - `DurabilityRelaxed` - allow the OS to decide when to flush (faster,
///   risks data loss on power failure).
///
pub type TransactionDurability {
  DurabilityDefault
  DurabilityStrict
  DurabilityRelaxed
}

/// Handle to an active transaction.
///
pub type Transaction(readonly, upgrade)

/// Handle to an object store obtained after `store` is called on a builder.
///
/// The phantom type `store_type` must match the `Store` used to obtain it,
/// preventing indexes from one store being used with another store's handle.
///
pub type TransactionStore(store_type)

/// Handle to an index obtained via `transaction.index`.
///
pub type TransactionIndex

/// Errors returned by store and index operations.
///
/// - `ConstraintError` - a uniqueness constraint was violated.
/// - `DataError` - the key or value was invalid for the operation.
/// - `InvalidStateError` - the transaction or store is in an unexpected state.
/// - `NotFoundError` - no record matched the query.
/// - `QuotaExceededError` - the browser's storage quota has been reached.
/// - `TransactionInactiveError` - the transaction has already committed or aborted.
/// - `UnableToDecode` - the record was found but the decoder failed.
/// - `UnknownError` - an unexpected browser error occurred.
///
pub type TransactionError {
  ConstraintError
  DataError
  InvalidStateError
  NotFoundError
  QuotaExceededError
  TransactionInactiveError
  UnableToDecode(List(decode.DecodeError))
  UnknownError(String)
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

/// Create a transaction builder for the given database and access mode.
///
/// Chain `store` calls to register every store you will access, then call
/// `begin` to start the transaction.
///
pub fn prepare(
  db: Database,
  mode: TransactionMode(readonly),
) -> TransactionBuilder(readonly) {
  prepare_ffi(db, case mode {
    TransactionReadOnly -> "readonly"
    TransactionReadWrite -> "readwrite"
  })
}

@external(javascript, "./transaction_ffi.mjs", "prepare")
fn prepare_ffi(db: Database, mode: String) -> TransactionBuilder(readonly)

/// Register an object store on the builder and receive a typed handle.
///
/// Returns a tuple of `#(builder, store_handle)`.
///
/// ```gleam
/// let tx = transaction.prepare(db, transaction.read_write)
/// let #(tx, tracks) = transaction.store(tx, track_store)
/// let #(tx, artists) = transaction.store(tx, artist_store)
/// use tx <- transaction.begin(tx)
/// ```
///
pub fn store(
  builder: TransactionBuilder(readonly),
  store: Store(store_type),
) -> #(TransactionBuilder(readonly), TransactionStore(store_type)) {
  store_ffi(builder, store)
}

@external(javascript, "./transaction_ffi.mjs", "store")
fn store_ffi(
  builder: TransactionBuilder(readonly),
  store: Store(store_type),
) -> #(TransactionBuilder(readonly), TransactionStore(store_type))

/// Obtain an index handle from a store handle.
///
/// The `Index(store_type)` and `TransactionStore(store_type)` must share the
/// same phantom type.
///
pub fn index(
  store: TransactionStore(store_type),
  name: Index(store_type),
) -> TransactionIndex {
  index_ffi(store, name)
}

@external(javascript, "./transaction_ffi.mjs", "index")
fn index_ffi(
  store: TransactionStore(store_type),
  name: Index(store_type),
) -> TransactionIndex

/// Set the durability hint for the transaction.
///
pub fn with_durability(
  builder: TransactionBuilder(readonly),
  durability: TransactionDurability,
) -> TransactionBuilder(readonly) {
  with_durability_ffi(builder, case durability {
    DurabilityDefault -> "default"
    DurabilityStrict -> "strict"
    DurabilityRelaxed -> "relaxed"
  })
}

@external(javascript, "./transaction_ffi.mjs", "with_durability")
fn with_durability_ffi(
  builder: TransactionBuilder(readonly),
  durability: String,
) -> TransactionBuilder(readonly)

/// Register a handler called when the transaction completes successfully.
///
pub fn on_complete(
  builder: TransactionBuilder(readonly),
  handler: fn() -> Nil,
) -> TransactionBuilder(readonly) {
  on_complete_ffi(builder, handler)
}

@external(javascript, "./transaction_ffi.mjs", "on_complete")
fn on_complete_ffi(
  builder: TransactionBuilder(readonly),
  handler: fn() -> Nil,
) -> TransactionBuilder(readonly)

/// Register a handler called when the transaction fails with an error.
///
/// The handler receives the browser error name as a string.
///
pub fn on_error(
  builder: TransactionBuilder(readonly),
  handler: fn(String) -> Nil,
) -> TransactionBuilder(readonly) {
  on_error_ffi(builder, handler)
}

@external(javascript, "./transaction_ffi.mjs", "on_error")
fn on_error_ffi(
  builder: TransactionBuilder(readonly),
  handler: fn(String) -> Nil,
) -> TransactionBuilder(readonly)

/// Register a handler called when the transaction is aborted.
///
/// The handler receives `Some(error_name)` if the abort was triggered by an
/// error, or `None` if it was triggered by `abort`.
///
pub fn on_abort(
  builder: TransactionBuilder(readonly),
  handler: fn(Option(String)) -> Nil,
) -> TransactionBuilder(readonly) {
  on_abort_ffi(builder, handler)
}

@external(javascript, "./transaction_ffi.mjs", "on_abort")
fn on_abort_ffi(
  builder: TransactionBuilder(readonly),
  handler: fn(Option(String)) -> Nil,
) -> TransactionBuilder(readonly)

/// Start the transaction and pass the result to `next`.
///
/// Returns `Ok(transaction)` if the transaction was opened successfully, or
/// `Error(TransactionError)` if it could not be started.
///
pub fn begin(
  builder: TransactionBuilder(readonly),
  next: fn(Result(Transaction(readonly, Normal), TransactionError)) -> a,
) -> a {
  begin_ffi(builder, fn(tx) {
    case tx {
      Ok(tx) -> next(Ok(tx))
      Error(name) -> next(Error(UnknownError(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "begin")
fn begin_ffi(
  builder: TransactionBuilder(readonly),
  next: fn(Result(Transaction(readonly, Normal), String)) -> a,
) -> a

/// Abort the transaction, rolling back all writes made so far.
///
pub fn abort(tx: Transaction(rw, upgrade)) -> Nil {
  abort_ffi(tx)
}

@external(javascript, "./transaction_ffi.mjs", "abort")
fn abort_ffi(tx: Transaction(rw, upgrade)) -> Nil

/// Commit the transaction immediately without waiting for all pending
/// requests to settle.
///
/// In most cases you do not need to call this - IndexedDB commits
/// automatically once there are no more pending requests.
///
pub fn commit(tx: Transaction(rw, upgrade)) -> Nil {
  commit_ffi(tx)
}

@external(javascript, "./transaction_ffi.mjs", "commit")
fn commit_ffi(tx: Transaction(rw, upgrade)) -> Nil

/// Read the first record matching `query` from `store` and decode it.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn store_get(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  store_get_ffi(tx, store, query, fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, decoder) {
          Ok(value) -> next(Ok(value))
          Error(errors) -> next(Error(UnableToDecode(errors)))
        }
      Error("NotFound") -> next(Error(NotFoundError))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_get")
fn store_get_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  next: fn(Result(dynamic.Dynamic, String)) -> a,
) -> a

/// Read all records matching `query` from `store` and decode each one.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` records.
///
pub fn store_get_all(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  store_get_all_ffi(tx, store, query, count, fn(result) {
    case result {
      Ok(raws) -> {
        let decoded =
          list.try_map(raws, fn(raw) {
            case decode.run(raw, decoder) {
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

@external(javascript, "./transaction_ffi.mjs", "store_get_all")
fn store_get_all_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  count: option.Option(Int),
  next: fn(Result(List(dynamic.Dynamic), String)) -> a,
) -> a

/// Read the primary key of the first record matching `query` in `store`.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn store_get_key(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  store_get_key_ffi(tx, store, query, fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, decoder) {
          Ok(value) -> next(Ok(value))
          Error(errors) -> next(Error(UnableToDecode(errors)))
        }
      Error("NotFound") -> next(Error(NotFoundError))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_get_key")
fn store_get_key_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  next: fn(Result(dynamic.Dynamic, String)) -> a,
) -> a

/// Read the primary keys of all records matching `query` in `store`.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` keys.
///
pub fn store_get_all_keys(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  store_get_all_keys_ffi(tx, store, query, count, fn(result) {
    case result {
      Ok(raws) -> {
        let decoded =
          list.try_map(raws, fn(raw) {
            case decode.run(raw, decoder) {
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

@external(javascript, "./transaction_ffi.mjs", "store_get_all_keys")
fn store_get_all_keys_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  count: option.Option(Int),
  next: fn(Result(List(dynamic.Dynamic), String)) -> a,
) -> a

/// Count the records matching `query` in `store`.
///
pub fn store_count(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  next: fn(Result(Int, TransactionError)) -> a,
) -> a {
  store_count_ffi(tx, store, query, fn(result) {
    case result {
      Ok(n) -> next(Ok(n))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_count")
fn store_count_ffi(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  next: fn(Result(Int, String)) -> a,
) -> a

/// Insert a new record into `store` and return its generated primary key.
///
/// Returns `Error(ConstraintError)` if the record's key already exists and
/// the store does not allow duplicates.
///
pub fn store_add(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  value: Value,
  key_decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  store_add_ffi(tx, store, value, fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, key_decoder) {
          Ok(key) -> next(Ok(key))
          Error(errors) -> next(Error(UnableToDecode(errors)))
        }
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_add")
fn store_add_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  value: Value,
  next: fn(Result(dynamic.Dynamic, String)) -> a,
) -> a

/// Insert or replace a record in `store` and return its primary key.
///
/// If a record with the same key already exists it is overwritten. Use
/// `store_add` instead when you want an error on duplicate keys.
///
pub fn store_put(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  value: Value,
  key_decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  store_put_ffi(tx, store, value, fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, key_decoder) {
          Ok(key) -> next(Ok(key))
          Error(errors) -> next(Error(UnableToDecode(errors)))
        }
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_put")
fn store_put_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  value: Value,
  next: fn(Result(dynamic.Dynamic, String)) -> a,
) -> a

/// Insert a new record with an explicit out-of-line key.
///
/// Use this when the store was created with `OutOfLineKey` and you manage
/// keys yourself rather than letting IndexedDB generate them.
///
pub fn store_add_with_out_of_line_key(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  value: Value,
  key: Value,
  key_decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  store_add_with_out_of_line_key_ffi(tx, store, value, key, fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, key_decoder) {
          Ok(k) -> next(Ok(k))
          Error(errors) -> next(Error(UnableToDecode(errors)))
        }
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_add_with_out_of_line_key")
fn store_add_with_out_of_line_key_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  value: Value,
  key: Value,
  next: fn(Result(dynamic.Dynamic, String)) -> a,
) -> a

/// Insert or replace a record with an explicit out-of-line key.
///
pub fn store_put_with_out_of_line_key(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  value: Value,
  key: Value,
  key_decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  store_put_with_out_of_line_key_ffi(tx, store, value, key, fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, key_decoder) {
          Ok(k) -> next(Ok(k))
          Error(errors) -> next(Error(UnableToDecode(errors)))
        }
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_put_with_out_of_line_key")
fn store_put_with_out_of_line_key_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  value: Value,
  key: Value,
  next: fn(Result(dynamic.Dynamic, String)) -> a,
) -> a

/// Delete all records matching `query` from `store`.
///
pub fn store_delete(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  query: Query,
  next: fn(Result(Nil, TransactionError)) -> a,
) -> a {
  store_delete_ffi(tx, store, query, fn(result) {
    case result {
      Ok(_) -> next(Ok(Nil))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_delete")
fn store_delete_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  query: Query,
  next: fn(Result(Nil, String)) -> a,
) -> a

/// Delete every record in `store`.
///
pub fn store_clear(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  next: fn(Result(Nil, TransactionError)) -> a,
) -> a {
  store_clear_ffi(tx, store, fn(result) {
    case result {
      Ok(_) -> next(Ok(Nil))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_clear")
fn store_clear_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  next: fn(Result(Nil, String)) -> a,
) -> a

/// Read the first record matching `query` via `index` and decode it.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn index_get(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  index_get_ffi(tx, index, query, fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, decoder) {
          Ok(value) -> next(Ok(value))
          Error(errors) -> next(Error(UnableToDecode(errors)))
        }
      Error("NotFound") -> next(Error(NotFoundError))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_get")
fn index_get_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  next: fn(Result(dynamic.Dynamic, String)) -> a,
) -> a

/// Read the primary key of the first record matching `query` via `index`.
///
/// Returns `Error(NotFoundError)` when no record matches.
///
pub fn index_get_key(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  decoder: decode.Decoder(t),
  next: fn(Result(t, TransactionError)) -> a,
) -> a {
  index_get_key_ffi(tx, index, query, fn(result) {
    case result {
      Ok(raw) ->
        case decode.run(raw, decoder) {
          Ok(value) -> next(Ok(value))
          Error(errors) -> next(Error(UnableToDecode(errors)))
        }
      Error("NotFound") -> next(Error(NotFoundError))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_get_key")
fn index_get_key_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  next: fn(Result(dynamic.Dynamic, String)) -> a,
) -> a

/// Read the primary keys of all records matching `query` via `index`.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` keys.
///
pub fn index_get_all_keys(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  index_get_all_keys_ffi(tx, index, query, count, fn(result) {
    case result {
      Ok(raws) -> {
        let decoded =
          list.try_map(raws, fn(raw) {
            case decode.run(raw, decoder) {
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
fn index_get_all_keys_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  count: option.Option(Int),
  next: fn(Result(List(dynamic.Dynamic), String)) -> a,
) -> a

/// Count the records matching `query` via `index`.
///
pub fn index_count(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  next: fn(Result(Int, TransactionError)) -> a,
) -> a {
  index_count_ffi(tx, index, query, fn(result) {
    case result {
      Ok(n) -> next(Ok(n))
      Error(name) -> next(Error(map_error(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "index_count")
fn index_count_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  next: fn(Result(Int, String)) -> a,
) -> a

/// Read all records matching `query` via `index` and decode each one.
///
/// Pass `option.Some(n)` for `count` to cap the result at `n` records.
///
pub fn index_get_all(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  count: option.Option(Int),
  decoder: decode.Decoder(t),
  next: fn(Result(List(t), TransactionError)) -> a,
) -> a {
  index_get_all_ffi(tx, index, query, count, fn(result) {
    case result {
      Ok(raws) -> {
        let decoded =
          list.try_map(raws, fn(raw) {
            case decode.run(raw, decoder) {
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
fn index_get_all_ffi(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  count: option.Option(Int),
  next: fn(Result(List(dynamic.Dynamic), String)) -> a,
) -> a

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
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  store_open_cursor_ffi(
    tx,
    store,
    query,
    direction,
    initial,
    handler,
    fn(result) {
      case result {
        Ok(state) -> next(Ok(state))
        Error(name) -> next(Error(map_error(name)))
      }
    },
  )
}

@external(javascript, "./transaction_ffi.mjs", "store_open_cursor")
fn store_open_cursor_ffi(
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
  next: fn(Result(state, String)) -> a,
) -> a

/// Open a full-value cursor over `index` and iterate with `handler`.
///
/// Same semantics as `store_open_cursor` but walks records sorted by the
/// index key rather than by primary key.
///
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
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  index_open_cursor_ffi(
    tx,
    index,
    query,
    direction,
    initial,
    handler,
    fn(result) {
      case result {
        Ok(state) -> next(Ok(state))
        Error(name) -> next(Error(map_error(name)))
      }
    },
  )
}

@external(javascript, "./transaction_ffi.mjs", "index_open_cursor")
fn index_open_cursor_ffi(
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
  next: fn(Result(state, String)) -> a,
) -> a

/// Open a key-only cursor over `store` and iterate with `handler`.
///
/// Faster than `store_open_cursor` when you only need the key (e.g. for
/// counting or deleting by key). The cursor does not carry the record value,
/// so `cursor_value` is not available.
///
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
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  store_open_key_cursor_ffi(
    tx,
    store,
    query,
    direction,
    initial,
    handler,
    fn(result) {
      case result {
        Ok(state) -> next(Ok(state))
        Error(name) -> next(Error(map_error(name)))
      }
    },
  )
}

@external(javascript, "./transaction_ffi.mjs", "store_open_key_cursor")
fn store_open_key_cursor_ffi(
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
  next: fn(Result(state, String)) -> a,
) -> a

/// Open a key-only cursor over `index` and iterate with `handler`.
///
/// Faster than `index_open_cursor` when only the index key or primary key is
/// needed.
///
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
  next: fn(Result(state, TransactionError)) -> a,
) -> a {
  index_open_key_cursor_ffi(
    tx,
    index,
    query,
    direction,
    initial,
    handler,
    fn(result) {
      case result {
        Ok(state) -> next(Ok(state))
        Error(name) -> next(Error(map_error(name)))
      }
    },
  )
}

@external(javascript, "./transaction_ffi.mjs", "index_open_key_cursor")
fn index_open_key_cursor_ffi(
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
  next: fn(Result(state, String)) -> a,
) -> a
