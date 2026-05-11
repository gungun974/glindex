import gleam/javascript/promise.{type Promise}
import gleam/list
import glindex/database

@external(javascript, "../glindex_test_ffi.mjs", "fake_indexeddb")
pub fn fake_indexeddb() -> Nil

@external(javascript, "../glindex_test_ffi.mjs", "make_tracker")
fn make_tracker() -> #(fn() -> Nil, fn() -> Bool)

pub fn open_database_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()
  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
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
  |> promise.await(fn(_) { open_database_test_assert() })
}

@external(javascript, "./database_test_ffi.mjs", "open_database_test_assert")
fn open_database_test_assert() -> Promise(Nil)

pub fn upgrade_database_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()
  let #(set_v1, verify_v1) = make_tracker()
  let #(set_v2, verify_v2) = make_tracker()

  //! Act (first open at version 1)
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.add_version(1, fn(_tx) { set_v1() })
    |> database.add_version(2, fn(_tx) { set_v2() })
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
  //! Assert (first open)
  |> promise.await(fn(_) {
    let assert True = verify_v1()
    let assert False = verify_v2()
    upgrade_database_test_assert1()
  })
  //! Act (second open at version 2)
  |> promise.await(fn(_) {
    let #(set_v1, verify_v1) = make_tracker()
    let #(set_v2, verify_v2) = make_tracker()

    promise.new(fn(resolve) {
      database.new("Hoi", 2)
      |> database.add_version(1, fn(_tx) { set_v1() })
      |> database.add_version(2, fn(_tx) { set_v2() })
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
    //! Assert (second open)
    |> promise.await(fn(_) {
      let assert False = verify_v1()
      let assert True = verify_v2()
      upgrade_database_test_assert2()
    })
  })
}

@external(javascript, "./database_test_ffi.mjs", "upgrade_database_test_assert1")
fn upgrade_database_test_assert1() -> Promise(Nil)

@external(javascript, "./database_test_ffi.mjs", "upgrade_database_test_assert2")
fn upgrade_database_test_assert2() -> Promise(Nil)

pub fn invalid_upgrade_database1_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()
  let #(set_v1, verify_v1) = make_tracker()

  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 0)
    |> database.add_version(1, fn(_tx) { set_v1() })
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(err) -> resolve(Error(err))
        Ok(db) -> {
          database.close(db)
          resolve(Ok(Nil))
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(res) {
    let assert False = verify_v1()
    let assert Error(database.VersionError) = res
    invalid_upgrade_database1_test_assert()
  })
}

@external(javascript, "./database_test_ffi.mjs", "invalid_upgrade_database1_test_assert")
fn invalid_upgrade_database1_test_assert() -> Promise(Nil)

pub fn invalid_upgrade_database2_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()
  let #(set_v1, verify_v1) = make_tracker()

  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.add_version(0, fn(_tx) { set_v1() })
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(err) -> resolve(Error(err))
        Ok(db) -> {
          database.close(db)
          resolve(Ok(Nil))
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(res) {
    let assert False = verify_v1()
    let assert Error(database.VersionError) = res
    invalid_upgrade_database2_test_assert()
  })
}

@external(javascript, "./database_test_ffi.mjs", "invalid_upgrade_database2_test_assert")
fn invalid_upgrade_database2_test_assert() -> Promise(Nil)

pub fn invalid_upgrade_database3_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()
  let #(set_v1, verify_v1) = make_tracker()
  let #(set_v1b, verify_v1b) = make_tracker()

  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.add_version(1, fn(_tx) { set_v1() })
    |> database.add_version(1, fn(_tx) { set_v1b() })
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(err) -> resolve(Error(err))
        Ok(db) -> {
          database.close(db)
          resolve(Ok(Nil))
        }
      }
    })
  })
  //! Assert
  |> promise.await(fn(res) {
    let assert False = verify_v1()
    let assert False = verify_v1b()
    let assert Error(database.VersionError) = res
    invalid_upgrade_database3_test_assert()
  })
}

@external(javascript, "./database_test_ffi.mjs", "invalid_upgrade_database3_test_assert")
fn invalid_upgrade_database3_test_assert() -> Promise(Nil)

pub fn invalid_upgrade_database4_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 2)
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(err) -> resolve(Error(err))
        Ok(db) -> {
          database.close(db)
          resolve(Ok(Nil))
        }
      }
    })
  })
  |> promise.await(fn(_) {
    promise.new(fn(resolve) {
      database.new("Hoi", 1)
      |> database.open(fn(maybe_db) {
        case maybe_db {
          Error(err) -> resolve(Error(err))
          Ok(db) -> {
            database.close(db)
            resolve(Ok(Nil))
          }
        }
      })
    })
  })
  //! Assert
  |> promise.await(fn(res) {
    let assert Error(database.VersionError) = res
    invalid_upgrade_database4_test_assert()
  })
}

