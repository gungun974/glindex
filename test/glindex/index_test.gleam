import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option
import glindex.{Index, Store}
import glindex/database
import glindex/index
import glindex/store
import glindex/transaction
import glindex/upgrade

@external(javascript, "../glindex_test_ffi.mjs", "fake_indexeddb")
pub fn fake_indexeddb() -> Nil

fn test_store() {
  Store(
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
    key_decoder: decode.int,
  )
}

fn test_index() {
  Index(name: "name_idx")
}

pub fn index_get_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          let builder = transaction.prepare(db, transaction.read_write)
          let #(builder, my_store) = transaction.store(builder, test_store())
          let name_idx = transaction.index(my_store, test_index())
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(tx, my_store, #(1, "Alice"))

                use result <- index.get(
                  tx,
                  name_idx,
                  glindex.Only(glindex.string("Alice")),
                )

                let assert Ok(#(1, "Alice")) = result

                database.close(db)

                resolve(Nil)
              }
            }
          })
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { index_get_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "index_get_test_assert")
fn index_get_test_assert() -> Promise(Nil)

pub fn index_get_key_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          let builder = transaction.prepare(db, transaction.read_write)
          let #(builder, my_store) = transaction.store(builder, test_store())
          let name_idx = transaction.index(my_store, test_index())
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(tx, my_store, #(1, "Alice"))

                use result <- index.get_key(
                  tx,
                  name_idx,
                  glindex.Only(glindex.string("Alice")),
                )

                let assert Ok(1) = result

                database.close(db)

                resolve(Nil)
              }
            }
          })
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { index_get_key_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "index_get_key_test_assert")
fn index_get_key_test_assert() -> Promise(Nil)

pub fn index_get_all_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          let builder = transaction.prepare(db, transaction.read_write)
          let #(builder, my_store) = transaction.store(builder, test_store())
          let name_idx = transaction.index(my_store, test_index())
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(tx, my_store, #(1, "Alice"))

                use _ <- store.add(tx, my_store, #(2, "Alice"))

                use result <- index.get_all(
                  tx,
                  name_idx,
                  glindex.Only(glindex.string("Alice")),
                  option.None,
                )

                let assert Ok(ids) = result

                let assert 2 = list.length(ids)

                database.close(db)

                resolve(Nil)
              }
            }
          })
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { index_get_all_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "index_get_all_test_assert")
fn index_get_all_test_assert() -> Promise(Nil)

pub fn index_get_all_keys_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          let builder = transaction.prepare(db, transaction.read_write)
          let #(builder, my_store) = transaction.store(builder, test_store())
          let name_idx = transaction.index(my_store, test_index())
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(tx, my_store, #(1, "Alice"))
                use _ <- store.add(tx, my_store, #(2, "Alice"))

                use result <- index.get_all_keys(
                  tx,
                  name_idx,
                  glindex.Only(glindex.string("Alice")),
                  option.None,
                )

                let assert Ok([1, 2]) = result

                database.close(db)

                resolve(Nil)
              }
            }
          })
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { index_get_all_keys_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "index_get_all_keys_test_assert")
fn index_get_all_keys_test_assert() -> Promise(Nil)

pub fn index_count_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          let builder = transaction.prepare(db, transaction.read_write)
          let #(builder, my_store) = transaction.store(builder, test_store())
          let name_idx = transaction.index(my_store, test_index())
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(tx, my_store, #(1, "Alice"))
                use _ <- store.add(tx, my_store, #(2, "Alice"))

                use result <- index.count(
                  tx,
                  name_idx,
                  glindex.Only(glindex.string("Alice")),
                )

                let assert Ok(2) = result

                database.close(db)

                resolve(Nil)
              }
            }
          })
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { index_count_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "index_count_test_assert")
fn index_count_test_assert() -> Promise(Nil)

pub fn index_get_not_found_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          let builder = transaction.prepare(db, transaction.read_only)
          let #(builder, my_store) = transaction.store(builder, test_store())
          let name_idx = transaction.index(my_store, test_index())
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use result <- index.get(
                  tx,
                  name_idx,
                  glindex.Only(glindex.string("Nobody")),
                )

                let assert Error(transaction.NotFoundError) = result

                database.close(db)

                resolve(Nil)
              }
            }
          })
        }
      }
    })
  })
}

pub fn index_get_key_not_found_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          let builder = transaction.prepare(db, transaction.read_only)
          let #(builder, my_store) = transaction.store(builder, test_store())
          let name_idx = transaction.index(my_store, test_index())
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use result <- index.get_key(
                  tx,
                  name_idx,
                  glindex.Only(glindex.string("Nobody")),
                )

                let assert Error(transaction.NotFoundError) = result

                database.close(db)

                resolve(Nil)
              }
            }
          })
        }
      }
    })
  })
}
