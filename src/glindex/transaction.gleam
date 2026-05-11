import gleam/dynamic
import gleam/dynamic/decode
import gleam/list
import gleam/option
import glindex.{
  type Database, type Index, type Normal, type Query, type ReadOnly,
  type ReadWrite, type Store, type Value,
}
import glindex/cursor.{
  type Cursor, type CursorDirection, type CursorNext, type IndexCursor,
  type StoreCursor, type WithValue, type WithoutValue,
}

pub type TransactionMode(readonly) {
  TransactionReadOnly
  TransactionReadWrite
}

pub const read_only: TransactionMode(ReadOnly) = TransactionReadOnly

pub const read_write: TransactionMode(ReadWrite) = TransactionReadWrite

pub type TransactionBuilder(readonly)

pub type TransactionDurability {
  DurabilityDefault
  DurabilityStrict
  DurabilityRelaxed
}

pub type Transaction(readonly, upgrade)

pub type TransactionStore(store_type)

pub type TransactionIndex

pub type TransactionError {
  ConstraintError
  UnableToDecode(List(decode.DecodeError))
  UnknownError(String)
}

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
pub fn prepare_ffi(db: Database, mode: String) -> TransactionBuilder(readonly)

/// Here I cheat
/// I don't want the user to be able to get from a Store a TransactionStore
/// But forget to chain the builder when using begin
/// So to prevent them error TransactionBuilder is secretly handle in JS
/// For mutating in place the object
/// This way there is no issue for the user
pub fn store(
  builder: TransactionBuilder(readonly),
  store: Store(store_type),
) -> #(TransactionBuilder(readonly), TransactionStore(store_type)) {
  store_ffi(builder, store)
}

@external(javascript, "./transaction_ffi.mjs", "store")
pub fn store_ffi(
  builder: TransactionBuilder(readonly),
  store: Store(store_type),
) -> #(TransactionBuilder(readonly), TransactionStore(store_type))

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

pub fn abort(tx: Transaction(rw, upgrade)) -> Nil {
  abort_ffi(tx)
}

@external(javascript, "./transaction_ffi.mjs", "abort")
fn abort_ffi(tx: Transaction(rw, upgrade)) -> Nil

pub fn commit(tx: Transaction(rw, upgrade)) -> Nil {
  commit_ffi(tx)
}

@external(javascript, "./transaction_ffi.mjs", "commit")
fn commit_ffi(tx: Transaction(rw, upgrade)) -> Nil

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
      Error(name) -> next(Error(UnknownError(name)))
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
      Error(name) -> next(Error(UnknownError(name)))
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
      Error(name) -> next(Error(UnknownError(name)))
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
      Error(name) -> next(Error(UnknownError(name)))
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

pub fn store_count(
  tx: Transaction(rw, upgrade),
  store: TransactionStore(any),
  query: Query,
  next: fn(Result(Int, TransactionError)) -> a,
) -> a {
  store_count_ffi(tx, store, query, fn(result) {
    case result {
      Ok(n) -> next(Ok(n))
      Error(name) -> next(Error(UnknownError(name)))
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
      Error("ConstraintError") -> next(Error(ConstraintError))
      Error(name) -> next(Error(UnknownError(name)))
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
      Error("ConstraintError") -> next(Error(ConstraintError))
      Error(name) -> next(Error(UnknownError(name)))
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
      Error("ConstraintError") -> next(Error(ConstraintError))
      Error(name) -> next(Error(UnknownError(name)))
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
      Error("ConstraintError") -> next(Error(ConstraintError))
      Error(name) -> next(Error(UnknownError(name)))
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

pub fn store_delete(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  query: Query,
  next: fn(Result(Nil, TransactionError)) -> a,
) -> a {
  store_delete_ffi(tx, store, query, fn(result) {
    case result {
      Ok(_) -> next(Ok(Nil))
      Error(name) -> next(Error(UnknownError(name)))
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

pub fn store_clear(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  next: fn(Result(Nil, TransactionError)) -> a,
) -> a {
  store_clear_ffi(tx, store, fn(result) {
    case result {
      Ok(_) -> next(Ok(Nil))
      Error(name) -> next(Error(UnknownError(name)))
    }
  })
}

@external(javascript, "./transaction_ffi.mjs", "store_clear")
fn store_clear_ffi(
  tx: Transaction(ReadWrite, upgrade),
  store: TransactionStore(any),
  next: fn(Result(Nil, String)) -> a,
) -> a

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
      Error(name) -> next(Error(UnknownError(name)))
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
      Error(name) -> next(Error(UnknownError(name)))
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
      Error(name) -> next(Error(UnknownError(name)))
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

pub fn index_count(
  tx: Transaction(rw, upgrade),
  index: TransactionIndex,
  query: Query,
  next: fn(Result(Int, TransactionError)) -> a,
) -> a {
  index_count_ffi(tx, index, query, fn(result) {
    case result {
      Ok(n) -> next(Ok(n))
      Error(name) -> next(Error(UnknownError(name)))
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
      Error(name) -> next(Error(UnknownError(name)))
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
        Error(name) -> next(Error(UnknownError(name)))
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
        Error(name) -> next(Error(UnknownError(name)))
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
        Error(name) -> next(Error(UnknownError(name)))
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
        Error(name) -> next(Error(UnknownError(name)))
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
