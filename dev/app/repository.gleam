import app/entity.{type Track, Track}
import gleam/dynamic/decode
import gleam/option
import gleam/result
import glindex.{type Database, type IdbError}
import glindex/cursor
import glindex/index
import glindex/store
import glindex/transaction

pub type TrackStore

pub const track_store: store.Store(TrackStore) = store.Store("tracks")

pub const track_artist_index: index.Index(TrackStore) = index.Index(
  "tracks_artist",
)

pub const track_artist_album_index: index.Index(TrackStore) = index.Index(
  "tracks_artist_and_album",
)

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
  next: fn(Result(Track, IdbError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)

  let #(tx, store) = transaction.store(tx, track_store)

  use tx <- transaction.begin(tx)

  case tx {
    Ok(tx) -> {
      use data_result <- transaction.store_get(
        tx,
        store,
        glindex.Only(glindex.int(id)),
        track_decoder(),
      )
      next({
        use data <- result.try(data_result)
        Ok(data)
      })
    }
    Error(e) -> next(Error(e))
  }
}

pub fn get_all_tracks_by_artist(
  db: Database,
  artist: String,
  next: fn(Result(List(Track), IdbError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)

  let #(tx, store) = transaction.store(tx, track_store)

  let index = transaction.index(store, track_artist_index)

  use tx <- transaction.begin(tx)

  case tx {
    Ok(tx) -> {
      use data_result <- transaction.index_get_all(
        tx,
        index,
        glindex.Only(glindex.string(artist)),
        option.None,
        track_decoder(),
      )
      next({
        use data <- result.try(data_result)
        Ok(data)
      })
    }
    Error(e) -> next(Error(e))
  }
}

pub fn add_track(
  db: Database,
  track: Track,
  next: fn(Result(Track, IdbError)) -> a,
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
          #("album", glindex.string(track.album)),
          #("artist", glindex.string(track.artist)),
          #("duration", glindex.int(track.duration)),
        ]),
        decode.int,
      )

      case maybe_id {
        Ok(id) -> {
          use data_result <- transaction.store_get(
            tx,
            store,
            glindex.Only(glindex.int(id)),
            track_decoder(),
          )
          next({
            use data <- result.try(data_result)
            Ok(data)
          })
        }
        Error(e) -> next(Error(e))
      }
    }
    Error(e) -> next(Error(e))
  }
}

