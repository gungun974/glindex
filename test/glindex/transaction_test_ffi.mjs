function open_db(name) {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(name);
    req.onsuccess = (e) => resolve(e.target.result);
    req.onerror = () => reject(new Error(`Failed to open database "${name}"`));
  });
}

function get_record(db, store_name, key) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(store_name, "readonly");
    const store = tx.objectStore(store_name);
    const req = store.get(key);
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

function count_records(db, store_name) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(store_name, "readonly");
    const store = tx.objectStore(store_name);
    const req = store.count();
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

function count_by_index(db, store_name, index_name, key) {
  return new Promise((resolve, reject) => {
    const tx = db.transaction(store_name, "readonly");
    const store = tx.objectStore(store_name);
    const idx = store.index(index_name);
    const req = idx.count(IDBKeyRange.only(key));
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

export async function store_add_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 1);
  db.close();
  if (!record || record.name !== "Alice") {
    throw new Error(
      `Expected record {id: 1, name: "Alice"}, got ${JSON.stringify(record)}`,
    );
  }
  return undefined;
}

export async function store_put_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 1);
  db.close();
  if (!record || record.name !== "Bob") {
    throw new Error(
      `Expected updated record {id: 1, name: "Bob"}, got ${JSON.stringify(record)}`,
    );
  }
  return undefined;
}

export async function store_get_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 1);
  db.close();
  if (!record || record.name !== "Alice") {
    throw new Error(
      `Expected record with name "Alice", got ${JSON.stringify(record)}`,
    );
  }
  return undefined;
}

export async function store_get_all_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 2) {
    throw new Error(`Expected 2 records, got ${count}`);
  }
  return undefined;
}

export async function store_get_key_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 42);
  db.close();
  if (!record) {
    throw new Error("Expected record with id 42 to exist");
  }
  return undefined;
}

export async function store_get_all_keys_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 2) {
    throw new Error(`Expected 2 records, got ${count}`);
  }
  return undefined;
}

export async function store_count_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 2) {
    throw new Error(`Expected 2 records, got ${count}`);
  }
  return undefined;
}

export async function store_delete_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 1);
  db.close();
  if (record !== undefined) {
    throw new Error(
      `Expected record with id 1 to be deleted, got ${JSON.stringify(record)}`,
    );
  }
  return undefined;
}

export async function store_clear_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 0) {
    throw new Error(`Expected 0 records after clear, got ${count}`);
  }
  return undefined;
}

export async function index_get_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 1);
  db.close();
  if (!record || record.name !== "Alice") {
    throw new Error(
      `Expected record with name "Alice", got ${JSON.stringify(record)}`,
    );
  }
  return undefined;
}

export async function index_get_key_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 1);
  db.close();
  if (!record) {
    throw new Error("Expected record with id 1 to exist");
  }
  return undefined;
}

export async function index_get_all_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_by_index(db, "my_store", "name_idx", "Alice");
  db.close();
  if (count !== 2) {
    throw new Error(
      `Expected 2 records with name "Alice" via index, got ${count}`,
    );
  }
  return undefined;
}

export async function index_get_all_keys_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_by_index(db, "my_store", "name_idx", "Alice");
  db.close();
  if (count !== 2) {
    throw new Error(
      `Expected 2 keys with name "Alice" via index, got ${count}`,
    );
  }
  return undefined;
}

export async function index_count_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_by_index(db, "my_store", "name_idx", "Alice");
  db.close();
  if (count !== 2) {
    throw new Error(
      `Expected count 2 for name "Alice" via index, got ${count}`,
    );
  }
  return undefined;
}

export async function abort_transaction_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 0) {
    throw new Error(`Expected 0 records after abort, got ${count}`);
  }
  return undefined;
}

export async function store_with_no_key_path_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 1);
  db.close();
  if (!record || record.name !== "Alice") {
    throw new Error(
      `Expected record with name "Alice" at auto-increment key 1, got ${JSON.stringify(record)}`,
    );
  }
  return undefined;
}

export async function with_durability_relaxed_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 1);
  db.close();
  if (!record || record.name !== "Alice") {
    throw new Error(
      `Expected record {id: 1, name: "Alice"} with relaxed durability, got ${JSON.stringify(record)}`,
    );
  }
  return undefined;
}

export async function on_complete_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 1);
  db.close();
  if (!record || record.name !== "Alice") {
    throw new Error(
      `Expected oncomplete to have fired and committed the record, got ${JSON.stringify(record)}`,
    );
  }
  return undefined;
}

export async function on_error_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 0) {
    throw new Error(
      `Expected 0 records after transaction error aborted it, got ${count}`,
    );
  }
  return undefined;
}

export async function store_add_with_out_of_line_key_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 42);
  db.close();
  if (!record || record.name !== "Alice") {
    throw new Error(
      `Expected record {name: "Alice"} at explicit key 42, got ${JSON.stringify(record)}`,
    );
  }
  return undefined;
}

export async function store_put_with_out_of_line_key_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 42);
  db.close();
  if (!record || record.name !== "Bob") {
    throw new Error(
      `Expected updated record {name: "Bob"} at explicit key 42, got ${JSON.stringify(record)}`,
    );
  }
  return undefined;
}

export async function store_get_not_found_test_assert() {
  return undefined;
}

export async function store_get_key_not_found_test_assert() {
  return undefined;
}

export async function index_get_not_found_test_assert() {
  return undefined;
}

export async function index_get_key_not_found_test_assert() {
  return undefined;
}

export async function store_with_composite_key_path_test_assert() {
  const db = await open_db("Hoi");
  const record = await new Promise((resolve, reject) => {
    const tx = db.transaction("my_store", "readonly");
    const store = tx.objectStore("my_store");
    const req = store.get(["Alice", "Smith"]);
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
  db.close();
  if (
    !record ||
    record.first_name !== "Alice" ||
    record.last_name !== "Smith"
  ) {
    throw new Error(
      `Expected record {first_name: "Alice", last_name: "Smith"}, got ${JSON.stringify(record)}`,
    );
  }
  return undefined;
}

export async function on_abort_manual_test_assert() {
  return undefined;
}

export async function on_abort_error_test_assert() {
  return undefined;
}
