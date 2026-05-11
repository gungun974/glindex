//// Core types and value converters for glindex.
////
//// This module exposes the fundamental building blocks used across the entire
//// library. Use the `Store` and `Index` types to make your schema
//// type-safe, the `Query` type for targeting records, and helpers for
//// converting Gleam values into `Value` that IndexedDB
//// can understand for inserting and querying.
////
//// The recommended entry points for actual database work are:
////
//// - [`glindex/database`](./glindex/database.html) - open and manage databases.
//// - [`glindex/upgrade`](./glindex/upgrade.html) - schema migration operations for IndexedDB.
//// - [`glindex/transaction`](./glindex/transaction.html) - classic IndexedDB-style transactions over one or more object stores.
//// - [`glindex/cursor`](./glindex/cursor.html) - cursor-based iteration over store or index records.
//// - [`glindex/store`](./glindex/store.html) - quick one-shot transaction for a single store operation.
//// - [`glindex/index`](./glindex/index.html) - quick one-shot transaction for a single index operation.

import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/list
import gleam/order.{type Order}
import gleam/time/calendar.{type Date, type TimeOfDay}
import gleam/time/timestamp.{type Timestamp}

/// A reference to an IndexedDB object store.
///
/// Each `Store` holds the name of the store as it is declared in the database
/// schema. Declare one constant per store and reuse it wherever you need to
/// read from or write to that store:
///
/// ```gleam
/// pub const track_store: Store(TrackStore) = Store("tracks")
/// ```
///
pub type Store(store_type) {
  Store(name: String)
}

/// A reference to an index on a specific object store.
///
/// Each `Index` holds the name of the index as it is declared in the database
/// schema. Declare one constant per index and pass it to query functions
/// alongside its corresponding store:
///
/// ```gleam
/// pub const track_artist_index: Index(TrackStore) = Index("tracks_artist")
///
/// pub const track_artist_album_index: Index(TrackStore) = Index(
///   "tracks_artist_and_album",
/// )
/// ```
///
pub type Index(store_type) {
  Index(name: String)
}

/// Hold an IndexedDB database connection.
///
/// Obtained from [`glindex/database.open`](./glindex/database.html#open).
///
pub type Database

@internal
pub type ReadOnly

@internal
pub type ReadWrite

@internal
pub type Normal

@internal
pub type VersionChange

/// An opaque JavaScript value can be used with IndexedDB.
///
/// Used in both inserting and quering data
///
/// Convert Gleam values to `Value` using the helpers in this module:
/// `int`, `string`, `float`, `bool`, `array`, `object`, and so on.
///
pub type Value

/// Specifies which records a store or index operation targets.
///
/// - `All` - every record in the store or index.
/// - `Only(value)` - the single record whose key equals `value`.
/// - `LowerBound(value, exclusive)` - records with key ≥ `value`
///   (or > when `exclusive` is `True`).
/// - `UpperBound(value, exclusive)` - records with key ≤ `value`
///   (or < when `exclusive` is `True`).
/// - `Bound(lower, upper, excl_lower, excl_upper)` - records whose key falls
///   within the given range.
///
pub type Query {
  All
  Only(Value)
  LowerBound(value: Value, exclusive: Bool)
  UpperBound(value: Value, exclusive: Bool)
  Bound(
    lower: Value,
    upper: Value,
    exclusive_lower: Bool,
    exclusive_upper: Bool,
  )
}

/// A `Value` representing JavaScript `null`.
///
@external(javascript, "./glindex_ffi.mjs", "null_value")
pub fn null() -> Value

/// Converts a `Bool` to a `Value`.
///
@external(javascript, "./glindex_ffi.mjs", "coerce")
pub fn bool(a: Bool) -> Value

/// Converts an `Int` to a `Value`.
///
@external(javascript, "./glindex_ffi.mjs", "coerce")
pub fn int(a: Int) -> Value

/// Converts a `Float` to a `Value`.
///
@external(javascript, "./glindex_ffi.mjs", "coerce")
pub fn float(a: Float) -> Value

/// Converts a `String` to a `Value`.
///
@external(javascript, "./glindex_ffi.mjs", "coerce")
pub fn string(a: String) -> Value

/// Converts a `BitArray` to a `Value` (stored as an `ArrayBuffer`).
///
@external(javascript, "./glindex_ffi.mjs", "coerce")
pub fn bytea(a: BitArray) -> Value

/// Converts a list of `Value`s to a JavaScript `Array` `Value`.
///
pub fn array(values: List(Value)) -> Value {
  do_array(values)
}

@external(javascript, "./glindex_ffi.mjs", "array")
fn do_array(from: List(Value)) -> Value