pub fn put_track(
  db: Database,
  track: Track,
  next: fn(Result(Track, IdbError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)

  let #(tx, store) = transaction.store(tx, track_store)

  use tx <- transaction.begin(tx)

  case tx {
    Ok(tx) -> {
      use maybe_id <- transaction.store_put(
        tx,
        store,
        glindex.object([
          #("id", glindex.int(track.id)),
          #("title", glindex.string(track.title)),
          #("album", glindex.string(track.album)),
          #("artist", glindex.string(track.artist)),
          #("duration", glindex.int(track.duration)),
        ]),
        decode.int,
      )

      case maybe_id {
        Ok(id) -> {
          use data_result <- transaction.store_get(
            tx,
            store,
            glindex.Only(glindex.int(id)),
            track_decoder(),
          )
          next({
            use data <- result.try(data_result)
            Ok(data)
          })
        }
        Error(e) -> next(Error(e))
      }
    }
    Error(e) -> next(Error(e))
  }
}

pub fn get_tracks_shorter_than(
  db: Database,
  max_duration: Int,
  next: fn(Result(List(Track), IdbError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)

  let #(tx, store) = transaction.store(tx, track_store)

  use tx <- transaction.begin(tx)

  case tx {
    Ok(tx) -> {
      use result <- transaction.store_open_cursor(
        tx,
        store,
        glindex.All,
        cursor.Next,
        [],
        fn(acc, cur, next) {
          case cursor.cursor_value(cur, track_decoder()) {
            Ok(track) if track.duration < max_duration -> {
              next([track, ..acc], cursor.continue())
            }
            _ -> {
              next(acc, cursor.continue())
            }
          }
        },
      )
      next(result)
    }
    Error(e) -> next(Error(e))
  }
}

pub fn delete_tracks_by_artist(
  db: Database,
  artist: String,
  next: fn(Result(Nil, IdbError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)

  let #(tx, store) = transaction.store(tx, track_store)

  let index = transaction.index(store, track_artist_index)

  use tx <- transaction.begin(tx)

  case tx {
    Ok(tx) -> {
      use result <- transaction.index_open_cursor(
        tx,
        index,
        glindex.Only(glindex.string(artist)),
        cursor.Next,
        Nil,
        fn(_, cur, next) {
          cursor.cursor_delete(cur)
          next(Nil, cursor.continue())
        },
      )
      next(result)
    }
    Error(e) -> next(Error(e))
  }
}

pub fn rename_artist(
  db: Database,
  old_name: String,
  new_name: String,
  next: fn(Result(Nil, IdbError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)

  let #(tx, store) = transaction.store(tx, track_store)

  let index = transaction.index(store, track_artist_index)

  use tx <- transaction.begin(tx)

  case tx {
    Ok(tx) -> {
      use result <- transaction.index_open_cursor(
        tx,
        index,
        glindex.Only(glindex.string(old_name)),
        cursor.Next,
        Nil,
        fn(_, cur, next) {
          case cursor.cursor_value(cur, track_decoder()) {
            Ok(track) -> {
              cursor.cursor_update(
                cur,
                glindex.object([
                  #("id", glindex.int(track.id)),
                  #("title", glindex.string(track.title)),
                  #("album", glindex.string(track.album)),
                  #("artist", glindex.string(new_name)),
                  #("duration", glindex.int(track.duration)),
                ]),
              )
              next(Nil, cursor.continue())
            }
            Error(_) -> next(Nil, cursor.stop())
          }
        },
      )
      next(result)
    }
    Error(e) -> next(Error(e))
  }
}

pub fn get_tracks_from_prolific_artists(
  db: Database,
  min_track_count: Int,
  next: fn(Result(List(Track), IdbError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_only)

  let #(tx, store) = transaction.store(tx, track_store)

  let index = transaction.index(store, track_artist_index)

  use tx <- transaction.begin(tx)

  case tx {
    Ok(tx) -> {
      use result <- transaction.store_open_cursor(
        tx,
        store,
        glindex.All,
        cursor.Next,
        [],
        fn(acc, cur, next) {
          case cursor.cursor_value(cur, track_decoder()) {
            Ok(track) -> {
              use count_result <- transaction.index_count(
                tx,
                index,
                glindex.Only(glindex.string(track.artist)),
              )
              case count_result {
                Ok(count) if count >= min_track_count ->
                  next([track, ..acc], cursor.continue())
                _ -> next(acc, cursor.continue())
              }
            }
            Error(_) -> next(acc, cursor.stop())
          }
        },
      )
      next(result)
    }
    Error(e) -> next(Error(e))
  }
}

pub fn delete_track(
  db: Database,
  id: Int,
  next: fn(Result(Track, IdbError)) -> a,
) -> a {
  let tx = transaction.prepare(db, transaction.read_write)

  let #(tx, store) = transaction.store(tx, track_store)

  use tx <- transaction.begin(tx)

  case tx {
    Ok(tx) -> {
      use data_result <- transaction.store_get(
        tx,
        store,
        glindex.Only(glindex.int(id)),
        track_decoder(),
      )
      case data_result {
        Ok(track) -> {
          use _ <- transaction.store_delete(
            tx,
            store,
            glindex.Only(glindex.int(id)),
          )
          next(Ok(track))
        }
        Error(e) -> next(Error(e))
      }
    }
    Error(e) -> next(Error(e))
  }
}
