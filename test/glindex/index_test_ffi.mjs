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

export async function get_test_assert() {
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

export async function get_all_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 2) {
    throw new Error(`Expected 2 records, got ${count}`);
  }
  return undefined;
}

export async function get_key_test_assert() {
  const db = await open_db("Hoi");
  const record = await get_record(db, "my_store", 1);
  db.close();
  if (!record) {
    throw new Error("Expected record with id 1 to exist");
  }
  return undefined;
}

export async function get_all_keys_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 2) {
    throw new Error(`Expected 2 records, got ${count}`);
  }
  return undefined;
}

export async function count_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 2) {
    throw new Error(`Expected 2 records, got ${count}`);
  }
  return undefined;
}

export async function open_cursor_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 3) {
    throw new Error(`Expected 3 records, got ${count}`);
  }
  return undefined;
}

export async function open_cursor_rw_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 0) {
    throw new Error(`Expected 0 records after cursor delete, got ${count}`);
  }
  return undefined;
}

export async function open_key_cursor_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 2) {
    throw new Error(`Expected 2 records, got ${count}`);
  }
  return undefined;
}

export async function open_key_cursor_rw_test_assert() {
  const db = await open_db("Hoi");
  const count = await count_records(db, "my_store");
  db.close();
  if (count !== 2) {
    throw new Error(`Expected 2 records, got ${count}`);
  }
  return undefined;
}
