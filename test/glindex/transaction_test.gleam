import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/option.{None, Some}
import glindex.{Store}
import glindex/database
import glindex/store
import glindex/transaction
import glindex/upgrade

@external(javascript, "../glindex_test_ffi.mjs", "fake_indexeddb")
pub fn fake_indexeddb() -> Nil

@external(javascript, "../glindex_test_ffi.mjs", "make_tracker")
fn make_tracker() -> #(fn() -> Nil, fn() -> Bool)

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

pub fn abort_transaction_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          let builder = transaction.prepare(db, transaction.read_write)
          let #(builder, my_store) = transaction.store(builder, test_store())
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(tx, my_store, #(1, "Alice"))

                transaction.abort(tx)

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
  |> promise.await(fn(_) { abort_transaction_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "abort_transaction_test_assert")
fn abort_transaction_test_assert() -> Promise(Nil)

pub fn with_durability_relaxed_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          let builder = transaction.prepare(db, transaction.read_write)
          let builder =
            transaction.with_durability(builder, transaction.DurabilityRelaxed)
          let #(builder, my_store) = transaction.store(builder, test_store())
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(tx, my_store, #(1, "Alice"))

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
  |> promise.await(fn(_) { with_durability_relaxed_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "with_durability_relaxed_test_assert")
fn with_durability_relaxed_test_assert() -> Promise(Nil)

pub fn on_complete_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()
  let #(mark, was_called) = make_tracker()

  //! Act
  promise.new(fn(resolve) {
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          let builder = transaction.prepare(db, transaction.read_write)
          let builder =
            transaction.on_complete(builder, fn() {
              mark()
              database.close(db)
              resolve(Nil)
            })
          let #(builder, my_store) = transaction.store(builder, test_store())
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(tx, my_store, #(1, "Alice"))
                Nil
              }
            }
          })
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) {
    let assert True = was_called()
    on_complete_test_assert()
  })
}

@external(javascript, "./transaction_test_ffi.mjs", "on_complete_test_assert")
fn on_complete_test_assert() -> Promise(Nil)

pub fn on_error_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()
  let #(mark, was_called) = make_tracker()

  //! Act
  promise.new(fn(resolve) {
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
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(db) -> {
          let builder = transaction.prepare(db, transaction.read_write)
          let builder =
            transaction.on_error(builder, fn(_error_name) {
              mark()
              database.close(db)
              resolve(Nil)
            })
          let #(builder, my_store) = transaction.store(builder, test_store())
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(tx, my_store, #(1, "Alice"))
                use _ <- store.add(tx, my_store, #(1, "Duplicate"))
                Nil
              }
            }
          })
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) {
    let assert True = was_called()
    on_error_test_assert()
  })
}

@external(javascript, "./transaction_test_ffi.mjs", "on_error_test_assert")
fn on_error_test_assert() -> Promise(Nil)

pub fn on_abort_manual_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()
  let #(mark, was_called) = make_tracker()
  let received_error =
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
          Error(_) -> resolve(None)
          Ok(db) -> {
            let builder = transaction.prepare(db, transaction.read_write)
            let builder =
              transaction.on_abort(builder, fn(err) {
                mark()
                database.close(db)
                resolve(err)
              })
            let #(builder, _my_store) = transaction.store(builder, test_store())
            transaction.begin(builder, fn(maybe_tx) {
              case maybe_tx {
                Error(_) -> {
                  database.close(db)
                  resolve(None)
                }
                Ok(tx) -> {
                  transaction.abort(tx)
                  Nil
                }
              }
            })
          }
        }
      })
    })

  //! Assert
  received_error
  |> promise.map(fn(err) {
    let assert True = was_called()
    let assert None = err
    Nil
  })
}

pub fn on_abort_error_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()
  let #(mark, was_called) = make_tracker()
  let received_error =
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
          Error(_) -> resolve(None)
          Ok(db) -> {
            let builder = transaction.prepare(db, transaction.read_write)
            let builder =
              transaction.on_abort(builder, fn(err) {
                mark()
                database.close(db)
                resolve(err)
              })
            let #(builder, my_store) = transaction.store(builder, test_store())
            transaction.begin(builder, fn(maybe_tx) {
              case maybe_tx {
                Error(_) -> {
                  database.close(db)
                  resolve(None)
                }
                Ok(tx) -> {
                  use _ <- store.add(tx, my_store, #(1, "Alice"))
                  use _ <- store.add(tx, my_store, #(1, "Duplicate"))
                  Nil
                }
              }
            })
          }
        }
      })
    })

  //! Assert
  received_error
  |> promise.map(fn(err) {
    let assert True = was_called()
    let assert Some(_) = err
    Nil
  })
}
