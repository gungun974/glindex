import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/list
import glindex.{Store}
import glindex/database
import glindex/transaction
import glindex/upgrade

@external(javascript, "../glindex_test_ffi.mjs", "fake_indexeddb")
pub fn fake_indexeddb() -> Nil

pub fn create_store_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(_) =
      upgrade.create_store(tx, "my_store", upgrade.store_options())
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  //! Assert
  |> promise.await(fn(_) { create_store_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_store_test_assert")
fn create_store_test_assert() -> Promise(Nil)

pub fn create_store_with_key_path_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(_) =
      upgrade.create_store(
        tx,
        "my_store",
        upgrade.StoreOptions(
          key_path: upgrade.KeyPath("id"),
          auto_increment: False,
        ),
      )
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  //! Assert
  |> promise.await(fn(_) { create_store_with_key_path_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_store_with_key_path_test_assert")
fn create_store_with_key_path_test_assert() -> Promise(Nil)

pub fn create_store_with_auto_increment_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(_) =
      upgrade.create_store(
        tx,
        "my_store",
        upgrade.StoreOptions(
          key_path: upgrade.OutOfLineKey,
          auto_increment: True,
        ),
      )
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  //! Assert
  |> promise.await(fn(_) { create_store_with_auto_increment_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_store_with_auto_increment_test_assert")
fn create_store_with_auto_increment_test_assert() -> Promise(Nil)

pub fn delete_store_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act (first open at version 1)
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(_) =
      upgrade.create_store(tx, "my_store", upgrade.store_options())
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  //! Act (second open at version 2)
  |> promise.await(fn(_) {
    database.new("Hoi", 2)
    |> database.add_version(1, fn(tx) {
      let assert Ok(_) =
        upgrade.create_store(tx, "my_store", upgrade.store_options())
      Nil
    })
    |> database.add_version(2, fn(tx) {
      let assert Ok(_) = upgrade.delete_store(tx, "my_store")
      Nil
    })
    |> database.open()
    |> promise.map_try(fn(db) { Ok(database.close(db)) })
  })
  //! Assert
  |> promise.await(fn(_) { delete_store_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "delete_store_test_assert")
fn delete_store_test_assert() -> Promise(Nil)

pub fn create_index_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(tx, "my_store", upgrade.store_options())
    let idx = upgrade.index(store, "name_idx")
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        idx,
        upgrade.KeyPath("name"),
        upgrade.index_options(),
      )
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  //! Assert
  |> promise.await(fn(_) { create_index_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_index_test_assert")
fn create_index_test_assert() -> Promise(Nil)

pub fn create_unique_index_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(tx, "my_store", upgrade.store_options())
    let idx = upgrade.index(store, "email_idx")
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        idx,
        upgrade.KeyPath("email"),
        upgrade.IndexOptions(unique: True, multi_entry: False),
      )
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  //! Assert
  |> promise.await(fn(_) { create_unique_index_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_unique_index_test_assert")
fn create_unique_index_test_assert() -> Promise(Nil)

pub fn delete_index_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act (first open at version 1)
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(tx, "my_store", upgrade.store_options())
    let idx = upgrade.index(store, "name_idx")
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        idx,
        upgrade.KeyPath("name"),
        upgrade.index_options(),
      )
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  //! Act (second open at version 2)
  |> promise.await(fn(_) {
    database.new("Hoi", 2)
    |> database.add_version(1, fn(tx) {
      let assert Ok(store) =
        upgrade.create_store(tx, "my_store", upgrade.store_options())
      let idx = upgrade.index(store, "name_idx")
      let assert Ok(_) =
        upgrade.create_index(
          tx,
          idx,
          upgrade.KeyPath("name"),
          upgrade.index_options(),
        )
      Nil
    })
    |> database.add_version(2, fn(tx) {
      let store = upgrade.store(tx, "my_store")
      let idx = upgrade.index(store, "name_idx")
      let assert Ok(_) = upgrade.delete_index(tx, idx)
      Nil
    })
    |> database.open()
    |> promise.map_try(fn(db) { Ok(database.close(db)) })
  })
  //! Assert
  |> promise.await(fn(_) { delete_index_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "delete_index_test_assert")
fn delete_index_test_assert() -> Promise(Nil)

pub fn create_store_with_composite_key_path_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(_) =
      upgrade.create_store(
        tx,
        "my_store",
        upgrade.StoreOptions(
          key_path: upgrade.CompositeKeyPath(["first_name", "last_name"]),
          auto_increment: False,
        ),
      )
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  //! Assert
  |> promise.await(fn(_) { create_store_with_composite_key_path_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_store_with_composite_key_path_test_assert")
fn create_store_with_composite_key_path_test_assert() -> Promise(Nil)

pub fn create_index_with_composite_key_path_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(tx, "my_store", upgrade.store_options())
    let idx = upgrade.index(store, "location_idx")
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        idx,
        upgrade.CompositeKeyPath(["city", "country"]),
        upgrade.index_options(),
      )
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  //! Assert
  |> promise.await(fn(_) { create_index_with_composite_key_path_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_index_with_composite_key_path_test_assert")
fn create_index_with_composite_key_path_test_assert() -> Promise(Nil)

pub fn store_key_path_out_of_line_key_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(tx, "my_store", upgrade.store_options())
    let assert Ok(upgrade.OutOfLineKey) = upgrade.store_key_path(tx, store)
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  |> promise.map(fn(_) { Nil })
}

pub fn store_key_path_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(
        tx,
        "my_store",
        upgrade.StoreOptions(
          key_path: upgrade.KeyPath("id"),
          auto_increment: False,
        ),
      )
    let assert Ok(upgrade.KeyPath("id")) = upgrade.store_key_path(tx, store)
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  |> promise.map(fn(_) { Nil })
}

pub fn store_key_path_composite_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(
        tx,
        "my_store",
        upgrade.StoreOptions(
          key_path: upgrade.CompositeKeyPath(["first_name", "last_name"]),
          auto_increment: False,
        ),
      )
    let assert Ok(upgrade.CompositeKeyPath(["first_name", "last_name"])) =
      upgrade.store_key_path(tx, store)
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  |> promise.map(fn(_) { Nil })
}

pub fn store_auto_increment_true_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(
        tx,
        "my_store",
        upgrade.StoreOptions(
          key_path: upgrade.OutOfLineKey,
          auto_increment: True,
        ),
      )
    let assert Ok(True) = upgrade.store_auto_increment(tx, store)
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  |> promise.map(fn(_) { Nil })
}

pub fn store_auto_increment_false_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(
        tx,
        "my_store",
        upgrade.StoreOptions(
          key_path: upgrade.KeyPath("id"),
          auto_increment: False,
        ),
      )
    let assert Ok(False) = upgrade.store_auto_increment(tx, store)
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  |> promise.map(fn(_) { Nil })
}

pub fn index_key_path_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(tx, "my_store", upgrade.store_options())
    let idx = upgrade.index(store, "name_idx")
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        idx,
        upgrade.KeyPath("name"),
        upgrade.index_options(),
      )
    let assert Ok(upgrade.KeyPath("name")) = upgrade.index_key_path(tx, idx)
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  |> promise.map(fn(_) { Nil })
}

pub fn index_unique_true_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(tx, "my_store", upgrade.store_options())
    let idx = upgrade.index(store, "email_idx")
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        idx,
        upgrade.KeyPath("email"),
        upgrade.IndexOptions(unique: True, multi_entry: False),
      )
    let assert Ok(True) = upgrade.index_unique(tx, idx)
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  |> promise.map(fn(_) { Nil })
}

pub fn index_unique_false_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(tx, "my_store", upgrade.store_options())
    let idx = upgrade.index(store, "name_idx")
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        idx,
        upgrade.KeyPath("name"),
        upgrade.index_options(),
      )
    let assert Ok(False) = upgrade.index_unique(tx, idx)
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  |> promise.map(fn(_) { Nil })
}

pub fn index_multi_entry_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(tx, "my_store", upgrade.store_options())
    let idx = upgrade.index(store, "tags_idx")
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        idx,
        upgrade.KeyPath("tags"),
        upgrade.IndexOptions(unique: False, multi_entry: True),
      )
    let assert Ok(True) = upgrade.index_multi_entry(tx, idx)
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  |> promise.map(fn(_) { Nil })
}

