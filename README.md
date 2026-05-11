# glindex

Type-safe [IndexedDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API) bindings for Gleam.

[![Package Version](https://img.shields.io/hexpm/v/glindex)](https://hex.pm/packages/glindex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glindex/)

```sh
gleam add glindex@1
```

```gleam
import gleam/dynamic/decode
import gleam/option
import glindex.{type Database, type Index, type Store, Index, Store}
import glindex/cursor
import glindex/database
import glindex/transaction
import glindex/upgrade

pub type TrackStore

pub const track_store: Store(TrackStore) = Store("tracks")

pub const track_artist_index: Index(TrackStore) = Index("tracks_artist")

pub type Track {
  Track(id: Int, title: String, artist: String)
}

fn track_decoder() -> decode.Decoder(Track) {
  use id <- decode.field("id", decode.int)
  use title <- decode.field("title", decode.string)
  use artist <- decode.field("artist", decode.string)
  decode.success(Track(id:, title:, artist:))
}

pub fn main() -> Nil {
  database.new("MyApp", 1)
  |> database.add_version(1, fn(tx) {
    let store =
      upgrade.create_store(
        tx,
        "tracks",
        upgrade.StoreOptions(key_path: upgrade.KeyPath("id"), auto_increment: True),
      )
    upgrade.create_index(
      tx,
      upgrade.index(store, "tracks_artist"),
      upgrade.KeyPath("artist"),
      upgrade.index_options(),
    )
    Nil
  })
  |> database.open(fn(maybe_db) {
    case maybe_db {
      Error(_) -> Nil
      Ok(db) -> {
        use _ <- add_track(db, Track(id: 0, title: "Bohemian Rhapsody", artist: "Queen"))

        use tracks <- get_tracks_by_artist(db, "Queen")
        let _ = echo tracks

        database.close(db)
      }
    }
  })
}

pub fn add_track(
  db: Database,
  track: Track,
  next: fn(Result(Track, transaction.TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, store) = transaction.store(tx, track_store)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> {
      use maybe_id <- transaction.store_add(
        tx,
        store,
        glindex.object([
          #("title", glindex.string(track.title)),
          #("artist", glindex.string(track.artist)),
        ]),
        decode.int,
      )
      case maybe_id {
        Ok(id) -> {
          use result <- transaction.store_get(tx, store, glindex.Only(glindex.int(id)), track_decoder())
          next(result)
        }
        Error(e) -> next(Error(e))
      }
    }
    Error(e) -> next(Error(e))
  }
}

pub fn get_tracks_by_artist(
  db: Database,
  artist: String,
  next: fn(Result(List(Track), transaction.TransactionError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, store) = transaction.store(tx, track_store)
  let index = transaction.index(store, track_artist_index)
  use tx <- transaction.begin(tx)
  case tx {
    Ok(tx) -> {
      use result <- transaction.index_get_all(
        tx,
        index,
        glindex.Only(glindex.string(artist)),
        option.None,
        track_decoder(),
      )
      next(result)
    }
    Error(e) -> next(Error(e))
  }
}
```

## Type-safe stores and indexes

The recommended pattern with this library is to declare your stores and indexes as typed constants linked to a custom type in your module like this:

```gleam
pub type TrackStore

pub const track_store: Store(TrackStore) = Store("tracks")

pub const track_artist_index: Index(TrackStore) = Index("tracks_artist")

pub const track_artist_album_index: Index(TrackStore) = Index(
  "tracks_artist_and_album",
)
```

The custom type `TrackStore` links each index to its store at the type level.
The compiler will reject any attempt to use `track_artist_index` on a store other than `track_store`, catching mismatches before they reach the browser.

## Opening a database

Use `database.new` to declare your database name and target version, then chain `database.add_version` calls to register incremental migrations.
Each migration only runs when upgrading from a lower version.

```gleam
database.new("MyApp", 2)
|> database.add_version(1, fn(tx) {
  let store =
    upgrade.create_store(
      tx,
      "tracks",
      upgrade.StoreOptions(key_path: upgrade.KeyPath("id"), auto_increment: True),
    )
  upgrade.create_index(
    tx,
    upgrade.index(store, "tracks_artist"),
    upgrade.KeyPath("artist"),
    upgrade.index_options(),
  )
  Nil
})
|> database.add_version(2, fn(tx) {
  let store = upgrade.store(tx, "tracks")
  upgrade.delete_index(tx, upgrade.index(store, "tracks_artist"))
  upgrade.create_index(
    tx,
    upgrade.index(store, "tracks_artist_and_album"),
    upgrade.CompositeKeyPath(["artist", "album"]),
    upgrade.index_options(),
  )
  Nil
})
|> database.open(fn(result) {
  case result {
    Ok(db) -> use_db(db)
    Error(_) -> Nil
  }
})
```

## Transactions

In IndexedDB all database operations run inside a transaction.
Build one with `transaction.prepare`, register the stores you need, then call `transaction.begin` to start it.
The entire API is async so operations chain naturally with `use`.

```gleam
let tx = transaction.prepare(db, transaction.read_write)
let #(tx, store) = transaction.store(tx, track_store)
use tx <- transaction.begin(tx)
```

Use `transaction.read_only` when you only need reads, IndexedDB can run multiple read-only transactions concurrently.

## Queries

`glindex.Query` controls which records a store or index operation targets:

| Constructor | Meaning |
|---|---|
| `All` | Every record |
| `Only(value)` | Exact key match |
| `LowerBound(value, exclusive)` | Keys >= (or >) value |
| `UpperBound(value, exclusive)` | Keys <= (or <) value |
| `Bound(lower, upper, excl_lower, excl_upper)` | Key range |

Values are wrapped with helpers such as `glindex.int`, `glindex.string`, `glindex.float`, or `glindex.array`.

## Cursors

In IndexedDB for iterating over large quantity of entries, you can use cursors.

Cursors let you walk through a range of records one at a time, optionally mutating or deleting each one as you go.

For iterating over a range of records use `transaction.store_open_cursor` or `transaction.index_open_cursor`.
The handler receives the current accumulator, the cursor, and a `next` continuation.
Call `cursor.continue()` to advance, `cursor.stop()` to finish early, or `cursor.advance(n)` to skip ahead.

```gleam
use result <- transaction.store_open_cursor(
  tx,
  store,
  glindex.All,
  cursor.Next,
  [],
  fn(acc, cur, next) {
    case cursor.cursor_value(cur, track_decoder()) {
      Ok(track) -> next([track, ..acc], cursor.continue())
      Error(_) -> next(acc, cursor.stop())
    }
  },
)
```

Inside a `read_write` cursor you can also mutate or delete the record at the current position with `cursor.cursor_update` and `cursor.cursor_delete`.

Further documentation can be found at <https://hexdocs.pm/glindex>.
