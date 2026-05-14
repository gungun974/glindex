//// Core types and value converters for glindex.
////
//// This module exposes the fundamental building blocks used across the entire
//// library. Use `store` and `index` to declare type-safe store and index
//// definitions that bundle their name together with serialization and
//// deserialization codecs. Use `Query` to target records by key, and the value
//// helpers (`int`, `string`, `float`, `object`, …) to build the `Value`s that
//// IndexedDB operates on.
////
//// The recommended entry points for actual database work are:
////
//// - [`glindex/database`](./glindex/database.html) - open and manage databases.
//// - [`glindex/upgrade`](./glindex/upgrade.html) - schema migrations inside a version-change transaction.
//// - [`glindex/transaction`](./glindex/transaction.html) - build and start transactions over one or more object stores.
//// - [`glindex/store`](./glindex/store.html) - read and write operations on object stores within a transaction.
//// - [`glindex/index`](./glindex/index.html) - read operations on indexes within a transaction.
//// - [`glindex/cursor`](./glindex/cursor.html) - cursor-based iteration over store or index records.

import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/list
import gleam/order.{type Order}
import gleam/time/calendar.{type Date, type TimeOfDay}
import gleam/time/timestamp.{type Timestamp}

/// A definition of an IndexedDB object store, bundling its name with the
/// codecs needed to serialize records and keys to `Value` and decode them back.
///
/// Create one with `store` (inline key) or `store_with_out_of_line_key`
/// (out-of-line key), then pass it to `transaction.store` to obtain a handle
/// for use inside a transaction:
///
/// ```gleam
/// pub type TrackStore
///
/// pub fn track_store() -> Store(TrackStore, _, _, _) {
///   glindex.store(
///     name: "tracks",
///     to_value: fn(track: Track, _action) { ... },
///     decoder: track_decoder(),
///     to_key: fn(id: Int) { glindex.int(id) },
///     key_decoder: decode.int,
///   )
/// }
/// ```
///
pub opaque type Store(store_type, key_mode, t, k) {
  Store(
    name: String,
    to_value: fn(t, Action) -> Value,
    decoder: decode.Decoder(t),
    to_key: fn(k) -> Value,
    key_decoder: decode.Decoder(k),
  )
}

@internal
pub type InlineKey

@internal
pub type OutOfLineKey

/// Create a store definition with an inline key.
///
/// Use this when the primary key is a property of the stored object (i.e. the
/// store was created with a `KeyPath`). The `to_value` function receives the
/// record and an `Action` so you can omit the key field on `Add` when
/// IndexedDB generates it automatically.
///
pub fn store(
  name name: String,
  to_value to_value: fn(t, Action) -> Value,
  decoder decoder: decode.Decoder(t),
  to_key to_key: fn(k) -> Value,
  key_decoder key_decoder: decode.Decoder(k),
) -> Store(store_type, InlineKey, t, k) {
  Store(name:, to_value:, decoder:, to_key:, key_decoder:)
}

/// Create a store definition with an out-of-line key.
///
/// Use this when the store was created with `OutOfLineKey` and the primary key
/// is not embedded in the object. Write operations require supplying the key
/// separately via `store.add_with_out_of_line_key` or
/// `store.put_with_out_of_line_key`.
///
pub fn store_with_out_of_line_key(
  name name: String,
  to_value to_value: fn(t, Action) -> Value,
  decoder decoder: decode.Decoder(t),
  to_key to_key: fn(k) -> Value,
  key_decoder key_decoder: decode.Decoder(k),
) -> Store(store_type, OutOfLineKey, t, k) {
  Store(name:, to_value:, decoder:, to_key:, key_decoder:)
}

@internal
pub fn store_name(store: Store(store_type, key_mode, t, k)) -> String {
  store.name
}

@internal
pub fn store_to_value(
  store: Store(store_type, key_mode, t, k),
) -> fn(t, Action) -> Value {
  store.to_value
}

@internal
pub fn store_decoder(
  store: Store(store_type, key_mode, t, k),
) -> decode.Decoder(t) {
  store.decoder
}

@internal
pub fn store_to_key(
  store: Store(store_type, key_mode, t, k),
) -> fn(k) -> Value {
  store.to_key
}

@internal
pub fn store_key_decoder(
  store: Store(store_type, key_mode, t, k),
) -> decode.Decoder(k) {
  store.key_decoder
}

/// Indicates whether a write operation is an insert or an upsert.
///
/// Passed to the `to_value` function of a `Store` so the serializer can
/// produce a different object shape for each case - typically to omit the
/// primary key field on `Add` when IndexedDB generates the key automatically,
/// and to include it on `Put` so the existing record is correctly replaced.
///
pub type Action {
  Add
  Put
}

/// A definition of an IndexedDB index, bundling its name with the codecs
/// needed to serialize and decode the index key.
///
/// The phantom type `store_type` links the index to its parent store - the
/// compiler will reject any attempt to use an index with a store of a
/// different type.
///
/// Create one with `index` and pass it to `transaction.index` to obtain a
/// handle for use inside a transaction:
///
/// ```gleam
/// pub fn track_artist_index() -> Index(TrackStore, _, _, _) {
///   glindex.index(
///     name: "tracks_artist",
///     to_index_key: fn(artist: String) { glindex.string(artist) },
///     index_key_decoder: decode.string,
///   )
/// }
/// ```
///
pub opaque type Index(store_type, t, k, i) {
  Index(
    name: String,
    to_index_key: fn(i) -> Value,
    index_key_decoder: decode.Decoder(i),
  )
}

/// Create an index definition.
///
/// `to_index_key` converts a Gleam value into the `Value` used to query the
/// index. `index_key_decoder` reads the raw index key back into a Gleam value
/// when iterating via a cursor.
///
pub fn index(
  name name: String,
  to_index_key to_index_key: fn(i) -> Value,
  index_key_decoder index_key_decoder: decode.Decoder(i),
) -> Index(store_type, t, k, i) {
  Index(name:, to_index_key:, index_key_decoder:)
}

@internal
pub fn index_name(index: Index(store_type, t, k, i)) -> String {
  index.name
}

@internal
pub fn index_to_index_key(index: Index(store_type, t, k, i)) -> fn(i) -> Value {
  index.to_index_key
}

@internal
pub fn index_index_key_decoder(
  index: Index(store_type, t, k, i),
) -> decode.Decoder(i) {
  index.index_key_decoder
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

/// An opaque JavaScript value that IndexedDB can store or use as a key.
///
/// Convert Gleam values to `Value` using the helpers in this module:
/// `int`, `string`, `float`, `bool`, `bytea`, `array`, `object`, and so on.
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
pub type Query(v) {
  All
  Only(v)
  LowerBound(value: v, exclusive: Bool)
  UpperBound(value: v, exclusive: Bool)
  Bound(lower: v, upper: v, exclusive_lower: Bool, exclusive_upper: Bool)
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
