import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/option
import glindex
import glindex/cursor
import glindex/database
import glindex/index
import glindex/store
import glindex/transaction
import glindex/upgrade

@external(javascript, "../glindex_test_ffi.mjs", "fake_indexeddb")
pub fn fake_indexeddb() -> Nil

fn test_store() {
  glindex.store(
    name: "my_store",
    to_value: fn(data: #(Int, String), _) {
      case data.0 {
        0 -> {
          glindex.object([
            #("name", glindex.string(data.1)),
          ])
        }
        _ ->
          glindex.object([
            #("id", glindex.int(data.0)),
            #("name", glindex.string(data.1)),
          ])
      }
    },
    decoder: {
      use id <- decode.field("id", decode.int)
      use name <- decode.field("name", decode.string)
      decode.success(#(id, name))
    },
    to_key: fn(key) { glindex.int(key) },
    key_decoder: decode.int,
  )
}

fn test_index() {
  glindex.index(
    name: "name_idx",
    to_index_key: fn(key) { glindex.string(key) },
    index_key_decoder: decode.string,
  )
}

pub fn store_open_cursor_test() -> Promise(Nil) {
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(2, "Bob")) })
          |> promise.await(fn(_) { store.add(tx, my_store, #(3, "Charlie")) })
          |> promise.await(fn(_) {
            store.open_cursor(
              tx,
              my_store,
              glindex.All,
              cursor.Next,
              0,
              fn(count, _) { promise.resolve(#(count + 1, cursor.continue())) },
            )
          })
          |> promise.map(fn(result) {
            let assert Ok(3) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_open_cursor_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "store_open_cursor_test_assert")
fn store_open_cursor_test_assert() -> Promise(Nil)

pub fn store_open_cursor_prev_test() -> Promise(Nil) {
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(2, "Bob")) })
          |> promise.await(fn(_) { store.add(tx, my_store, #(3, "Charlie")) })
          |> promise.await(fn(_) {
            store.open_cursor(
              tx,
              my_store,
              glindex.All,
              cursor.Prev,
              option.None,
              fn(state, cur) {
                case cursor.cursor_value(cur) {
                  Ok(name) ->
                    promise.resolve(#(option.Some(name), cursor.stop()))
                  Error(_) -> promise.resolve(#(state, cursor.stop()))
                }
              },
            )
          })
          |> promise.map(fn(result) {
            let assert Ok(option.Some(#(3, "Charlie"))) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_open_cursor_prev_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "store_open_cursor_prev_test_assert")
fn store_open_cursor_prev_test_assert() -> Promise(Nil)

pub fn store_open_cursor_stop_test() -> Promise(Nil) {
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(2, "Bob")) })
          |> promise.await(fn(_) { store.add(tx, my_store, #(3, "Charlie")) })
          |> promise.await(fn(_) {
            store.open_cursor(
              tx,
              my_store,
              glindex.All,
              cursor.Next,
              0,
              fn(count, _) { promise.resolve(#(count + 1, cursor.stop())) },
            )
          })
          |> promise.map(fn(result) {
            let assert Ok(1) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_open_cursor_stop_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "store_open_cursor_stop_test_assert")
fn store_open_cursor_stop_test_assert() -> Promise(Nil)

pub fn store_open_cursor_advance_test() -> Promise(Nil) {
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(2, "Bob")) })
          |> promise.await(fn(_) { store.add(tx, my_store, #(3, "Charlie")) })
          |> promise.await(fn(_) {
            store.open_cursor(
              tx,
              my_store,
              glindex.All,
              cursor.Next,
              #(False, 0),
              fn(state, _) {
                let #(advanced, count) = state
                case advanced {
                  False -> promise.resolve(#(#(True, count), cursor.advance(2)))
                  True ->
                    promise.resolve(#(#(True, count + 1), cursor.continue()))
                }
              },
            )
          })
          |> promise.map(fn(result) {
            let assert Ok(#(_, count)) = result
            let assert 1 = count

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_open_cursor_advance_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "store_open_cursor_advance_test_assert")
fn store_open_cursor_advance_test_assert() -> Promise(Nil)

pub fn store_open_cursor_continue_key_test() -> Promise(Nil) {
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(2, "Bob")) })
          |> promise.await(fn(_) { store.add(tx, my_store, #(3, "Charlie")) })
          |> promise.await(fn(_) {
            store.open_cursor(
              tx,
              my_store,
              glindex.All,
              cursor.Next,
              0,
              fn(count, _) {
                let next = case count {
                  0 -> cursor.continue_key(3)
                  _ -> cursor.stop()
                }
                promise.resolve(#(count + 1, next))
              },
            )
          })
          |> promise.map(fn(result) {
            let assert Ok(2) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_open_cursor_continue_key_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "store_open_cursor_continue_key_test_assert")
fn store_open_cursor_continue_key_test_assert() -> Promise(Nil)

pub fn store_open_key_cursor_test() -> Promise(Nil) {
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(2, "Bob")) })
          |> promise.await(fn(_) {
            store.open_key_cursor(
              tx,
              my_store,
              glindex.All,
              cursor.Next,
              0,
              fn(count, _) { promise.resolve(#(count + 1, cursor.continue())) },
            )
          })
          |> promise.map(fn(result) {
            let assert Ok(2) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_open_key_cursor_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "store_open_key_cursor_test_assert")
fn store_open_key_cursor_test_assert() -> Promise(Nil)

pub fn index_open_cursor_test() -> Promise(Nil) {
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
    let idx = upgrade.index(s, "name_idx")
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        let name_idx = transaction.index(my_store, test_index())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(2, "Bob")) })
          |> promise.await(fn(_) {
            index.open_cursor(
              tx,
              name_idx,
              glindex.All,
              cursor.Next,
              0,
              fn(count, _) { promise.resolve(#(count + 1, cursor.continue())) },
            )
          })
          |> promise.map(fn(result) {
            let assert Ok(2) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { index_open_cursor_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "index_open_cursor_test_assert")
fn index_open_cursor_test_assert() -> Promise(Nil)

pub fn index_open_cursor_continue_primary_key_test() -> Promise(Nil) {
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
    let idx = upgrade.index(s, "name_idx")
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        let name_idx = transaction.index(my_store, test_index())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(2, "Bob")) })
          |> promise.await(fn(_) { store.add(tx, my_store, #(3, "Charlie")) })
          |> promise.await(fn(_) {
            index.open_cursor(
              tx,
              name_idx,
              glindex.All,
              cursor.Next,
              0,
              fn(count, _) {
                let next = case count {
                  0 -> cursor.continue_primary_key("Charlie", 3)
                  _ -> cursor.stop()
                }
                promise.resolve(#(count + 1, next))
              },
            )
          })
          |> promise.map(fn(result) {
            let assert Ok(2) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) {
    index_open_cursor_continue_primary_key_test_assert()
  })
}

@external(javascript, "./cursor_test_ffi.mjs", "index_open_cursor_continue_primary_key_test_assert")
fn index_open_cursor_continue_primary_key_test_assert() -> Promise(Nil)

pub fn index_open_key_cursor_test() -> Promise(Nil) {
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
    let idx = upgrade.index(s, "name_idx")
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        let name_idx = transaction.index(my_store, test_index())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(2, "Bob")) })
          |> promise.await(fn(_) {
            index.open_key_cursor(
              tx,
              name_idx,
              glindex.All,
              cursor.Next,
              0,
              fn(count, _) { promise.resolve(#(count + 1, cursor.continue())) },
            )
          })
          |> promise.map(fn(result) {
            let assert Ok(2) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { index_open_key_cursor_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "index_open_key_cursor_test_assert")
fn index_open_key_cursor_test_assert() -> Promise(Nil)

pub fn cursor_delete_test() -> Promise(Nil) {
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(2, "Bob")) })
          |> promise.await(fn(_) {
            store.open_cursor(
              tx,
              my_store,
              glindex.All,
              cursor.Next,
              Nil,
              fn(_, cur) {
                cursor.cursor_delete(cur)
                |> promise.map(fn(_) { #(Nil, cursor.continue()) })
              },
            )
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { cursor_delete_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "cursor_delete_test_assert")
fn cursor_delete_test_assert() -> Promise(Nil)

pub fn cursor_update_test() -> Promise(Nil) {
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) {
            store.open_cursor(
              tx,
              my_store,
              glindex.All,
              cursor.Next,
              Nil,
              fn(_, cur) {
                cursor.cursor_update(cur, #(1, "Updated"))
                |> promise.map(fn(_) { #(Nil, cursor.stop()) })
              },
            )
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { cursor_update_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "cursor_update_test_assert")
fn cursor_update_test_assert() -> Promise(Nil)

pub fn cursor_delete_returns_ok_test() -> Promise(Nil) {
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) {
            store.open_cursor(
              tx,
              my_store,
              glindex.All,
              cursor.Next,
              Nil,
              fn(_, cur) {
                cursor.cursor_delete(cur)
                |> promise.map(fn(result) {
                  let assert Ok(Nil) = result

                  #(Nil, cursor.stop())
                })
              },
            )
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  |> promise.map(fn(_) { Nil })
}

pub fn cursor_update_returns_ok_test() -> Promise(Nil) {
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) {
            store.open_cursor(
              tx,
              my_store,
              glindex.All,
              cursor.Next,
              Nil,
              fn(_, cur) {
                cursor.cursor_update(cur, #(1, "Updated"))
                |> promise.map(fn(result) {
                  let assert Ok(Nil) = result
                  #(Nil, cursor.stop())
                })
              },
            )
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  |> promise.map(fn(_) { Nil })
}
