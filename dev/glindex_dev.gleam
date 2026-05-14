import app/entity.{Track}
import app/repository
import gleam/javascript/promise
import glindex/database
import glindex/upgrade

@external(javascript, "./glindex_dev_ffi.mjs", "fake_indexeddb")
pub fn fake_indexeddb() -> Nil

pub fn main() -> Nil {
  // This is needed to be able to test IndexedDB-dependent code in Node.js.
  // You don't want to do that in a browser
  fake_indexeddb()

  database.new("Music", 2)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
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
        upgrade.index(store, "tracks_artist"),
        upgrade.KeyPath("artist"),
        upgrade.index_options(),
      )
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        upgrade.index(store, "tracks_album"),
        upgrade.KeyPath("album"),
        upgrade.index_options(),
      )
    Nil
  })
  |> database.add_version(2, fn(tx) {
    let store = upgrade.store(tx, "tracks")
    let assert Ok(_) =
      upgrade.delete_index(tx, upgrade.index(store, "tracks_album"))
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        upgrade.index(store, "tracks_artist_and_album"),
        upgrade.CompositeKeyPath(["artist", "album"]),
        upgrade.index_options(),
      )
    Nil
  })
  |> database.open()
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Ok(db) -> {
        use _ <- promise.await(repository.add_track(
          db,
          Track(
            id: 0,
            title: "Bohemian Rhapsody",
            album: "A Night at the Opera",
            artist: "Queen",
            duration: 354,
          ),
        ))
        use _ <- promise.await(repository.add_track(
          db,
          Track(
            id: 0,
            title: "We Will Rock You",
            album: "News of the World",
            artist: "Queen",
            duration: 122,
          ),
        ))
        use _ <- promise.await(repository.add_track(
          db,
          Track(
            id: 0,
            title: "Stairway to Heaven",
            album: "Led Zeppelin IV",
            artist: "Led Zeppelin",
            duration: 482,
          ),
        ))

        use track <- promise.await(repository.get_track(db, 1))
        let _ = echo track

        use by_artist <- promise.await(repository.get_all_tracks_by_artist(
          db,
          "Queen",
        ))
        let _ = echo by_artist

        use short <- promise.await(repository.get_tracks_shorter_than(db, 200))
        let _ = echo short

        database.close(db)

        promise.resolve(Nil)
      }
      Error(_) -> promise.resolve(Nil)
    }
  })
  Nil
}
