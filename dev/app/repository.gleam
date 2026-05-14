import app/entity.{type Track, Track}
import gleam/dynamic/decode
import gleam/javascript/promise
import gleam/option
import gleam/result
import glindex.{type Database, type Index, type Store, Index, Store}
import glindex/cursor
import glindex/index
import glindex/store
import glindex/transaction.{type TransactionError}

pub type TrackStore

pub fn track_store() -> Store(TrackStore, Track, Int) {
  Store(
    name: "tracks",
    to_value: fn(track: Track, action: glindex.Action) {
      case action {
        glindex.Put -> {
          glindex.object([
            #("id", glindex.int(track.id)),
            #("title", glindex.string(track.title)),
            #("album", glindex.string(track.album)),
            #("artist", glindex.string(track.artist)),
            #("duration", glindex.int(track.duration)),
          ])
        }
        _ -> {
          glindex.object([
            #("title", glindex.string(track.title)),
            #("album", glindex.string(track.album)),
            #("artist", glindex.string(track.artist)),
            #("duration", glindex.int(track.duration)),
          ])
        }
      }
    },
    decoder: track_decoder(),
    key_decoder: decode.int,
  )
}

pub fn track_artist_index() -> Index(TrackStore, Track, String) {
  Index(name: "tracks_artist")
}

pub fn track_artist_album_index() -> Index(TrackStore, Track, decode.Dynamic) {
  Index(name: "tracks_artist_and_album")
}

fn track_decoder() -> decode.Decoder(Track) {
  use id <- decode.field("id", decode.int)
  use title <- decode.field("title", decode.string)
  use album <- decode.field("album", decode.string)
  use artist <- decode.field("artist", decode.string)
  use duration <- decode.field("duration", decode.int)
  decode.success(Track(id:, title:, album:, artist:, duration:))
}

pub fn get_track(
  db: Database,
  id: Int,
) -> promise.Promise(Result(Track, TransactionError)) {
  let tx = transaction.prepare(db, transaction.read_only)

  let #(tx, store) = transaction.store(tx, track_store())

  use tx <- promise.await(transaction.begin(tx))

  case tx {
    Ok(tx) -> {
      store.get(tx, store, glindex.Only(glindex.int(id)))
    }
    Error(e) -> promise.resolve(Error(e))
  }
}

pub fn get_all_tracks_by_artist(
  db: Database,
  artist: String,
) -> promise.Promise(Result(List(Track), TransactionError)) {
  let tx = transaction.prepare(db, transaction.read_only)

  let #(tx, store) = transaction.store(tx, track_store())

  let index = transaction.index(store, track_artist_index())

  use tx <- promise.await(transaction.begin(tx))

  case tx {
    Ok(tx) -> {
      use data_result <- promise.map(index.get_all(
        tx,
        index,
        glindex.Only(glindex.string(artist)),
        option.None,
      ))

      use data <- result.try(data_result)
      Ok(data)
    }
    Error(e) -> promise.resolve(Error(e))
  }
}

pub fn add_track(
  db: Database,
  track: Track,
) -> promise.Promise(Result(Track, TransactionError)) {
  let tx = transaction.prepare(db, transaction.read_write)

  let #(tx, store) = transaction.store(tx, track_store())

  use tx <- promise.await(transaction.begin(tx))

  case tx {
    Ok(tx) -> {
      use maybe_id <- promise.await(store.add(tx, store, track))

      case maybe_id {
        Ok(id) -> {
          use data_result <- promise.map(store.get(
            tx,
            store,
            glindex.Only(glindex.int(id)),
          ))

          use data <- result.try(data_result)
          Ok(data)
        }
        Error(e) -> promise.resolve(Error(e))
      }
    }
    Error(e) -> promise.resolve(Error(e))
  }
}

pub fn put_track(
  db: Database,
  track: Track,
) -> promise.Promise(Result(Track, TransactionError)) {
  let tx = transaction.prepare(db, transaction.read_write)

  let #(tx, store) = transaction.store(tx, track_store())

  use tx <- promise.await(transaction.begin(tx))

  case tx {
    Ok(tx) -> {
      use maybe_id <- promise.await(store.put(tx, store, track))

      case maybe_id {
        Ok(id) -> {
          use data_result <- promise.map(store.get(
            tx,
            store,
            glindex.Only(glindex.int(id)),
          ))

          use data <- result.try(data_result)
          Ok(data)
        }
        Error(e) -> promise.resolve(Error(e))
      }
    }
    Error(e) -> promise.resolve(Error(e))
  }
}

