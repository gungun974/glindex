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
    to_key: fn(key) { glindex.int(key) },
    key_decoder: decode.int,
  )
}

pub fn abort_transaction_test() -> Promise(Nil) {
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
          |> promise.map(fn(_) { Ok(transaction.abort(tx)) })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
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
        let builder =
          transaction.with_durability(builder, transaction.DurabilityRelaxed)
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
  |> promise.await(fn(_) { with_durability_relaxed_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "with_durability_relaxed_test_assert")
fn with_durability_relaxed_test_assert() -> Promise(Nil)

pub fn on_complete_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()
  let #(mark, was_called) = make_tracker()

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
    let #(wait, end) = promise.start()

    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let builder =
          transaction.on_complete(builder, fn() {
            mark()
            end(Nil)
          })
        let #(builder, my_store) = transaction.store(builder, test_store())

        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
        })
        |> promise.tap(fn(_) { database.close(db) })
        |> promise.await(fn(_) { wait })
      }
    }
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
        let builder = transaction.on_error(builder, fn(_error_name) { mark() })
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(1, "Duplicate")) })
          |> promise.map(fn(_) { Ok(Nil) })
        })
        |> promise.tap(fn(_) { database.close(db) })
      }
    }
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
    |> database.open()
    |> promise.await(fn(maybe_db) {
      let #(wait, end) = promise.start()

      case maybe_db {
        Error(_) -> panic
        Ok(db) -> {
          let builder = transaction.prepare(db, transaction.read_write)
          let builder =
            transaction.on_abort(builder, fn(err) {
              mark()
              end(err)
            })
          let #(builder, _my_store) = transaction.store(builder, test_store())
          promise.map_try(transaction.begin(builder), fn(tx) {
            Ok(transaction.abort(tx))
          })
          |> promise.tap(fn(_) { database.close(db) })
          |> promise.await(fn(_) { wait })
        }
      }
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
  |> database.open()
  |> promise.await(fn(maybe_db) {
    let #(wait, end) = promise.start()

    case maybe_db {
      Error(_) -> panic
      Ok(db) -> {
        let builder = transaction.prepare(db, transaction.read_write)
        let builder =
          transaction.on_abort(builder, fn(err) {
            mark()
            end(err)
          })
        let #(builder, my_store) = transaction.store(builder, test_store())
        promise.try_await(transaction.begin(builder), fn(tx) {
          store.add(tx, my_store, #(1, "Alice"))
          |> promise.await(fn(_) { store.add(tx, my_store, #(1, "Duplicate")) })
          |> promise.map(fn(_) { Ok(Nil) })
        })
        |> promise.tap(fn(_) { database.close(db) })
        |> promise.await(fn(_) { wait })
      }
    }
  })
  //! Assert
  |> promise.map(fn(err) {
    let assert True = was_called()
    let assert Some(_) = err
    Nil
  })
}
