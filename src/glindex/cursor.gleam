//// Cursor-based iteration over store or index records.
////
//// Cursors let you walk through a range of records one at a time, optionally
//// mutating or deleting each one as you go. They are opened via
//// [`glindex/transaction.store_open_cursor`](./transaction.html#store_open_cursor)
//// and [`glindex/transaction.index_open_cursor`](./transaction.html#index_open_cursor).
////
//// The iteration model is accumulator-based: your handler receives the current
//// accumulator, the cursor, and a `next` continuation. Return `cursor.continue()`
//// to advance, `cursor.stop()` to finish early, or `cursor.advance(n)` to skip
//// ahead. The final accumulator is returned as the `Result` of the cursor call.
////
//// ## Example
////
//// ```gleam
//// use result <- transaction.store_open_cursor(
////   tx,
////   store,
////   glindex.All,
////   cursor.Next,
////   [],
////   fn(acc, cur, next) {
////     case cursor.cursor_value(cur, track_decoder()) {
////       Ok(track) -> next([track, ..acc], cursor.continue())
////       Error(_) -> next(acc, cursor.stop())
////     }
////   },
//// )
//// ```

import gleam/dynamic
import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import glindex.{type ReadWrite}

@internal
pub type StoreCursor

@internal
pub type IndexCursor

/// The direction in which the cursor walks through the records.
///
/// - `Next` - ascending key order, visiting all records.
/// - `Prev` - descending key order, visiting all records.
/// - `NextUnique` - ascending key order, skipping duplicate index keys.
/// - `PrevUnique` - descending key order, skipping duplicate index keys.
///
pub type CursorDirection {
  Next
  Prev
  NextUnique
  PrevUnique
}

/// Opaque instruction returned from a cursor handler to control iteration.
///
/// Construct one with `continue`, `advance`, `stop`, or
/// `continue_primary_key`.
///
pub opaque type CursorNext(source, p, k) {
  Continue
  Advance(Int)
  ContinuePrimaryKey(key: k, primary_key: p)
  Stop
}

/// Advance to the next record in the current direction.
///
pub fn continue() -> CursorNext(source, p, k) {
  Continue
}

/// Skip forward `n` records from the current position.
///
pub fn advance(n: Int) -> CursorNext(source, p, k) {
  Advance(n)
}

/// Stop iteration and return the current accumulator.
///
pub fn stop() -> CursorNext(source, p, k) {
  Stop
}

/// Jump to the record with the given index key and primary key.
///
/// Only valid for index cursors (`IndexCursor`). Useful for efficiently
/// seeking within a sorted index without visiting every intermediate record.
///
pub fn continue_primary_key(
  key: k,
  primary_key: p,
) -> CursorNext(IndexCursor, p, k) {
  ContinuePrimaryKey(key:, primary_key:)
}

@internal
pub type WithValue

@internal
pub type WithoutValue

/// The cursor handle passed to your iteration handler.
///
pub type Cursor(has_value, mode, source, t, p, k)

/// Errors that can occur inside a cursor handler.
///
pub type CursorError {
  UnableToDecode(List(decode.DecodeError))
  CursorUnknownError(String)
}

/// Return the direction the cursor is walking.
///
pub fn cursor_direction(
  cursor: Cursor(value, mode, source, t, p, k),
) -> CursorDirection {
  case cursor_direction_ffi(cursor) {
    "prev" -> Prev
    "nextunique" -> NextUnique
    "prevunique" -> PrevUnique
    _ -> Next
  }
}

@external(javascript, "./cursor_ffi.mjs", "cursor_direction")
fn cursor_direction_ffi(cursor: Cursor(value, mode, source, t, p, k)) -> String

/// Return the key of the record at the current cursor position.
///
pub fn cursor_key(
  cursor: Cursor(value, mode, source, t, p, k),
) -> Result(k, CursorError) {
  case decode.run(cursor_key_ffi(cursor), extract_cursor(cursor).2) {
    Ok(v) -> Ok(v)
    Error(e) -> Error(UnableToDecode(e))
  }
}

@external(javascript, "./cursor_ffi.mjs", "cursor_key")
fn cursor_key_ffi(
  cursor: Cursor(value, mode, source, t, p, k),
) -> dynamic.Dynamic

