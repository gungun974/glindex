import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option
import glindex.{Store}
import glindex/database
import glindex/store
import glindex/transaction
import glindex/upgrade

@external(javascript, "../glindex_test_ffi.mjs", "fake_indexeddb")
pub fn fake_indexeddb() -> Nil

pub fn store_add_test() -> Promise(Nil) {
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
  |> promise.await(fn(_) { store_add_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_add_test_assert")
fn store_add_test_assert() -> Promise(Nil)

pub fn store_put_test() -> Promise(Nil) {
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

                use _ <- store.put(
                  tx,
                  my_store,
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
        }
      }
    })
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

                use result <- store.get(
                  tx,
                  my_store,
                  glindex.Only(glindex.int(1)),
                  decode.field("name", decode.string, decode.success),
                )

                let assert Ok("Alice") = result

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
  |> promise.await(fn(_) { store_get_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_get_test_assert")
fn store_get_test_assert() -> Promise(Nil)

pub fn store_get_all_test() -> Promise(Nil) {
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

                use result <- store.get_all(
                  tx,
                  my_store,
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
        }
      }
    })
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
                    #("id", glindex.int(42)),
                    #("name", glindex.string("Alice")),
                  ]),
                  decode.int,
                )

                use result <- store.get_key(
                  tx,
                  my_store,
                  glindex.Only(glindex.int(42)),
                  decode.int,
                )

                let assert Ok(42) = result

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
  |> promise.await(fn(_) { store_get_key_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_get_key_test_assert")
fn store_get_key_test_assert() -> Promise(Nil)

pub fn store_get_all_keys_test() -> Promise(Nil) {
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

                use result <- store.get_all_keys(
                  tx,
                  my_store,
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
        }
      }
    })
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

                use result <- store.count(tx, my_store, glindex.All)

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
  |> promise.await(fn(_) { store_count_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_count_test_assert")
fn store_count_test_assert() -> Promise(Nil)

pub fn store_delete_test() -> Promise(Nil) {
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

                use _ <- store.delete(
                  tx,
                  my_store,
                  glindex.Only(glindex.int(1)),
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
  |> promise.await(fn(_) { store_delete_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_delete_test_assert")
fn store_delete_test_assert() -> Promise(Nil)

pub fn store_clear_test() -> Promise(Nil) {
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

                use _ <- store.clear(tx, my_store)

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
  |> promise.await(fn(_) { store_clear_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_clear_test_assert")
fn store_clear_test_assert() -> Promise(Nil)

pub fn store_with_no_key_path_test() -> Promise(Nil) {
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
                use key <- store.add(
                  tx,
                  my_store,
                  glindex.object([#("name", glindex.string("Alice"))]),
                  decode.int,
                )

                let assert Ok(1) = key

                use result <- store.get(
                  tx,
                  my_store,
                  glindex.Only(glindex.int(1)),
                  decode.field("name", decode.string, decode.success),
                )

                let assert Ok("Alice") = result

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
  |> promise.await(fn(_) { store_with_no_key_path_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_with_no_key_path_test_assert")
fn store_with_no_key_path_test_assert() -> Promise(Nil)

pub fn store_with_composite_key_path_test() -> Promise(Nil) {
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
                    #("first_name", glindex.string("Alice")),
                    #("last_name", glindex.string("Smith")),
                  ]),
                  decode.list(decode.string),
                )

                use result <- store.get(
                  tx,
                  my_store,
                  glindex.Only(
                    glindex.array([
                      glindex.string("Alice"),
                      glindex.string("Smith"),
                    ]),
                  ),
                  decode.field("first_name", decode.string, decode.success),
                )

                let assert Ok("Alice") = result

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

pub fn store_add_with_out_of_line_key_test() -> Promise(Nil) {
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
            key_path: upgrade.OutOfLineKey,
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
                use result <- store.add_with_out_of_line_key(
                  tx,
                  my_store,
                  glindex.object([#("name", glindex.string("Alice"))]),
                  glindex.int(42),
                  decode.int,
                )

                let assert Ok(42) = result

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
  |> promise.await(fn(_) { store_add_with_out_of_line_key_test_assert() })
}

@external(javascript, "./transaction_test_ffi.mjs", "store_add_with_out_of_line_key_test_assert")
fn store_add_with_out_of_line_key_test_assert() -> Promise(Nil)

pub fn store_put_with_out_of_line_key_test() -> Promise(Nil) {
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
            key_path: upgrade.OutOfLineKey,
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
                use _ <- store.add_with_out_of_line_key(
                  tx,
                  my_store,
                  glindex.object([#("name", glindex.string("Alice"))]),
                  glindex.int(42),
                  decode.int,
                )

                use result <- store.put_with_out_of_line_key(
                  tx,
                  my_store,
                  glindex.object([#("name", glindex.string("Bob"))]),
                  glindex.int(42),
                  decode.int,
                )

                let assert Ok(42) = result

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

pub fn store_get_not_found_test() -> Promise(Nil) {
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
          let builder = transaction.prepare(db, transaction.read_only)
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use result <- store.get(
                  tx,
                  my_store,
                  glindex.Only(glindex.int(999)),
                  decode.field("name", decode.string, decode.success),
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

pub fn store_get_key_not_found_test() -> Promise(Nil) {
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
          let builder = transaction.prepare(db, transaction.read_only)
          let #(builder, my_store) =
            transaction.store(builder, Store("my_store"))
          transaction.begin(builder, fn(maybe_tx) {
            case maybe_tx {
              Error(_) -> {
                database.close(db)
                resolve(Nil)
              }
              Ok(tx) -> {
                use result <- store.get_key(
                  tx,
                  my_store,
                  glindex.Only(glindex.int(999)),
                  decode.int,
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

pub fn store_add_data_error_test() -> Promise(Nil) {
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
                use result <- store.add(
                  tx,
                  my_store,
                  glindex.object([#("name", glindex.string("Alice"))]),
                  decode.int,
                )

                let assert Error(transaction.DataError) = result

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

pub fn store_add_constraint_error_test() -> Promise(Nil) {
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

                use result <- store.add(
                  tx,
                  my_store,
                  glindex.object([
                    #("id", glindex.int(1)),
                    #("name", glindex.string("Duplicate")),
                  ]),
                  decode.int,
                )

                let assert Error(transaction.ConstraintError) = result

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