pub fn rename_store_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act (create at version 1)
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(_) =
      upgrade.create_store(tx, "old_store", upgrade.store_options())
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  //! Act (rename at version 2)
  |> promise.await(fn(_) {
    database.new("Hoi", 2)
    |> database.add_version(1, fn(tx) {
      let assert Ok(_) =
        upgrade.create_store(tx, "old_store", upgrade.store_options())
      Nil
    })
    |> database.add_version(2, fn(tx) {
      let store = upgrade.store(tx, "old_store")
      let assert Ok(_) = upgrade.rename_store(tx, store, "new_store")
      Nil
    })
    |> database.open()
    |> promise.map_try(fn(db) { Ok(database.close(db)) })
  })
  //! Assert
  |> promise.await(fn(_) { rename_store_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "rename_store_test_assert")
fn rename_store_test_assert() -> Promise(Nil)

pub fn rename_index_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act (create at version 1)
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(store) =
      upgrade.create_store(tx, "my_store", upgrade.store_options())
    let idx = upgrade.index(store, "old_idx")
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        idx,
        upgrade.KeyPath("name"),
        upgrade.index_options(),
      )
    Nil
  })
  |> database.open()
  |> promise.map_try(fn(db) { Ok(database.close(db)) })
  //! Act (rename at version 2)
  |> promise.await(fn(_) {
    database.new("Hoi", 2)
    |> database.add_version(1, fn(tx) {
      let assert Ok(store) =
        upgrade.create_store(tx, "my_store", upgrade.store_options())
      let idx = upgrade.index(store, "old_idx")
      let assert Ok(_) =
        upgrade.create_index(
          tx,
          idx,
          upgrade.KeyPath("name"),
          upgrade.index_options(),
        )
      Nil
    })
    |> database.add_version(2, fn(tx) {
      let store = upgrade.store(tx, "my_store")
      let idx = upgrade.index(store, "old_idx")
      let assert Ok(_) = upgrade.rename_index(tx, idx, "new_idx")
      Nil
    })
    |> database.open()
    |> promise.map_try(fn(db) { Ok(database.close(db)) })
  })
  //! Assert
  |> promise.await(fn(_) { rename_index_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "rename_index_test_assert")
fn rename_index_test_assert() -> Promise(Nil)

pub fn object_store_names_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(_) =
      upgrade.create_store(
        tx,
        "store_a",
        upgrade.StoreOptions(
          key_path: upgrade.KeyPath("id"),
          auto_increment: False,
        ),
      )
    let assert Ok(_) =
      upgrade.create_store(
        tx,
        "store_b",
        upgrade.StoreOptions(
          key_path: upgrade.KeyPath("id"),
          auto_increment: False,
        ),
      )
    Nil
  })
  |> database.open()
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_only)
        let #(builder, _) =
          transaction.store(
            builder,
            Store(
              name: "store_a",
              to_value: fn(_, _) { glindex.null() },
              decoder: decode.dynamic,
              to_key: fn(_) { glindex.null() },
              key_decoder: decode.dynamic,
            ),
          )
        let #(builder, _) =
          transaction.store(
            builder,
            Store(
              name: "store_b",
              to_value: fn(_, _) { glindex.null() },
              decoder: decode.dynamic,
              to_key: fn(_) { glindex.null() },
              key_decoder: decode.dynamic,
            ),
          )
        promise.map_try(transaction.begin(builder), fn(tx) {
          let names = upgrade.object_store_names(tx)

          let assert 2 = list.length(names)
          let assert True = list.contains(names, "store_a")
          let assert True = list.contains(names, "store_b")

          Ok(Nil)
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  |> promise.map(fn(_) { Nil })
}

pub fn index_names_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  database.new("Hoi", 1)
  |> database.add_version(1, fn(tx) {
    let assert Ok(s) =
      upgrade.create_store(
        tx,
        "my_store",
        upgrade.StoreOptions(
          key_path: upgrade.KeyPath("id"),
          auto_increment: False,
        ),
      )
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        upgrade.index(s, "name_idx"),
        upgrade.KeyPath("name"),
        upgrade.index_options(),
      )
    let assert Ok(_) =
      upgrade.create_index(
        tx,
        upgrade.index(s, "age_idx"),
        upgrade.KeyPath("age"),
        upgrade.index_options(),
      )
    Nil
  })
  |> database.open()
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_only)
        let #(builder, my_store) =
          transaction.store(
            builder,
            Store(
              name: "my_store",
              to_value: fn(_, _) { glindex.null() },
              decoder: decode.dynamic,
              to_key: fn(_) { glindex.null() },
              key_decoder: decode.dynamic,
            ),
          )
        promise.map_try(transaction.begin(builder), fn(tx) {
          let assert Ok(names) = upgrade.index_names(tx, my_store)

          let assert 2 = list.length(names)
          let assert True = list.contains(names, "name_idx")
          let assert True = list.contains(names, "age_idx")

          Ok(Nil)
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  |> promise.map(fn(_) { Nil })
}
