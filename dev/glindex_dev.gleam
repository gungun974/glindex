import app/entity.{Track}
import app/repository
import glindex/database
import glindex/upgrade

pub fn main() -> Nil {
  database.new("Music", 2)
  |> database.add_version(1, fn(tx) {
    let store =
      upgrade.create_store(
        tx,
        "tracks",
        upgrade.StoreOptions(
          key_path: upgrade.KeyPath("id"),
          auto_increment: True,
        ),
      )
    upgrade.create_index(
      tx,
      upgrade.index(store, "tracks_artist"),
      upgrade.KeyPath("artist"),
      upgrade.index_options(),
    )
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
    upgrade.delete_index(tx, upgrade.index(store, "tracks_album"))
    upgrade.create_index(
      tx,
      upgrade.index(store, "tracks_artist_and_album"),
      upgrade.CompositeKeyPath(["artist", "album"]),
      upgrade.index_options(),
    )
    Nil
  })
  |> database.open(fn(maybe_db) {
    case maybe_db {
      Error(_) -> Nil
      Ok(db) -> {
        use _ <- repository.add_track(
          db,
          Track(
            id: 0,
            title: "Bohemian Rhapsody",
            album: "A Night at the Opera",
            artist: "Queen",
            duration: 354,
          ),
        )
        use _ <- repository.add_track(
          db,
          Track(
            id: 0,
            title: "We Will Rock You",
            album: "News of the World",
            artist: "Queen",
            duration: 122,
          ),
        )
        use _ <- repository.add_track(
          db,
          Track(
            id: 0,
            title: "Stairway to Heaven",
            album: "Led Zeppelin IV",
            artist: "Led Zeppelin",
            duration: 482,
          ),
        )

        use track <- repository.get_track(db, 1)
        echo track

        use by_artist <- repository.get_all_tracks_by_artist(db, "Queen")
        echo by_artist

        use short <- repository.get_tracks_shorter_than(db, 200)
        echo short

        database.close(db)
      }
    }
  })
}