/// Converts a list of key-value pairs to a JavaScript object `Value`.
///
/// ## Example
///
/// ```gleam
/// glindex.object([
///   #("title", glindex.string("Bohemian Rhapsody")),
///   #("artist", glindex.string("Queen")),
///   #("duration", glindex.int(354)),
/// ])
/// ```
///
pub fn object(entries: List(#(String, Value))) -> Value {
  do_object(entries)
}

@external(javascript, "./glindex_ffi.mjs", "object")
fn do_object(entries: List(#(String, Value))) -> Value

/// Converts a `Dict` to a JavaScript `Map` `Value`.
///
/// Both keys and values are converted with the provided converter functions.
///
pub fn map(
  key_converter: fn(k) -> Value,
  value_converter: fn(v) -> Value,
  dict: Dict(k, v),
) -> Value {
  dict.to_list(dict)
  |> list.map(fn(entry) {
    let #(k, v) = entry
    #(key_converter(k), value_converter(v))
  })
  |> do_map
}

@external(javascript, "./glindex_ffi.mjs", "map_value")
fn do_map(entries: List(#(Value, Value))) -> Value

/// Converts a list to a JavaScript `Set` `Value`.
///
pub fn set(converter: fn(a) -> Value, values: List(a)) -> Value {
  list.map(values, converter)
  |> do_set
}

@external(javascript, "./glindex_ffi.mjs", "set_value")
fn do_set(values: List(Value)) -> Value

/// Converts a `Timestamp` to a `Value` stored as microseconds since the Unix
/// epoch. Use `timestamp_decoder` to read it back.
///
pub fn timestamp(timestamp: Timestamp) -> Value {
  let #(seconds, nanoseconds) =
    timestamp.to_unix_seconds_and_nanoseconds(timestamp)
  coerce_value(seconds * 1_000_000 + nanoseconds / 1000)
}

/// Decoder for a `Timestamp` stored by `timestamp`.
///
pub fn timestamp_decoder() -> decode.Decoder(Timestamp) {
  use microseconds <- decode.map(decode.int)
  let seconds = microseconds / 1_000_000
  let nanoseconds = { microseconds % 1_000_000 } * 1000
  timestamp.from_unix_seconds_and_nanoseconds(seconds, nanoseconds)
}

/// Decoder for a `Date` stored by `calendar_date`.
///
pub fn calendar_date_decoder() -> decode.Decoder(Date) {
  use year <- decode.field(0, decode.int)
  use month_int <- decode.field(1, decode.int)
  use day <- decode.field(2, decode.int)
  let month = case month_int {
    1 -> calendar.January
    2 -> calendar.February
    3 -> calendar.March
    4 -> calendar.April
    5 -> calendar.May
    6 -> calendar.June
    7 -> calendar.July
    8 -> calendar.August
    9 -> calendar.September
    10 -> calendar.October
    11 -> calendar.November
    _ -> calendar.December
  }
  decode.success(calendar.Date(year:, month:, day:))
}

/// Decoder for a `TimeOfDay` stored by `calendar_time_of_day`.
///
pub fn calendar_time_of_day_decoder() -> decode.Decoder(TimeOfDay) {
  use hours <- decode.field(0, decode.int)
  use minutes <- decode.field(1, decode.int)
  use float_seconds <- decode.field(2, decode.float)
  let seconds = float.truncate(float_seconds)
  let nanoseconds =
    float.round({ float_seconds -. int.to_float(seconds) } *. 1_000_000_000.0)
  decode.success(calendar.TimeOfDay(hours:, minutes:, seconds:, nanoseconds:))
}

/// Converts a `Date` to an array `Value` of `[year, month, day]`.
/// Use `calendar_date_decoder` to read it back.
///
pub fn calendar_date(date: Date) -> Value {
  let month = calendar.month_to_int(date.month)
  coerce_value(#(date.year, month, date.day))
}

/// Converts a `TimeOfDay` to an array `Value` of `[hours, minutes, seconds]`.
/// Use `calendar_time_of_day_decoder` to read it back.
///
pub fn calendar_time_of_day(time: TimeOfDay) -> Value {
  let seconds = int.to_float(time.seconds)
  let seconds = seconds +. int.to_float(time.nanoseconds) /. 1_000_000_000.0
  coerce_value(#(time.hours, time.minutes, seconds))
}

@external(javascript, "./glindex_ffi.mjs", "coerce")
fn coerce_value(a: anything) -> Value

/// Compares two `Value`s using IndexedDB's built-in key comparison algorithm.
///
/// This mirrors the ordering IndexedDB uses internally for keys and ranges,
/// which differs from JavaScript's default `<` / `>` operators for certain
/// types such as arrays.
///
pub fn cmp(a: Value, b: Value) -> Order {
  case cmp_ffi(a, b) {
    1 -> order.Gt
    -1 -> order.Lt
    _ -> order.Eq
  }
}

@external(javascript, "./glindex_ffi.mjs", "cmp")
fn cmp_ffi(a: Value, b: Value) -> Int