pub fn get_tracks_shorter_than(
  db: Database,
  max_duration: Int,
) -> promise.Promise(Result(List(Track), TransactionError)) {
  let tx = transaction.prepare(db, transaction.read_only)

  let #(tx, store) = transaction.store(tx, track_store())

  use tx <- promise.await(transaction.begin(tx))

  case tx {
    Ok(tx) -> {
      store.open_cursor(tx, store, glindex.All, cursor.Next, [], fn(acc, cur) {
        case cursor.cursor_value(cur, track_decoder()) {
          Ok(track) if track.duration < max_duration -> {
            promise.resolve(#([track, ..acc], cursor.continue()))
          }
          _ -> {
            promise.resolve(#(acc, cursor.continue()))
          }
        }
      })
    }
    Error(e) -> promise.resolve(Error(e))
  }
}

pub fn delete_tracks_by_artist(
  db: Database,
  artist: String,
) -> promise.Promise(Result(Nil, TransactionError)) {
  let tx = transaction.prepare(db, transaction.read_write)

  let #(tx, store) = transaction.store(tx, track_store())

  let index = transaction.index(store, track_artist_index())

  use tx <- promise.await(transaction.begin(tx))

  case tx {
    Ok(tx) -> {
      index.open_cursor(
        tx,
        index,
        glindex.Only(glindex.string(artist)),
        cursor.Next,
        Nil,
        fn(_, cur) {
          use _ <- promise.map(cursor.cursor_delete(cur))

          #(Nil, cursor.continue())
        },
      )
    }
    Error(e) -> promise.resolve(Error(e))
  }
}

pub fn rename_artist(
  db: Database,
  old_name: String,
  new_name: String,
) -> promise.Promise(Result(Nil, TransactionError)) {
  let tx = transaction.prepare(db, transaction.read_write)

  let #(tx, store) = transaction.store(tx, track_store())

  let index = transaction.index(store, track_artist_index())

  use tx <- promise.await(transaction.begin(tx))

  case tx {
    Ok(tx) -> {
      index.open_cursor(
        tx,
        index,
        glindex.Only(glindex.string(old_name)),
        cursor.Next,
        Nil,
        fn(_, cur) {
          case cursor.cursor_value(cur, track_decoder()) {
            Ok(track) -> {
              use _ <- promise.map(cursor.cursor_update(
                cur,
                glindex.object([
                  #("id", glindex.int(track.id)),
                  #("title", glindex.string(track.title)),
                  #("album", glindex.string(track.album)),
                  #("artist", glindex.string(new_name)),
                  #("duration", glindex.int(track.duration)),
                ]),
              ))

              #(Nil, cursor.continue())
            }
            Error(_) -> promise.resolve(#(Nil, cursor.stop()))
          }
        },
      )
    }
    Error(e) -> promise.resolve(Error(e))
  }
}

pub fn get_tracks_from_prolific_artists(
  db: Database,
  min_track_count: Int,
) -> promise.Promise(Result(List(Track), TransactionError)) {
  let tx = transaction.prepare(db, transaction.read_only)

  let #(tx, store) = transaction.store(tx, track_store())

  let index = transaction.index(store, track_artist_index())

  use tx <- promise.await(transaction.begin(tx))

  case tx {
    Ok(tx) -> {
      store.open_cursor(tx, store, glindex.All, cursor.Next, [], fn(acc, cur) {
        case cursor.cursor_value(cur, track_decoder()) {
          Ok(track) -> {
            use count_result <- promise.map(index.count(
              tx,
              index,
              glindex.Only(glindex.string(track.artist)),
            ))

            case count_result {
              Ok(count) if count >= min_track_count -> {
                #([track, ..acc], cursor.continue())
              }
              _ -> #(acc, cursor.continue())
            }
          }
          Error(_) -> promise.resolve(#(acc, cursor.stop()))
        }
      })
    }
    Error(e) -> promise.resolve(Error(e))
  }
}

pub fn delete_track(
  db: Database,
  id: Int,
) -> promise.Promise(Result(Track, TransactionError)) {
  let tx = transaction.prepare(db, transaction.read_write)

  let #(tx, store) = transaction.store(tx, track_store())

  use tx <- promise.await(transaction.begin(tx))

  case tx {
    Ok(tx) -> {
      use data_result <- promise.await(store.get(
        tx,
        store,
        glindex.Only(glindex.int(id)),
      ))
      case data_result {
        Ok(track) -> {
          use _ <- promise.map(store.delete(
            tx,
            store,
            glindex.Only(glindex.int(id)),
          ))

          Ok(track)
        }
        Error(e) -> promise.resolve(Error(e))
      }
    }
    Error(e) -> promise.resolve(Error(e))
  }
}