/// Return the primary key of the record at the current cursor position.
///
/// For store cursors this is the same as `cursor_key`. For index cursors it
/// is the underlying record key in the object store, which may differ from
/// the indexed key.
///
pub fn cursor_primary_key(
  cursor: Cursor(value, mode, source, t, p, k),
) -> Result(p, CursorError) {
  case decode.run(cursor_primary_key_ffi(cursor), extract_cursor(cursor).1) {
    Ok(v) -> Ok(v)
    Error(e) -> Error(UnableToDecode(e))
  }
}

@external(javascript, "./cursor_ffi.mjs", "cursor_primary_key")
fn cursor_primary_key_ffi(
  cursor: Cursor(value, mode, source, t, p, k),
) -> dynamic.Dynamic

@external(javascript, "./cursor_ffi.mjs", "extract_cursor")
fn extract_cursor(
  cursor: Cursor(has_value, mode, source, t, p, k),
) -> #(decode.Decoder(t), decode.Decoder(p), decode.Decoder(k))

/// Decode and return the record at the current cursor position.
///
/// Only available on cursors opened with `store_open_cursor` or
/// `index_open_cursor` (`WithValue`).
///
pub fn cursor_value(
  cursor: Cursor(WithValue, mode, source, t, p, k),
) -> Result(t, CursorError) {
  case decode.run(cursor_value_ffi(cursor), extract_cursor(cursor).0) {
    Ok(v) -> Ok(v)
    Error(e) -> Error(UnableToDecode(e))
  }
}

@external(javascript, "./cursor_ffi.mjs", "cursor_value")
fn cursor_value_ffi(
  cursor: Cursor(WithValue, mode, source, t, p, k),
) -> dynamic.Dynamic

@internal
pub fn is_continue(next: CursorNext(source, p, k)) -> Bool {
  case next {
    Continue -> True
    _ -> False
  }
}

@internal
pub fn is_stop(next: CursorNext(source, p, k)) -> Bool {
  case next {
    Stop -> True
    _ -> False
  }
}

@internal
pub fn is_advance(next: CursorNext(source, p, k)) -> Bool {
  case next {
    Advance(_) -> True
    _ -> False
  }
}

@internal
pub fn advance_steps(next: CursorNext(source, p, k)) -> Int {
  let assert Advance(n) = next
  n
}

@internal
pub fn is_continue_primary_key(next: CursorNext(source, p, k)) -> Bool {
  case next {
    ContinuePrimaryKey(_, _) -> True
    _ -> False
  }
}

@internal
pub fn continue_primary_key_values(next: CursorNext(source, p, k)) -> #(k, p) {
  let assert ContinuePrimaryKey(key, primary_key) = next
  #(key, primary_key)
}

/// Delete the record at the current cursor position.
///
/// Only available on read-write cursors (`ReadWrite`) that carry a value
/// (`WithValue`).
///
pub fn cursor_delete(
  cursor: Cursor(WithValue, ReadWrite, source, t, p, k),
) -> Promise(Result(Nil, CursorError)) {
  cursor_delete_ffi(cursor)
  |> promise.map(fn(result) {
    case result {
      Ok(_) -> Ok(Nil)
      Error(name) -> Error(CursorUnknownError(name))
    }
  })
}

@external(javascript, "./cursor_ffi.mjs", "cursor_delete")
fn cursor_delete_ffi(
  cursor: Cursor(WithValue, ReadWrite, source, t, p, k),
) -> Promise(Result(Nil, String))

/// Replace the record at the current cursor position with `value`.
///
/// Only available on read-write cursors (`ReadWrite`) that carry a value
/// (`WithValue`). The key of the record does not change.
///
pub fn cursor_update(
  cursor: Cursor(WithValue, ReadWrite, source, t, p, k),
  value: t,
) {
  cursor_update_ffi(cursor, value)
  |> promise.map(fn(result) {
    case result {
      Ok(_) -> Ok(Nil)
      Error(name) -> Error(CursorUnknownError(name))
    }
  })
}

@external(javascript, "./cursor_ffi.mjs", "cursor_update")
fn cursor_update_ffi(
  cursor: Cursor(WithValue, ReadWrite, source, t, p, k),
  value: t,
) -> Promise(Result(Nil, String))
