import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/option
import glindex.{Index, Store}
import glindex/cursor
import glindex/database
import glindex/index
import glindex/store
import glindex/transaction
import glindex/upgrade

@external(javascript, "../glindex_test_ffi.mjs", "fake_indexeddb")
pub fn fake_indexeddb() -> Nil

pub fn store_open_cursor_test() -> Promise(Nil) {
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
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(1)),
                    #("name", glindex.string("Alice")),
                  ]),
                  decode.int,
                )

                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(2)),
                    #("name", glindex.string("Bob")),
                  ]),
                  decode.int,
                )

                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(3)),
                    #("name", glindex.string("Charlie")),
                  ]),
                  decode.int,
                )

                use result <- store.open_cursor(
                  tx,
                  my_store,
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
        }
      }
    })
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
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(1)),
                    #("name", glindex.string("Alice")),
                  ]),
                  decode.int,
                )

                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(2)),
                    #("name", glindex.string("Bob")),
                  ]),
                  decode.int,
                )

                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(3)),
                    #("name", glindex.string("Charlie")),
                  ]),
                  decode.int,
                )

                use result <- store.open_cursor(
                  tx,
                  my_store,
                  glindex.All,
                  cursor.Prev,
                  option.None,
                  fn(state, cur, next) {
                    case
                      cursor.cursor_value(
                        cur,
                        decode.field("name", decode.string, decode.success),
                      )
                    {
                      Ok(name) -> next(option.Some(name), cursor.stop())
                      Error(_) -> next(state, cursor.stop())
                    }
                  },
                )

                let assert Ok(option.Some("Charlie")) = result

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
  |> promise.await(fn(_) { store_open_cursor_prev_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "store_open_cursor_prev_test_assert")
fn store_open_cursor_prev_test_assert() -> Promise(Nil)

pub fn store_open_cursor_stop_test() -> Promise(Nil) {
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
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(1)),
                    #("name", glindex.string("Alice")),
                  ]),
                  decode.int,
                )

                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(2)),
                    #("name", glindex.string("Bob")),
                  ]),
                  decode.int,
                )

                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(3)),
                    #("name", glindex.string("Charlie")),
                  ]),
                  decode.int,
                )

                use result <- store.open_cursor(
                  tx,
                  my_store,
                  glindex.All,
                  cursor.Next,
                  0,
                  fn(count, _, next) { next(count + 1, cursor.stop()) },
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
  |> promise.await(fn(_) { store_open_cursor_stop_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "store_open_cursor_stop_test_assert")
fn store_open_cursor_stop_test_assert() -> Promise(Nil)

pub fn store_open_cursor_advance_test() -> Promise(Nil) {
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
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(1)),
                    #("name", glindex.string("Alice")),
                  ]),
                  decode.int,
                )

                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(2)),
                    #("name", glindex.string("Bob")),
                  ]),
                  decode.int,
                )

                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(3)),
                    #("name", glindex.string("Charlie")),
                  ]),
                  decode.int,
                )

                use result <- store.open_cursor(
                  tx,
                  my_store,
                  glindex.All,
                  cursor.Next,
                  #(False, 0),
                  fn(state, _, next) {
                    let #(advanced, count) = state
                    case advanced {
                      False -> next(#(True, count), cursor.advance(2))
                      True -> next(#(True, count + 1), cursor.continue())
                    }
                  },
                )

                let assert Ok(#(_, count)) = result
                let assert 1 = count

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
  |> promise.await(fn(_) { store_open_cursor_advance_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "store_open_cursor_advance_test_assert")
fn store_open_cursor_advance_test_assert() -> Promise(Nil)

pub fn store_open_key_cursor_test() -> Promise(Nil) {
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
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(1)),
                    #("name", glindex.string("Alice")),
                  ]),
                  decode.int,
                )

                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(2)),
                    #("name", glindex.string("Bob")),
                  ]),
                  decode.int,
                )

                use result <- store.open_key_cursor(
                  tx,
                  my_store,
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
        }
      }
    })
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
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          let name_idx = transaction.index(my_store, Index("name_idx"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(1)),
                    #("name", glindex.string("Alice")),
                  ]),
                  decode.int,
                )

                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(2)),
                    #("name", glindex.string("Bob")),
                  ]),
                  decode.int,
                )

                use result <- index.open_cursor(
                  tx,
                  name_idx,
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
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(_) { index_open_cursor_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "index_open_cursor_test_assert")
fn index_open_cursor_test_assert() -> Promise(Nil)

pub fn index_open_key_cursor_test() -> Promise(Nil) {
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
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          let name_idx = transaction.index(my_store, Index("name_idx"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(1)),
                    #("name", glindex.string("Alice")),
                  ]),
                  decode.int,
                )

                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(2)),
                    #("name", glindex.string("Bob")),
                  ]),
                  decode.int,
                )

                use result <- index.open_key_cursor(
                  tx,
                  name_idx,
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
        }
      }
    })
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
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(1)),
                    #("name", glindex.string("Alice")),
                  ]),
                  decode.int,
                )

                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(2)),
                    #("name", glindex.string("Bob")),
                  ]),
                  decode.int,
                )

                use _ <- store.open_cursor(
                  tx,
                  my_store,
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
        }
      }
    })
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
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(1)),
                    #("name", glindex.string("Alice")),
                  ]),
                  decode.int,
                )

                use _ <- store.open_cursor(
                  tx,
                  my_store,
                  glindex.All,
                  cursor.Next,
                  Nil,
                  fn(_, cur, next) {
                    use _ <- cursor.cursor_update(
                      cur,
                      glindex.object([
                        #("id", glindex.int(1)),
                        #("name", glindex.string("Updated")),
                      ]),
                    )
                    next(Nil, cursor.stop())
                  },
                )

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
  |> promise.await(fn(_) { cursor_update_test_assert() })
}

@external(javascript, "./cursor_test_ffi.mjs", "cursor_update_test_assert")
fn cursor_update_test_assert() -> Promise(Nil)

pub fn cursor_delete_returns_ok_test() -> Promise(Nil) {
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
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(1)),
                    #("name", glindex.string("Alice")),
                  ]),
                  decode.int,
                )

                use _ <- store.open_cursor(
                  tx,
                  my_store,
                  glindex.All,
                  cursor.Next,
                  Nil,
                  fn(_, cur, next) {
                    use result <- cursor.cursor_delete(cur)
                    let assert Ok(Nil) = result
                    next(Nil, cursor.stop())
                  },
                )

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

pub fn cursor_update_returns_ok_test() -> Promise(Nil) {
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
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use _ <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(1)),
                    #("name", glindex.string("Alice")),
                  ]),
                  decode.int,
                )

                use _ <- store.open_cursor(
                  tx,
                  my_store,
                  glindex.All,
                  cursor.Next,
                  Nil,
                  fn(_, cur, next) {
                    use result <- cursor.cursor_update(
                      cur,
                      glindex.object([
                        #("id", glindex.int(1)),
                        #("name", glindex.string("Updated")),
                      ]),
                    )
                    let assert Ok(Nil) = result
                    next(Nil, cursor.stop())
                  },
                )

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
