# glindex

Type-safe [IndexedDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API) bindings for Gleam.

[![Package Version](https://img.shields.io/hexpm/v/glindex)](https://hex.pm/packages/glindex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glindex/)

```sh
gleam add glindex@1
```

```gleam
import gleam/dynamic/decode
import gleam/javascript/promise
import gleam/option
import glindex.{type Database, type Index, type Store}
import glindex/database
import glindex/index
import glindex/store
import glindex/transaction
import glindex/upgrade

pub type TrackStore

pub type Track {
  Track(id: Int, title: String, artist: String)
}

pub fn track_store() -> Store(TrackStore, _, _, _) {
  glindex.store(
    name: "tracks",
    to_value: fn(track: Track, action: glindex.Action) {
      case action {
        glindex.Add ->
          glindex.object([
            #("title", glindex.string(track.title)),
            #("artist", glindex.string(track.artist)),
          ])
        glindex.Put ->
          glindex.object([
            #("id", glindex.int(track.id)),
            #("title", glindex.string(track.title)),
            #("artist", glindex.string(track.artist)),
          ])
      }
    },
    decoder: {
      use id <- decode.field("id", decode.int)
      use title <- decode.field("title", decode.string)
      use artist <- decode.field("artist", decode.string)
      decode.success(Track(id:, title:, artist:))
    },
    to_key: fn(id: Int) { glindex.int(id) },
    key_decoder: decode.int,
  )
}

pub fn track_artist_index() -> Index(TrackStore, _, _, _) {
  glindex.index(
    name: "tracks_artist",
    to_index_key: fn(artist: String) { glindex.string(artist) },
    index_key_decoder: decode.string,
  )
}

pub fn main() -> promise.Promise(Nil) {
  use db_result <- promise.await(
    database.new("MyApp", 1)
    |> database.add_version(1, fn(tx) {
      let assert Ok(s) =
        upgrade.create_store(
          tx,
          "tracks",
          upgrade.StoreOptions(
            key_path: upgrade.KeyPath("id"),
            auto_increment: True,
          ),
        )
      let assert Ok(_) =
        upgrade.create_index(
          tx,
          upgrade.index(s, "tracks_artist"),
          upgrade.KeyPath("artist"),
          upgrade.index_options(),
        )
      Nil
    })
    |> database.open(),
  )

  case db_result {
    Error(_) -> promise.resolve(Nil)
    Ok(db) -> {
      use _ <- promise.await(add_track(
        db,
        Track(id: 0, title: "Bohemian Rhapsody", artist: "Queen"),
      ))
      use tracks <- promise.await(get_tracks_by_artist(db, "Queen"))
      let _ = echo tracks
      database.close(db)
      promise.resolve(Nil)
    }
  }
}

pub fn add_track(
  db: Database,
  track: Track,
) -> promise.Promise(Result(Track, transaction.TransactionError)) {
  let tx = transaction.prepare(db, transaction.read_write)
  let #(tx, s) = transaction.store(tx, track_store())
  use tx <- promise.await(transaction.begin(tx))
  case tx {
    Ok(tx) -> {
      use maybe_id <- promise.await(store.add(tx, s, track))
      case maybe_id {
        Ok(id) -> store.get(tx, s, glindex.Only(id))
        Error(e) -> promise.resolve(Error(e))
      }
    }
    Error(e) -> promise.resolve(Error(e))
  }
}

pub fn get_tracks_by_artist(
  db: Database,
  artist: String,
) -> promise.Promise(Result(List(Track), transaction.TransactionError)) {
  let tx = transaction.prepare(db, transaction.read_only)
  let #(tx, s) = transaction.store(tx, track_store())
  let idx = transaction.index(s, track_artist_index())
  use tx <- promise.await(transaction.begin(tx))
  case tx {
    Ok(tx) -> index.get_all(tx, idx, glindex.Only(artist), option.None)
    Error(e) -> promise.resolve(Error(e))
  }
}
```

## Defining stores and indexes

Each store is declared as a function returning a `Store` value that bundles the store name together with its serializer, decoder, key serializer, and key decoder. This keeps everything in one place and makes the compiler verify that the right codecs are used throughout.

```gleam
pub type TrackStore

pub fn track_store() -> Store(TrackStore, _, _, _) {
  glindex.store(
    name: "tracks",
    to_value: fn(track: Track, action: glindex.Action) {
      case action {
        glindex.Add ->
          glindex.object([
            #("title", glindex.string(track.title)),
            #("artist", glindex.string(track.artist)),
          ])
        glindex.Put ->
          glindex.object([
            #("id", glindex.int(track.id)),
            #("title", glindex.string(track.title)),
            #("artist", glindex.string(track.artist)),
          ])
      }
    },
    decoder: {
      use id <- decode.field("id", decode.int)
      use title <- decode.field("title", decode.string)
      use artist <- decode.field("artist", decode.string)
      decode.success(Track(id:, title:, artist:))
    },
    to_key: fn(id: Int) { glindex.int(id) },
    key_decoder: decode.int,
  )
}
```

The `action` parameter in `to_value` distinguishes `Add` (insert) from `Put` (upsert). Use it when the serialized form must differ between the two - for example, when the key is auto-generated by IndexedDB on `Add` and must therefore be omitted from the object, but included on `Put` so the existing record is correctly identified.

Indexes are declared the same way:

```gleam
pub fn track_artist_index() -> Index(TrackStore, _, _, _) {
  glindex.index(
    name: "tracks_artist",
    to_index_key: fn(artist: String) { glindex.string(artist) },
    index_key_decoder: decode.string,
  )
}

pub fn track_artist_album_index() -> Index(TrackStore, _, _, _) {
  glindex.index(
    name: "tracks_artist_and_album",
    to_index_key: fn(key: #(String, String)) {
      glindex.array([glindex.string(key.0), glindex.string(key.1)])
    },
    index_key_decoder: {
      use first <- decode.field(0, decode.string)
      use second <- decode.field(1, decode.string)
      decode.success(#(first, second))
    },
  )
}
```

The phantom type `TrackStore` links each index to its store at the type level. The compiler will reject any attempt to use `track_artist_index()` with a store other than `track_store()`, catching mismatches before they reach the browser.

## Opening a database

Use `database.new` to declare the database name and target version, then chain `database.add_version` calls to register incremental migrations. Each migration only runs when the database is being upgraded past that version. `database.open` returns a `Promise`.

```gleam
database.new("MyApp", 2)
|> database.add_version(1, fn(tx) {
  let assert Ok(s) =
    upgrade.create_store(
      tx,
      "tracks",
      upgrade.StoreOptions(key_path: upgrade.KeyPath("id"), auto_increment: True),
    )
  let assert Ok(_) =
    upgrade.create_index(
      tx,
      upgrade.index(s, "tracks_artist"),
      upgrade.KeyPath("artist"),
      upgrade.index_options(),
    )
  Nil
})
|> database.add_version(2, fn(tx) {
  let s = upgrade.store(tx, "tracks")
  let assert Ok(_) =
    upgrade.delete_index(tx, upgrade.index(s, "tracks_artist"))
  let assert Ok(_) =
    upgrade.create_index(
      tx,
      upgrade.index(s, "tracks_artist_and_album"),
      upgrade.CompositeKeyPath(["artist", "album"]),
      upgrade.index_options(),
    )
  Nil
})
|> database.open()
```

## Transactions

All database operations run inside a transaction. Build one with `transaction.prepare`, register the stores you need with `transaction.store`, then `await` the `Promise` returned by `transaction.begin`.

```gleam
let tx = transaction.prepare(db, transaction.read_write)
let #(tx, s) = transaction.store(tx, track_store())
use tx <- promise.await(transaction.begin(tx))
case tx {
  Ok(tx) -> {
    use result <- promise.await(store.add(tx, s, track))
    ...
  }
  Error(e) -> promise.resolve(Error(e))
}
```

Use `transaction.read_only` when you only need reads - IndexedDB can run multiple read-only transactions concurrently.

> **Transaction lifetime**
>
> IndexedDB auto-closes a transaction as soon as it has no pending requests
> and all microtasks have been processed. **Do not `await` anything unrelated
> to the database inside a transaction** - for example, an HTTP request or a
> timer. If the event loop goes idle between two database operations, the
> transaction will have already committed and the next operation will fail.
>
> ```gleam
> // OK - every await is a database operation on the same transaction
> use id <- promise.await(store.add(tx, s, track))
> use _  <- promise.await(store.get(tx, s, glindex.Only(id)))
>
> // WRONG - the transaction closes during the HTTP request
> use id       <- promise.await(store.add(tx, s, track))
> use response <- promise.await(http.get("/api/confirm"))  // transaction is now closed
> use _        <- promise.await(store.get(tx, s, glindex.Only(id)))  // fails
> ```

Store operations live in `glindex/store`; index operations live in `glindex/index`. Both modules expose functions that accept a transaction handle and return a `Promise`.

```gleam
store.get(tx, s, glindex.Only(42))
store.get_all(tx, s, glindex.All, option.None)
store.add(tx, s, track)
store.put(tx, s, track)
store.delete(tx, s, glindex.Only(42))

index.get(tx, idx, glindex.Only("Queen"))
index.get_all(tx, idx, glindex.Only("Queen"), option.None)
index.count(tx, idx, glindex.All)
```

## Queries

`glindex.Query` controls which records an operation targets. The query type is parameterised by the key type of the store or index, so values are passed directly without manual conversion.

| Constructor | Meaning |
|---|---|
| `All` | Every record |
| `Only(value)` | Exact key match |
| `LowerBound(value, exclusive)` | Keys >= (or >) value |
| `UpperBound(value, exclusive)` | Keys <= (or <) value |
| `Bound(lower, upper, excl_lower, excl_upper)` | Key range |

```gleam
glindex.Only(42)
glindex.LowerBound(100, False)
glindex.Bound("a", "z", False, True)
```

## Cursors

Cursors let you walk through a range of records one at a time, optionally mutating or deleting each one as you go. Open one with `store.open_cursor` or `index.open_cursor`.

The handler receives the current accumulator and the cursor, and must return a `Promise` of the new accumulator paired with a navigation instruction.

```gleam
use result <- promise.await(
  store.open_cursor(tx, s, glindex.All, cursor.Next, [], fn(acc, cur) {
    case cursor.cursor_value(cur) {
      Ok(track) -> promise.resolve(#([track, ..acc], cursor.continue()))
      Error(_) -> promise.resolve(#(acc, cursor.stop()))
    }
  }),
)
```

Navigation instructions:

| Function | Effect |
|---|---|
| `cursor.continue()` | Advance to the next record |
| `cursor.advance(n)` | Skip `n` records forward |
| `cursor.continue_key(key)` | Jump to the first record with key >= `key` |
| `cursor.continue_primary_key(key, primary_key)` | Jump to a specific index key + primary key pair (index cursors only) |
| `cursor.stop()` | Stop iteration and return the accumulator |

Inside a `read_write` cursor you can also mutate or delete the current record:

```gleam
store.open_cursor(tx, s, glindex.Only(artist), cursor.Next, Nil, fn(_, cur) {
  case cursor.cursor_value(cur) {
    Ok(track) -> {
      use _ <- promise.map(cursor.cursor_update(cur, Track(..track, artist: new_name)))
      #(Nil, cursor.continue())
    }
    Error(_) -> promise.resolve(#(Nil, cursor.stop()))
  }
})
```

Use `store.open_key_cursor` or `index.open_key_cursor` when you only need the key - these skip fetching the full record value and are faster for counting or bulk deletes.

Further documentation can be found at <https://hexdocs.pm/glindex>.
