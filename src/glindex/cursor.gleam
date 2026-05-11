import gleam/dynamic
import gleam/dynamic/decode
import glindex.{type ReadWrite, type Value}

pub type StoreCursor

pub type IndexCursor

pub type CursorDirection {
  Next
  Prev
  NextUnique
  PrevUnique
}

pub opaque type CursorNext(source) {
  Continue
  Advance(Int)
  ContinuePrimaryKey(key: Value, primary_key: Value)
  Stop
}

pub fn continue() -> CursorNext(source) {
  Continue
}

pub fn advance(n: Int) -> CursorNext(source) {
  Advance(n)
}

pub fn stop() -> CursorNext(source) {
  Stop
}

pub fn continue_primary_key(
  key: Value,
  primary_key: Value,
) -> CursorNext(IndexCursor) {
  ContinuePrimaryKey(key:, primary_key:)
}

pub type WithValue

pub type WithoutValue

pub type Cursor(has_value, mode, source)

pub type CursorError {
  UnableToDecode(List(decode.DecodeError))
}

pub fn cursor_direction(
  cursor: Cursor(value, mode, source),
) -> CursorDirection {
  case cursor_direction_ffi(cursor) {
    "prev" -> Prev
    "nextunique" -> NextUnique
    "prevunique" -> PrevUnique
    _ -> Next
  }
}

@external(javascript, "./cursor_ffi.mjs", "cursor_direction")
fn cursor_direction_ffi(cursor: Cursor(value, mode, source)) -> String

pub fn cursor_key(cursor: Cursor(value, mode, source)) -> Value {
  cursor_key_ffi(cursor)
}

@external(javascript, "./cursor_ffi.mjs", "cursor_key")
fn cursor_key_ffi(cursor: Cursor(value, mode, source)) -> Value

pub fn cursor_primary_key(cursor: Cursor(value, mode, source)) -> Value {
  cursor_primary_key_ffi(cursor)
}

@external(javascript, "./cursor_ffi.mjs", "cursor_primary_key")
fn cursor_primary_key_ffi(cursor: Cursor(value, mode, source)) -> Value

pub fn cursor_value(
  cursor: Cursor(WithValue, mode, source),
  decoder: decode.Decoder(t),
) -> Result(t, CursorError) {
  case decode.run(cursor_value_ffi(cursor), decoder) {
    Ok(v) -> Ok(v)
    Error(e) -> Error(UnableToDecode(e))
  }
}

@external(javascript, "./cursor_ffi.mjs", "cursor_value")
fn cursor_value_ffi(cursor: Cursor(WithValue, mode, source)) -> dynamic.Dynamic

pub fn is_continue(next: CursorNext(source)) -> Bool {
  case next {
    Continue -> True
    _ -> False
  }
}

pub fn is_stop(next: CursorNext(source)) -> Bool {
  case next {
    Stop -> True
    _ -> False
  }
}

pub fn is_advance(next: CursorNext(source)) -> Bool {
  case next {
    Advance(_) -> True
    _ -> False
  }
}

pub fn advance_steps(next: CursorNext(source)) -> Int {
  let assert Advance(n) = next
  n
}

pub fn is_continue_primary_key(next: CursorNext(source)) -> Bool {
  case next {
    ContinuePrimaryKey(_, _) -> True
    _ -> False
  }
}

pub fn continue_primary_key_values(
  next: CursorNext(source),
) -> #(Value, Value) {
  let assert ContinuePrimaryKey(key, primary_key) = next
  #(key, primary_key)
}

pub fn cursor_delete(cursor: Cursor(WithValue, ReadWrite, source)) -> Nil {
  cursor_delete_ffi(cursor)
}

@external(javascript, "./cursor_ffi.mjs", "cursor_delete")
fn cursor_delete_ffi(cursor: Cursor(WithValue, ReadWrite, source)) -> Nil

pub fn cursor_update(
  cursor: Cursor(WithValue, ReadWrite, source),
  value: Value,
) -> Nil {
  cursor_update_ffi(cursor, value)
}

@external(javascript, "./cursor_ffi.mjs", "cursor_update")
fn cursor_update_ffi(
  cursor: Cursor(WithValue, ReadWrite, source),
  value: Value,
) -> Nil
