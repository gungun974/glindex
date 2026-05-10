import gleam/dynamic/decode
import glindex.{type IdbError, type ReadOnly, type ReadWrite, type Value}

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

pub fn cursor_direction(
  cursor: Cursor(value, mode, source),
) -> CursorDirection {
  todo
}

pub fn cursor_key(cursor: Cursor(value, mode, source)) -> Value {
  todo
}

pub fn cursor_primary_key(cursor: Cursor(value, mode, source)) -> Value {
  todo
}

pub fn cursor_value(
  cursor: Cursor(WithValue, mode, source),
  decoder: decode.Decoder(t),
) -> Result(t, IdbError) {
  todo
}

pub fn cursor_delete(cursor: Cursor(value, ReadWrite, source)) -> Nil {
  todo
}

pub fn cursor_update(
  cursor: Cursor(value, ReadWrite, source),
  value: Value,
) -> Nil {
  todo
}
