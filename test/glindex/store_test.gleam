import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option
import glindex.{Store}
import glindex/cursor
import glindex/database
import glindex/store
import glindex/upgrade

@external(javascript, "../glindex_test_ffi.mjs", "fake_indexeddb")
pub fn fake_indexeddb() -> Nil

pub fn add_test() -> Promise(Nil) {
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
          use key <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          let assert Ok(1) = key

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { add_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "add_test_assert")
fn add_test_assert() -> Promise(Nil)

pub fn put_test() -> Promise(Nil) {
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
          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          use _ <- store.put(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Bob")),
            ]),
            decode.int,
          )

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { put_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "put_test_assert")
fn put_test_assert() -> Promise(Nil)

pub fn get_test() -> Promise(Nil) {
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
          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          use result <- store.get(
            db,
            Store("my_store"),
            glindex.Only(glindex.int(1)),
            decode.field("name", decode.string, decode.success),
          )

          let assert Ok("Alice") = result

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { get_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "get_test_assert")
fn get_test_assert() -> Promise(Nil)

pub fn get_all_test() -> Promise(Nil) {
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
          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(2)),
              #("name", glindex.string("Bob")),
            ]),
            decode.int,
          )

          use result <- store.get_all(
            db,
            Store("my_store"),
            glindex.All,
            option.None,
            decode.field("id", decode.int, decode.success),
          )

          let assert Ok(ids) = result
          let assert 2 = list.length(ids)

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { get_all_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "get_all_test_assert")
fn get_all_test_assert() -> Promise(Nil)

pub fn get_key_test() -> Promise(Nil) {
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
          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(42)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          use result <- store.get_key(
            db,
            Store("my_store"),
            glindex.Only(glindex.int(42)),
            decode.int,
          )

          let assert Ok(42) = result

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { get_key_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "get_key_test_assert")
fn get_key_test_assert() -> Promise(Nil)

pub fn get_all_keys_test() -> Promise(Nil) {
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
          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(2)),
              #("name", glindex.string("Bob")),
            ]),
            decode.int,
          )

          use result <- store.get_all_keys(
            db,
            Store("my_store"),
            glindex.All,
            option.None,
            decode.int,
          )

          let assert Ok(keys) = result
          let assert 2 = list.length(keys)

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { get_all_keys_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "get_all_keys_test_assert")
fn get_all_keys_test_assert() -> Promise(Nil)

pub fn count_test() -> Promise(Nil) {
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
          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(2)),
              #("name", glindex.string("Bob")),
            ]),
            decode.int,
          )

          use result <- store.count(db, Store("my_store"), glindex.All)

          let assert Ok(2) = result

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { count_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "count_test_assert")
fn count_test_assert() -> Promise(Nil)

pub fn delete_test() -> Promise(Nil) {
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
          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          use _ <- store.delete(
            db,
            Store("my_store"),
            glindex.Only(glindex.int(1)),
          )

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { delete_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "delete_test_assert")
fn delete_test_assert() -> Promise(Nil)

pub fn clear_test() -> Promise(Nil) {
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
          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(2)),
              #("name", glindex.string("Bob")),
            ]),
            decode.int,
          )

          use _ <- store.clear(db, Store("my_store"))

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { clear_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "clear_test_assert")
fn clear_test_assert() -> Promise(Nil)

pub fn open_cursor_test() -> Promise(Nil) {
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
          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(2)),
              #("name", glindex.string("Bob")),
            ]),
            decode.int,
          )

          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(3)),
              #("name", glindex.string("Charlie")),
            ]),
            decode.int,
          )

          use result <- store.open_cursor(
            db,
            Store("my_store"),
            glindex.All,
            cursor.Next,
            0,
            fn(count, _, next) { next(count + 1, cursor.continue()) },
          )

          let assert Ok(3) = result

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { open_cursor_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "open_cursor_test_assert")
fn open_cursor_test_assert() -> Promise(Nil)

pub fn open_cursor_rw_test() -> Promise(Nil) {
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
          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(2)),
              #("name", glindex.string("Bob")),
            ]),
            decode.int,
          )

          use _ <- store.open_cursor_rw(
            db,
            Store("my_store"),
            glindex.All,
            cursor.Next,
            Nil,
            fn(_, cur, next) {
              use _ <- cursor.cursor_delete(cur)
              next(Nil, cursor.continue())
            },
          )

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { open_cursor_rw_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "open_cursor_rw_test_assert")
fn open_cursor_rw_test_assert() -> Promise(Nil)

pub fn open_key_cursor_test() -> Promise(Nil) {
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
          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(2)),
              #("name", glindex.string("Bob")),
            ]),
            decode.int,
          )

          use result <- store.open_key_cursor(
            db,
            Store("my_store"),
            glindex.All,
            cursor.Next,
            0,
            fn(count, _, next) { next(count + 1, cursor.continue()) },
          )

          let assert Ok(2) = result

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { open_key_cursor_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "open_key_cursor_test_assert")
fn open_key_cursor_test_assert() -> Promise(Nil)

pub fn open_key_cursor_rw_test() -> Promise(Nil) {
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
          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(1)),
              #("name", glindex.string("Alice")),
            ]),
            decode.int,
          )

          use _ <- store.add(
            db,
            Store("my_store"),
            glindex.object([
              #("id", glindex.int(2)),
              #("name", glindex.string("Bob")),
            ]),
            decode.int,
          )

          use result <- store.open_key_cursor_rw(
            db,
            Store("my_store"),
            glindex.All,
            cursor.Next,
            0,
            fn(count, _, next) { next(count + 1, cursor.continue()) },
          )

          let assert Ok(2) = result

          database.close(db)
          resolve(Nil)
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { open_key_cursor_rw_test_assert() })
}

@external(javascript, "./store_test_ffi.mjs", "open_key_cursor_rw_test_assert")
fn open_key_cursor_rw_test_assert() -> Promise(Nil)
