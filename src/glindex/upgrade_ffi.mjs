import {
  List$isNonEmpty,
  List$NonEmpty$first,
  List$NonEmpty$rest,
} from "../gleam.mjs";
import {
  KeyPath$isNoKeyPath,
  KeyPath$isKeyPath,
  KeyPath$KeyPath$0,
  KeyPath$CompositeKeyPath$0,
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
  const idbOptions = { autoIncrement: StoreOptions$StoreOptions$auto_increment(options) };

  const keyPath = StoreOptions$StoreOptions$key_path(options);
  if (KeyPath$isKeyPath(keyPath)) {
    idbOptions.keyPath = KeyPath$KeyPath$0(keyPath);
  } else if (!KeyPath$isNoKeyPath(keyPath)) {
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
  } else if (!KeyPath$isNoKeyPath(key_path)) {
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
