import {
  List$isNonEmpty,
  List$NonEmpty$first,
  List$NonEmpty$rest,
  List$NonEmpty,
  List$Empty,
} from "../gleam.mjs";
import {
  KeyPath$isOutOfLineKey,
  KeyPath$isKeyPath,
  KeyPath$KeyPath$0,
  KeyPath$CompositeKeyPath$0,
  KeyPath$OutOfLineKey,
  KeyPath$KeyPath,
  KeyPath$CompositeKeyPath,
  StoreOptions$StoreOptions$key_path,
  StoreOptions$StoreOptions$auto_increment,
  IndexOptions$IndexOptions$unique,
  IndexOptions$IndexOptions$multi_entry,
} from "./upgrade.mjs";

export function store(name) {
  return name;
}

export function index(store, name) {
  return {
    store,
    name,
  };
}

export function create_store(tx, name, options) {
  const idbOptions = {
    autoIncrement: StoreOptions$StoreOptions$auto_increment(options),
  };

  const keyPath = StoreOptions$StoreOptions$key_path(options);
  if (KeyPath$isKeyPath(keyPath)) {
    idbOptions.keyPath = KeyPath$KeyPath$0(keyPath);
  } else if (!KeyPath$isOutOfLineKey(keyPath)) {
    const arr = [];
    let list = KeyPath$CompositeKeyPath$0(keyPath);
    while (List$isNonEmpty(list)) {
      arr.push(List$NonEmpty$first(list));
      list = List$NonEmpty$rest(list);
    }
    idbOptions.keyPath = arr;
  }

  tx.db.createObjectStore(name, idbOptions);
  return name;
}

export function delete_store(tx, name) {
  tx.db.deleteObjectStore(name);
  return undefined;
}

export function create_index(tx, index, key_path, options) {
  const store = tx.tx.objectStore(index.store);

  let idbKeyPath;
  if (KeyPath$isKeyPath(key_path)) {
    idbKeyPath = KeyPath$KeyPath$0(key_path);
  } else if (!KeyPath$isOutOfLineKey(key_path)) {
    const arr = [];
    let list = KeyPath$CompositeKeyPath$0(key_path);
    while (List$isNonEmpty(list)) {
      arr.push(List$NonEmpty$first(list));
      list = List$NonEmpty$rest(list);
    }
    idbKeyPath = arr;
  }

  store.createIndex(index.name, idbKeyPath, {
    unique: IndexOptions$IndexOptions$unique(options),
    multiEntry: IndexOptions$IndexOptions$multi_entry(options),
  });
  return index;
}

export function delete_index(tx, index) {
  const store = tx.tx.objectStore(index.store);

  store.deleteIndex(index.name);
  return undefined;
}

function gleamListFromArray(arr) {
  let list = List$Empty();
  for (let i = arr.length - 1; i >= 0; i--) {
    list = List$NonEmpty(arr[i], list);
  }
  return list;
}

function idbKeyPathToGleam(kp) {
  if (kp === null) return KeyPath$OutOfLineKey();
  if (Array.isArray(kp))
    return KeyPath$CompositeKeyPath(gleamListFromArray(kp));
  return KeyPath$KeyPath(kp);
}

export function store_key_path(tx, store_name) {
  return idbKeyPathToGleam(tx.tx.objectStore(store_name).keyPath);
}

export function store_auto_increment(tx, store_name) {
  return tx.tx.objectStore(store_name).autoIncrement;
}

export function index_key_path(tx, index) {
  return idbKeyPathToGleam(
    tx.tx.objectStore(index.store).index(index.name).keyPath,
  );
}

export function index_unique(tx, index) {
  return tx.tx.objectStore(index.store).index(index.name).unique;
}

export function index_multi_entry(tx, index) {
  return tx.tx.objectStore(index.store).index(index.name).multiEntry;
}

export function rename_store(tx, store_name, new_name) {
  tx.tx.objectStore(store_name).name = new_name;
  return new_name;
}

export function rename_index(tx, index, new_name) {
  tx.tx.objectStore(index.store).index(index.name).name = new_name;
  return { store: index.store, name: new_name };
}

export function object_store_names(tx) {
  return gleamListFromArray(Array.from(tx.tx.objectStoreNames));
}

export function index_names(tx, store_name) {
  return gleamListFromArray(
    Array.from(tx.tx.objectStore(store_name).indexNames),
  );
}
