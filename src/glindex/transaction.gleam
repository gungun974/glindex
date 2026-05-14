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

import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/option.{type Option}
import glindex.{
  type Database, type Index, type Normal, type ReadOnly, type ReadWrite,
  type Store,
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
pub type TransactionStore(store_type, t, k)

/// Handle to an index obtained via `transaction.index`.
///
pub type TransactionIndex(t, k, i)

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
  store: Store(store_type, t, k),
) -> #(TransactionBuilder(readonly), TransactionStore(store_type, t, k)) {
  store_ffi(builder, store)
}

@external(javascript, "./transaction_ffi.mjs", "store")
fn store_ffi(
  builder: TransactionBuilder(readonly),
  store: Store(store_type, t, k),
) -> #(TransactionBuilder(readonly), TransactionStore(store_type, t, k))

/// Obtain an index handle from a store handle.
///
/// The `Index(store_type)` and `TransactionStore(store_type)` must share the
/// same phantom type.
///
pub fn index(
  store: TransactionStore(store_type, t, k),
  name: Index(store_type, t, k, i),
) -> TransactionIndex(t, k, i) {
  index_ffi(store, name)
}

@external(javascript, "./transaction_ffi.mjs", "index")
fn index_ffi(
  store: TransactionStore(store_type, t, k),
  name: Index(store_type, t, k, i),
) -> TransactionIndex(t, k, i)

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
) -> Promise(Result(Transaction(readonly, Normal), TransactionError)) {
  use next <- promise.new()

  case begin_ffi(builder) {
    Ok(tx) -> next(Ok(tx))
    Error(name) -> next(Error(UnknownError(name)))
  }
}

@external(javascript, "./transaction_ffi.mjs", "begin")
fn begin_ffi(
  builder: TransactionBuilder(readonly),
) -> Result(Transaction(readonly, Normal), String)

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
