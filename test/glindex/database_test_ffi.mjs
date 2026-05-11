export async function open_database_test_assert() {
  const databases = await indexedDB.databases();
  const exists = databases.some((db) => db.name === "Hoi");
  if (!exists) {
    throw new Error('Database "Hoi" was not created');
  }
  return undefined;
}

export async function upgrade_database_test_assert1() {
  const databases = await indexedDB.databases();
  const db = databases.find((d) => d.name === "Hoi");
  if (!db) throw new Error('Database "Hoi" not found');
  if (db.version !== 1)
    throw new Error(`Database version is ${db.version}, expected 1`);
  return undefined;
}

export async function upgrade_database_test_assert2() {
  const databases = await indexedDB.databases();
  const db = databases.find((d) => d.name === "Hoi");
  if (!db) throw new Error('Database "Hoi" not found');
  if (db.version !== 2)
    throw new Error(`Database version is ${db.version}, expected 2`);
  return undefined;
}

export async function invalid_upgrade_database1_test_assert() {
  const databases = await indexedDB.databases();
  const exists = databases.some((db) => db.name === "Hoi");
  if (exists) {
    throw new Error('Database "Hoi" should not exist but does');
  }
  return undefined;
}

export async function invalid_upgrade_database2_test_assert() {
  const databases = await indexedDB.databases();
  const exists = databases.some((db) => db.name === "Hoi");
  if (exists) {
    throw new Error('Database "Hoi" should not exist but does');
  }
  return undefined;
}

export async function invalid_upgrade_database3_test_assert() {
  const databases = await indexedDB.databases();
  const exists = databases.some((db) => db.name === "Hoi");
  if (exists) {
    throw new Error('Database "Hoi" should not exist but does');
  }
  return undefined;
}

export async function invalid_upgrade_database4_test_assert() {
  const databases = await indexedDB.databases();
  const db = databases.find((d) => d.name === "Hoi");
  if (!db) throw new Error('Database "Hoi" not found');
  if (db.version !== 2)
    throw new Error(`Database version is ${db.version}, expected 2`);
  return undefined;
}

export async function blocked_database_test_assert() {
  const databases = await indexedDB.databases();
  const db = databases.find((d) => d.name === "Hoi");
  if (!db) throw new Error('Database "Hoi" not found');
  if (db.version !== 1)
    throw new Error(`Database version is ${db.version}, expected 1`);
  return undefined;
}

export async function on_blocked_callback_test_assert() {
  const databases = await indexedDB.databases();
  const db = databases.find((d) => d.name === "Hoi");
  if (!db) throw new Error('Database "Hoi" not found');
  if (db.version !== 1)
    throw new Error(`Database version is ${db.version}, expected 1`);
  return undefined;
}

export async function on_blocking_callback_test_assert() {
  const databases = await indexedDB.databases();
  const db = databases.find((d) => d.name === "Hoi");
  if (!db) throw new Error('Database "Hoi" not found');
  if (db.version !== 1)
    throw new Error(`Database version is ${db.version}, expected 1`);
  return undefined;
}

export async function databases_test_assert() {
  return undefined;
}

export async function delete_test_assert() {
  const databases = await indexedDB.databases();
  const exists = databases.some((db) => db.name === "Hoi");
  if (exists) {
    throw new Error('Database "Hoi" should have been deleted but still exists');
  }
  return undefined;
}

export async function delete_blocked_test_assert() {
  const databases = await indexedDB.databases();
  const db = databases.find((d) => d.name === "Hoi");
  if (!db) throw new Error('Database "Hoi" not found');
  if (db.version !== 1)
    throw new Error(`Database version is ${db.version}, expected 1`);
  return undefined;
}
