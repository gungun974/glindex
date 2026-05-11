import gleam/javascript/promise.{type Promise}
import glindex/database
import glindex/upgrade

@external(javascript, "../glindex_test_ffi.mjs", "fake_indexeddb")
pub fn fake_indexeddb() -> Nil

pub fn create_store_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.add_version(1, fn(tx) {
      let _ = upgrade.create_store(tx, "my_store", upgrade.store_options())
      Nil
    })
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { create_store_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_store_test_assert")
fn create_store_test_assert() -> Promise(Nil)

pub fn create_store_with_key_path_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.add_version(1, fn(tx) {
      let _ =
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { create_store_with_key_path_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_store_with_key_path_test_assert")
fn create_store_with_key_path_test_assert() -> Promise(Nil)

pub fn create_store_with_auto_increment_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.add_version(1, fn(tx) {
      let _ =
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { create_store_with_auto_increment_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_store_with_auto_increment_test_assert")
fn create_store_with_auto_increment_test_assert() -> Promise(Nil)

pub fn delete_store_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act (first open at version 1)
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.add_version(1, fn(tx) {
      let _ = upgrade.create_store(tx, "my_store", upgrade.store_options())
      Nil
    })
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Act (second open at version 2)
  |> promise.await(fn(_) {
    promise.new(fn(resolve) {
      database.new("Hoi", 2)
      |> database.add_version(1, fn(tx) {
        let _ = upgrade.create_store(tx, "my_store", upgrade.store_options())
        Nil
      })
      |> database.add_version(2, fn(tx) { upgrade.delete_store(tx, "my_store") })
      |> database.open(fn(maybe_db) {
        case maybe_db {
          Error(_) -> resolve(Nil)
          Ok(db) -> {
            database.close(db)
            resolve(Nil)
          }
        }
      })
    })
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
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.add_version(1, fn(tx) {
      let store = upgrade.create_store(tx, "my_store", upgrade.store_options())
      let idx = upgrade.index(store, "name_idx")
      let _ =
        upgrade.create_index(
          tx,
          idx,
          upgrade.KeyPath("name"),
          upgrade.index_options(),
        )
      Nil
    })
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { create_index_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_index_test_assert")
fn create_index_test_assert() -> Promise(Nil)

pub fn create_unique_index_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.add_version(1, fn(tx) {
      let store = upgrade.create_store(tx, "my_store", upgrade.store_options())
      let idx = upgrade.index(store, "email_idx")
      let _ =
        upgrade.create_index(
          tx,
          idx,
          upgrade.KeyPath("email"),
          upgrade.IndexOptions(unique: True, multi_entry: False),
        )
      Nil
    })
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { create_unique_index_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_unique_index_test_assert")
fn create_unique_index_test_assert() -> Promise(Nil)

pub fn delete_index_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act (first open at version 1)
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.add_version(1, fn(tx) {
      let store = upgrade.create_store(tx, "my_store", upgrade.store_options())
      let idx = upgrade.index(store, "name_idx")
      let _ =
        upgrade.create_index(
          tx,
          idx,
          upgrade.KeyPath("name"),
          upgrade.index_options(),
        )
      Nil
    })
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Act (second open at version 2)
  |> promise.await(fn(_) {
    promise.new(fn(resolve) {
      database.new("Hoi", 2)
      |> database.add_version(1, fn(tx) {
        let store =
          upgrade.create_store(tx, "my_store", upgrade.store_options())
        let idx = upgrade.index(store, "name_idx")
        let _ =
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
        upgrade.delete_index(tx, idx)
      })
      |> database.open(fn(maybe_db) {
        case maybe_db {
          Error(_) -> resolve(Nil)
          Ok(db) -> {
            database.close(db)
            resolve(Nil)
          }
        }
      })
    })
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
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.add_version(1, fn(tx) {
      let _ =
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { create_store_with_composite_key_path_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_store_with_composite_key_path_test_assert")
fn create_store_with_composite_key_path_test_assert() -> Promise(Nil)

pub fn create_index_with_composite_key_path_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.add_version(1, fn(tx) {
      let store = upgrade.create_store(tx, "my_store", upgrade.store_options())
      let idx = upgrade.index(store, "location_idx")
      let _ =
        upgrade.create_index(
          tx,
          idx,
          upgrade.CompositeKeyPath(["city", "country"]),
          upgrade.index_options(),
        )
      Nil
    })
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { create_index_with_composite_key_path_test_assert() })
}

@external(javascript, "./upgrade_test_ffi.mjs", "create_index_with_composite_key_path_test_assert")
fn create_index_with_composite_key_path_test_assert() -> Promise(Nil)
