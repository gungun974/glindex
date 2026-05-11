import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/list
import gleam/order.{type Order}
import gleam/time/calendar.{type Date, type TimeOfDay}
import gleam/time/timestamp.{type Timestamp}

pub type Store(store_type) {
  Store(name: String)
}

pub type Index(store_type) {
  Index(name: String)
}

pub type Database

pub type ReadOnly

pub type ReadWrite

pub type Normal

pub type VersionChange

pub type Value

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

@external(javascript, "./glindex_ffi.mjs", "null_value")
pub fn null() -> Value

@external(javascript, "./glindex_ffi.mjs", "coerce")
pub fn bool(a: Bool) -> Value

@external(javascript, "./glindex_ffi.mjs", "coerce")
pub fn int(a: Int) -> Value

@external(javascript, "./glindex_ffi.mjs", "coerce")
pub fn float(a: Float) -> Value

@external(javascript, "./glindex_ffi.mjs", "coerce")
pub fn string(a: String) -> Value

@external(javascript, "./glindex_ffi.mjs", "coerce")
pub fn bytea(a: BitArray) -> Value

pub fn array(values: List(Value)) -> Value {
  do_array(values)
}

@external(javascript, "./glindex_ffi.mjs", "array")
fn do_array(from: List(Value)) -> Value

pub fn object(entries: List(#(String, Value))) -> Value {
  do_object(entries)
}

@external(javascript, "./glindex_ffi.mjs", "object")
fn do_object(entries: List(#(String, Value))) -> Value

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

pub fn set(converter: fn(a) -> Value, values: List(a)) -> Value {
  list.map(values, converter)
  |> do_set
}

@external(javascript, "./glindex_ffi.mjs", "set_value")
fn do_set(values: List(Value)) -> Value

pub fn timestamp(timestamp: Timestamp) -> Value {
  let #(seconds, nanoseconds) =
    timestamp.to_unix_seconds_and_nanoseconds(timestamp)
  coerce_value(seconds * 1_000_000 + nanoseconds / 1000)
}

pub fn timestamp_decoder() -> decode.Decoder(Timestamp) {
  use microseconds <- decode.map(decode.int)
  let seconds = microseconds / 1_000_000
  let nanoseconds = { microseconds % 1_000_000 } * 1000
  timestamp.from_unix_seconds_and_nanoseconds(seconds, nanoseconds)
}

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

pub fn calendar_time_of_day_decoder() -> decode.Decoder(TimeOfDay) {
  use hours <- decode.field(0, decode.int)
  use minutes <- decode.field(1, decode.int)
  use float_seconds <- decode.field(2, decode.float)
  let seconds = float.truncate(float_seconds)
  let nanoseconds =
    float.round({ float_seconds -. int.to_float(seconds) } *. 1_000_000_000.0)
  decode.success(calendar.TimeOfDay(hours:, minutes:, seconds:, nanoseconds:))
}

pub fn calendar_date(date: Date) -> Value {
  let month = calendar.month_to_int(date.month)
  coerce_value(#(date.year, month, date.day))
}

pub fn calendar_time_of_day(time: TimeOfDay) -> Value {
  let seconds = int.to_float(time.seconds)
  let seconds = seconds +. int.to_float(time.nanoseconds) /. 1_000_000_000.0
  coerce_value(#(time.hours, time.minutes, seconds))
}

@external(javascript, "./glindex_ffi.mjs", "coerce")
fn coerce_value(a: anything) -> Value

pub fn cmp(a: Value, b: Value) -> Order {
  case cmp_ffi(a, b) {
    1 -> order.Gt
    -1 -> order.Lt
    _ -> order.Eq
  }
}

@external(javascript, "./glindex_ffi.mjs", "cmp")
fn cmp_ffi(a: Value, b: Value) -> Int
