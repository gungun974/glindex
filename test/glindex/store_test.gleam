import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option
import glindex
import glindex/database
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

pub fn store_add_test() -> Promise(Nil) {
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
          |> promise.map(fn(_) { Ok(Nil) })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_add_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_add_test_assert")
fn store_add_test_assert() -> Promise(Nil)

pub fn store_put_test() -> Promise(Nil) {
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
          |> promise.await(fn(_) { store.put(tx, my_store, #(1, "Bob")) })
          |> promise.map(fn(_) { Ok(Nil) })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_put_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_put_test_assert")
fn store_put_test_assert() -> Promise(Nil)

pub fn store_get_test() -> Promise(Nil) {
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
          |> promise.await(fn(_) { store.get(tx, my_store, glindex.Only(1)) })
          |> promise.map(fn(result) {
            let assert Ok(#(1, "Alice")) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_get_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_get_test_assert")
fn store_get_test_assert() -> Promise(Nil)

pub fn store_get_all_test() -> Promise(Nil) {
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
            store.get_all(tx, my_store, glindex.All, option.None)
          })
          |> promise.map(fn(result) {
            let assert Ok(ids) = result

            let assert 2 = list.length(ids)

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_get_all_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_get_all_test_assert")
fn store_get_all_test_assert() -> Promise(Nil)

pub fn store_get_key_test() -> Promise(Nil) {
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
          store.add(tx, my_store, #(42, "Alice"))
          |> promise.await(fn(_) {
            store.get_key(tx, my_store, glindex.Only(42))
          })
          |> promise.map(fn(result) {
            let assert Ok(42) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_get_key_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_get_key_test_assert")
fn store_get_key_test_assert() -> Promise(Nil)

pub fn store_get_all_keys_test() -> Promise(Nil) {
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
            store.get_all_keys(tx, my_store, glindex.All, option.None)
          })
          |> promise.map(fn(result) {
            let assert Ok([1, 2]) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_get_all_keys_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_get_all_keys_test_assert")
fn store_get_all_keys_test_assert() -> Promise(Nil)

pub fn store_count_test() -> Promise(Nil) {
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
          |> promise.await(fn(_) { store.count(tx, my_store, glindex.All) })
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
  |> promise.await(fn(_) { store_count_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_count_test_assert")
fn store_count_test_assert() -> Promise(Nil)

pub fn store_delete_test() -> Promise(Nil) {
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
          |> promise.await(fn(_) { store.delete(tx, my_store, glindex.Only(1)) })
          |> promise.map(fn(_) { Ok(Nil) })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_delete_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_delete_test_assert")
fn store_delete_test_assert() -> Promise(Nil)

pub fn store_clear_test() -> Promise(Nil) {
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
          |> promise.await(fn(_) { store.clear(tx, my_store) })
          |> promise.map(fn(_) { Ok(Nil) })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_clear_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_clear_test_assert")
fn store_clear_test_assert() -> Promise(Nil)

pub fn store_with_no_key_path_test() -> Promise(Nil) {
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) =
          transaction.store(
            builder,
            glindex.store(
              name: "my_store",
              to_value: fn(data: String, _) {
                glindex.object([
                  #("name", glindex.string(data)),
                ])
              },
              decoder: {
                use name <- decode.field("name", decode.string)
                decode.success(name)
              },
              to_key: fn(key) { glindex.int(key) },
              key_decoder: decode.int,
            ),
          )
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, "Alice")
          |> promise.await(fn(key) {
            let assert Ok(1) = key

            store.get(tx, my_store, glindex.Only(1))
          })
          |> promise.map(fn(result) {
            let assert Ok("Alice") = result
            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_with_no_key_path_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_with_no_key_path_test_assert")
fn store_with_no_key_path_test_assert() -> Promise(Nil)

pub fn store_with_composite_key_path_test() -> Promise(Nil) {
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
  |> promise.await(fn(maybe_db) {
    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let #(builder, my_store) =
          transaction.store(builder, {
            glindex.store(
              name: "my_store",
              to_value: fn(data: #(String, String), _) {
                glindex.object([
                  #("first_name", glindex.string(data.0)),
                  #("last_name", glindex.string(data.1)),
                ])
              },
              decoder: {
                use first_name <- decode.field("first_name", decode.string)
                use last_name <- decode.field("last_name", decode.string)
                decode.success(#(first_name, last_name))
              },
              to_key: fn(key: #(String, String)) {
                glindex.array([
                  glindex.string(key.0),
                  glindex.string(key.1),
                ])
              },
              key_decoder: {
                use first_name <- decode.field("first_name", decode.string)
                use last_name <- decode.field("last_name", decode.string)
                decode.success(#(first_name, last_name))
              },
            )
          })
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #("Alice", "Smith"))
          |> promise.await(fn(_) {
            store.get(tx, my_store, glindex.Only(#("Alice", "Smith")))
          })
          |> promise.map(fn(result) {
            let assert Ok(#("Alice", "Smith")) = result
            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  |> promise.map(fn(_) { Nil })
}

pub fn store_add_with_out_of_line_key_test() -> Promise(Nil) {
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
        let #(builder, my_store) =
          transaction.store(
            builder,
            glindex.store_with_out_of_line_key(
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
            ),
          )
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add_with_out_of_line_key(
            tx,
            my_store,
            #(0, "Alice"),
            glindex.int(42),
          )
          |> promise.map(fn(result) {
            let assert Ok(42) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  //! Assert
  |> promise.await(fn(_) { store_add_with_out_of_line_key_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_add_with_out_of_line_key_test_assert")
fn store_add_with_out_of_line_key_test_assert() -> Promise(Nil)

pub fn store_put_with_out_of_line_key_test() -> Promise(Nil) {
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
        let #(builder, my_store) =
          transaction.store(
            builder,
            glindex.store_with_out_of_line_key(
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
            ),
          )
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add_with_out_of_line_key(
            tx,
            my_store,
            #(0, "Alice"),
            glindex.int(42),
          )
          |> promise.await(fn(_) {
            store.put_with_out_of_line_key(
              tx,
              my_store,
              #(0, "Bob"),
              glindex.int(42),
            )
          })
          |> promise.map(fn(result) {
            let assert Ok(42) = result
            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  |> promise.map(fn(_) { Nil })
}

pub fn store_get_not_found_test() -> Promise(Nil) {
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
        let builder = transaction.prepare(db, transaction.read_only)
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.get(tx, my_store, glindex.Only(999))
          |> promise.map(fn(result) {
            let assert Error(transaction.NotFoundError) = result
            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  |> promise.map(fn(_) { Nil })
}

pub fn store_get_key_not_found_test() -> Promise(Nil) {
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
        let builder = transaction.prepare(db, transaction.read_only)
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.get_key(tx, my_store, glindex.Only(999))
          |> promise.map(fn(result) {
            let assert Error(transaction.NotFoundError) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  |> promise.map(fn(_) { Nil })
}

pub fn store_add_data_error_test() -> Promise(Nil) {
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
        let #(builder, my_store) =
          transaction.store(
            builder,
            glindex.store(
              name: "my_store",
              to_value: fn(_: #(Int, String), _) { glindex.null() },
              decoder: decode.success(#(0, "")),
              to_key: fn(_) { glindex.null() },
              key_decoder: decode.dynamic,
            ),
          )
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.map(fn(result) {
            let assert Error(transaction.DataError) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  |> promise.map(fn(_) { Nil })
}

pub fn store_add_constraint_error_test() -> Promise(Nil) {
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
        let #(builder, my_store) =
          transaction.store(
            builder,
            glindex.store(
              name: "my_store",
              to_value: fn(data: #(Int, String), _) {
                glindex.object([
                  #("id", glindex.int(data.0)),
                  #("name", glindex.string(data.1)),
                ])
              },
              decoder: {
                use id <- decode.field("id", decode.int)
                use name <- decode.field("name", decode.string)
                decode.success(#(id, name))
              },
              to_key: fn(key) { glindex.int(key) },
              key_decoder: decode.int,
            ),
          )
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(1, "Duplicate")) })
          |> promise.map(fn(result) {
            let assert Error(transaction.ConstraintError) = result

            Ok(Nil)
          })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
  })
  |> promise.map(fn(_) { Nil })
}
