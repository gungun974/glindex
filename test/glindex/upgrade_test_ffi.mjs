function open_db(name) {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(name);
    req.onsuccess = (e) => resolve(e.target.result);
    req.onerror = () => reject(new Error(`Failed to open database "${name}"`));
  });
}

export async function create_store_test_assert() {
  const db = await open_db("Hoi");
  const store_names = Array.from(db.objectStoreNames);
  db.close();
  if (!store_names.includes("my_store")) {
    throw new Error('Object store "my_store" was not created');
  }
  return undefined;
}

export async function create_store_with_key_path_test_assert() {
  const db = await open_db("Hoi");
  const tx = db.transaction("my_store", "readonly");
  const store = tx.objectStore("my_store");
  const key_path = store.keyPath;
  db.close();
  if (key_path !== "id") {
    throw new Error(`Expected keyPath "id", got "${key_path}"`);
  }
  return undefined;
}

export async function create_store_with_auto_increment_test_assert() {
  const db = await open_db("Hoi");
  const tx = db.transaction("my_store", "readonly");
  const store = tx.objectStore("my_store");
  const auto_increment = store.autoIncrement;
  db.close();
  if (!auto_increment) {
    throw new Error("Expected autoIncrement to be true");
  }
  return undefined;
}

export async function delete_store_test_assert() {
  const db = await open_db("Hoi");
  const store_names = Array.from(db.objectStoreNames);
  db.close();
  if (store_names.includes("my_store")) {
    throw new Error('Object store "my_store" should have been deleted');
  }
  return undefined;
}

export async function create_index_test_assert() {
  const db = await open_db("Hoi");
  const tx = db.transaction("my_store", "readonly");
  const store = tx.objectStore("my_store");
  const index_names = Array.from(store.indexNames);
  db.close();
  if (!index_names.includes("name_idx")) {
    throw new Error('Index "name_idx" was not created');
  }
  return undefined;
}

export async function create_unique_index_test_assert() {
  const db = await open_db("Hoi");
  const tx = db.transaction("my_store", "readonly");
  const store = tx.objectStore("my_store");
  const idx = store.index("email_idx");
  const unique = idx.unique;
  db.close();
  if (!unique) {
    throw new Error('Index "email_idx" should be unique');
  }
  return undefined;
}

export async function delete_index_test_assert() {
  const db = await open_db("Hoi");
  const tx = db.transaction("my_store", "readonly");
  const store = tx.objectStore("my_store");
  const index_names = Array.from(store.indexNames);
  db.close();
  if (index_names.includes("name_idx")) {
    throw new Error('Index "name_idx" should have been deleted');
  }
  return undefined;
}

export async function create_store_with_composite_key_path_test_assert() {
  const db = await open_db("Hoi");
  const tx = db.transaction("my_store", "readonly");
  const store = tx.objectStore("my_store");
  const key_path = store.keyPath;
  db.close();
  if (
    !Array.isArray(key_path) ||
    key_path[0] !== "first_name" ||
    key_path[1] !== "last_name"
  ) {
    throw new Error(
      `Expected keyPath ["first_name", "last_name"], got "${JSON.stringify(key_path)}"`,
    );
  }
  return undefined;
}

export async function create_index_with_composite_key_path_test_assert() {
  const db = await open_db("Hoi");
  const tx = db.transaction("my_store", "readonly");
  const store = tx.objectStore("my_store");
  const idx = store.index("location_idx");
  const key_path = idx.keyPath;
  db.close();
  if (
    !Array.isArray(key_path) ||
    key_path[0] !== "city" ||
    key_path[1] !== "country"
  ) {
    throw new Error(
      `Expected keyPath ["city", "country"], got "${JSON.stringify(key_path)}"`,
    );
  }
  return undefined;
}