@external(javascript, "./database_test_ffi.mjs", "invalid_upgrade_database4_test_assert")
fn invalid_upgrade_database4_test_assert() -> Promise(Nil)

pub fn blocked_database_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(err) -> resolve(Error(err))
        Ok(_) -> {
          // We never close the DB for this test
          resolve(Ok(Nil))
        }
      }
    })
  })
  |> promise.await(fn(_) {
    promise.new(fn(resolve) {
      database.new("Hoi", 2)
      |> database.open(fn(maybe_db) {
        case maybe_db {
          Error(err) -> resolve(Error(err))
          Ok(db) -> {
            database.close(db)
            resolve(Ok(Nil))
          }
        }
      })
    })
  })
  //! Assert
  |> promise.await(fn(res) {
    let assert Error(database.Blocked) = res
    blocked_database_test_assert()
  })
}

@external(javascript, "./database_test_ffi.mjs", "blocked_database_test_assert")
fn blocked_database_test_assert() -> Promise(Nil)

pub fn on_blocked_callback_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()
  let #(set_blocked, verify_blocked) = make_tracker()

  //! Act (open V1, keep connection open)
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(_) -> resolve(Nil)
      }
    })
  })
  //! Act (try to open V2 with on_blocked handler, triggers blocked)
  |> promise.await(fn(_) {
    promise.new(fn(resolve) {
      database.new("Hoi", 2)
      |> database.on_blocked(fn(_, _) { set_blocked() })
      |> database.open(fn(maybe_db) {
        case maybe_db {
          Error(err) -> resolve(Error(err))
          Ok(db) -> {
            database.close(db)
            resolve(Ok(Nil))
          }
        }
      })
    })
  })
  //! Assert
  |> promise.await(fn(res) {
    let assert True = verify_blocked()
    let assert Error(database.Blocked) = res
    on_blocked_callback_test_assert()
  })
}

@external(javascript, "./database_test_ffi.mjs", "on_blocked_callback_test_assert")
fn on_blocked_callback_test_assert() -> Promise(Nil)

pub fn on_blocking_callback_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()
  let #(set_blocking, verify_blocking) = make_tracker()

  //! Act (open V1 with on_blocking handler, keep connection open)
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.on_blocking(fn(_, _) { set_blocking() })
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(_) -> resolve(Nil)
      }
    })
  })
  //! Act (try to open V2, triggers versionchange on V1 connection)
  |> promise.await(fn(_) {
    promise.new(fn(resolve) {
      database.new("Hoi", 2)
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
  |> promise.await(fn(_) {
    let assert True = verify_blocking()
    on_blocking_callback_test_assert()
  })
}

@external(javascript, "./database_test_ffi.mjs", "on_blocking_callback_test_assert")
fn on_blocking_callback_test_assert() -> Promise(Nil)

pub fn databases_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
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
  |> promise.await(fn(_) {
    promise.new(fn(resolve) {
      database.databases(fn(result) { resolve(result) })
    })
  })
  //! Assert
  |> promise.await(fn(res) {
    let assert Ok(dbs) = res
    let assert True =
      list.any(dbs, fn(db) { db.name == "Hoi" && db.version == 1 })
    databases_test_assert()
  })
}

@external(javascript, "./database_test_ffi.mjs", "databases_test_assert")
fn databases_test_assert() -> Promise(Nil)

pub fn delete_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
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
  |> promise.await(fn(_) {
    promise.new(fn(resolve) {
      database.delete("Hoi", fn(result) { resolve(result) })
    })
  })
  //! Assert
  |> promise.await(fn(res) {
    let assert Ok(Nil) = res
    delete_test_assert()
  })
}

@external(javascript, "./database_test_ffi.mjs", "delete_test_assert")
fn delete_test_assert() -> Promise(Nil)

pub fn delete_blocked_test() -> Promise(Nil) {
  //! Arrange
  fake_indexeddb()

  //! Act (open V1, keep connection open)
  promise.new(fn(resolve) {
    database.new("Hoi", 1)
    |> database.open(fn(maybe_db) {
      case maybe_db {
        Error(_) -> resolve(Nil)
        Ok(_) -> resolve(Nil)
      }
    })
  })
  //! Act (try to delete while connection is open)
  |> promise.await(fn(_) {
    promise.new(fn(resolve) {
      database.delete("Hoi", fn(result) { resolve(result) })
    })
  })
  //! Assert
  |> promise.await(fn(res) {
    let assert Error(database.Blocked) = res
    delete_blocked_test_assert()
  })
}

@external(javascript, "./database_test_ffi.mjs", "delete_blocked_test_assert")
fn delete_blocked_test_assert() -> Promise(Nil)
