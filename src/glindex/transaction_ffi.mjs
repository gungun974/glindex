import {
  Result$Ok,
  Result$Error,
  List$NonEmpty,
  List$Empty,
} from "../gleam.mjs";

import { Option$Some, Option$None } from "../../gleam_stdlib/gleam/option.mjs";

import {
  Query$isAll,
  Query$isOnly,
  Query$Only$0,
  Query$isLowerBound,
  Query$LowerBound$value,
  Query$LowerBound$exclusive,
  Query$isUpperBound,
  Query$UpperBound$value,
  Query$UpperBound$exclusive,
  Query$Bound$lower,
  Query$Bound$upper,
  Query$Bound$exclusive_lower,
  Query$Bound$exclusive_upper,
  Store$Store,
  Store$Store$name,
  Store$Store$to_value,
  Store$Store$decoder,
  Store$Store$key_decoder,
  Index$Index$name,
} from "../glindex.mjs";

import {
  CursorDirection$isPrev,
  CursorDirection$isNextUnique,
  CursorDirection$isPrevUnique,
  is_continue,
  is_stop,
  is_advance,
  advance_steps,
  is_continue_primary_key,
  continue_primary_key_values,
} from "./cursor.mjs";

function directionToString(direction) {
  if (CursorDirection$isPrev(direction)) return "prev";
  if (CursorDirection$isNextUnique(direction)) return "nextunique";
  if (CursorDirection$isPrevUnique(direction)) return "prevunique";
  return "next";
}

function queryToIDBKeyRange(query) {
  if (Query$isAll(query)) return null;
  if (Query$isOnly(query)) return Query$Only$0(query);
  if (Query$isLowerBound(query))
    return IDBKeyRange.lowerBound(
      Query$LowerBound$value(query),
      Query$LowerBound$exclusive(query),
    );
  if (Query$isUpperBound(query))
    return IDBKeyRange.upperBound(
      Query$UpperBound$value(query),
      Query$UpperBound$exclusive(query),
    );
  return IDBKeyRange.bound(
    Query$Bound$lower(query),
    Query$Bound$upper(query),
    Query$Bound$exclusive_lower(query),
    Query$Bound$exclusive_upper(query),
  );
}

function domStringListToGleamList(list) {
  let result = List$Empty();
  for (let i = list.length - 1; i >= 0; i--) {
    result = List$NonEmpty(list[i], result);
  }
  return result;
}

function gleamListFromArray(arr) {
  let list = List$Empty();
  for (let i = arr.length - 1; i >= 0; i--) {
    list = List$NonEmpty(arr[i], list);
  }
  return list;
}

function optionToValue(opt) {
  return opt.constructor.name === "None" ? undefined : opt[0];
}

export function prepare(db, mode) {
  return {
    db,
    mode,
    stores: [],
    durability: "default",
    oncomplete: null,
    onerror: null,
    onabort: null,
  };
}

export function with_durability(builder, durability) {
  builder.durability = durability;
  return builder;
}

export function on_complete(builder, handler) {
  builder.oncomplete = handler;
  return builder;
}

export function on_error(builder, handler) {
  builder.onerror = handler;
  return builder;
}

export function on_abort(builder, handler) {
  builder.onabort = handler;
  return builder;
}

export function store(builder, store) {
  const name = Store$Store$name(store);
  const to_value = Store$Store$to_value(store);
  const decoder = Store$Store$decoder(store);
  const key_decoder = Store$Store$key_decoder(store);
  builder.stores.push(name);
  return [
    builder,
    {
      name,
      to_value,
      decoder,
      key_decoder,
    },
  ];
}

export function index(store, index) {
  const name = Index$Index$name(index);
  return { store, name };
}

export function extract_store(store) {
  return Store$Store(
    store.name,
    store.to_value,
    store.decoder,
    store.key_decoder,
  );
}

export function extract_index(index) {
  return [index.store.decoder, index.store.key_decoder];
}

export function begin(builder) {
  try {
    const db = builder.db;
    const tx = db.transaction(builder.stores, builder.mode, {
      durability: builder.durability,
    });
    if (builder.oncomplete) tx.oncomplete = () => builder.oncomplete();
    if (builder.onerror)
      tx.onerror = () => builder.onerror(tx.error?.name ?? "UnknownError");
    if (builder.onabort)
      tx.onabort = () =>
        builder.onabort(tx.error ? Option$Some(tx.error.name) : Option$None());
    return Result$Ok({ db, tx });
  } catch (e) {
    return Result$Error(e.name ?? "UnknownError");
  }
}

export function abort(tx) {
  tx.tx.abort();
  return undefined;
}

export function commit(tx) {
  tx.tx.commit();
  return undefined;
}

export function store_get(tx, store, query) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(store.name)
        .get(queryToIDBKeyRange(query));
      request.onsuccess = () =>
        request.result === undefined
          ? resolve(Result$Error("NotFound"))
          : resolve(Result$Ok(request.result));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function store_get_all(tx, store, query, count) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(store.name)
        .getAll(queryToIDBKeyRange(query), optionToValue(count));
      request.onsuccess = () =>
        resolve(Result$Ok(gleamListFromArray(request.result)));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function store_get_key(tx, store, query) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(store.name)
        .getKey(queryToIDBKeyRange(query));
      request.onsuccess = () =>
        request.result === undefined
          ? resolve(Result$Error("NotFound"))
          : resolve(Result$Ok(request.result));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function store_get_all_keys(tx, store, query, count) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(store.name)
        .getAllKeys(queryToIDBKeyRange(query), optionToValue(count));
      request.onsuccess = () =>
        resolve(Result$Ok(gleamListFromArray(request.result)));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function store_count(tx, store, query) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(store.name)
        .count(queryToIDBKeyRange(query));
      request.onsuccess = () => resolve(Result$Ok(request.result));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function store_add(tx, store, value) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx.objectStore(store.name).add(value);
      request.onsuccess = () => resolve(Result$Ok(request.result));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function store_put(tx, store, value) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx.objectStore(store.name).put(value);
      request.onsuccess = () => resolve(Result$Ok(request.result));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function store_add_with_out_of_line_key(tx, store, value, key) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx.objectStore(store.name).add(value, key);
      request.onsuccess = () => resolve(Result$Ok(request.result));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function store_put_with_out_of_line_key(tx, store, value, key) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx.objectStore(store.name).put(value, key);
      request.onsuccess = () => resolve(Result$Ok(request.result));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function store_delete(tx, store, query) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(store.name)
        .delete(queryToIDBKeyRange(query));
      request.onsuccess = () => resolve(Result$Ok(undefined));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function store_clear(tx, store) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx.objectStore(store.name).clear();
      request.onsuccess = () => resolve(Result$Ok(undefined));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function index_get(tx, index, query) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(index.store.name)
        .index(index.name)
        .get(queryToIDBKeyRange(query));
      request.onsuccess = () =>
        request.result === undefined
          ? resolve(Result$Error("NotFound"))
          : resolve(Result$Ok(request.result));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function index_get_key(tx, index, query) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(index.store.name)
        .index(index.name)
        .getKey(queryToIDBKeyRange(query));
      request.onsuccess = () =>
        request.result === undefined
          ? resolve(Result$Error("NotFound"))
          : resolve(Result$Ok(request.result));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function index_get_all_keys(tx, index, query, count) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(index.store.name)
        .index(index.name)
        .getAllKeys(queryToIDBKeyRange(query), optionToValue(count));
      request.onsuccess = () =>
        resolve(Result$Ok(gleamListFromArray(request.result)));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function index_count(tx, index, query) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(index.store.name)
        .index(index.name)
        .count(queryToIDBKeyRange(query));
      request.onsuccess = () => resolve(Result$Ok(request.result));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function index_get_all(tx, index, query, count) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(index.store.name)
        .index(index.name)
        .getAll(queryToIDBKeyRange(query), optionToValue(count));
      request.onsuccess = () =>
        resolve(Result$Ok(gleamListFromArray(request.result)));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

function runCursor(request, initial, handler, resolve) {
  let state = initial;
  request.onsuccess = () => {
    const cursor = request.result;
    if (!cursor) {
      resolve(Result$Ok(state));
      return;
    }
    handler(state, cursor, (newState, cursorNext) => {
      state = newState;
      if (is_continue(cursorNext)) {
        cursor.continue();
      } else if (is_advance(cursorNext)) {
        cursor.advance(advance_steps(cursorNext));
      } else if (is_continue_primary_key(cursorNext)) {
        const values = continue_primary_key_values(cursorNext);
        cursor.continuePrimaryKey(values[0], values[1]);
      } else if (is_stop(cursorNext)) {
        resolve(Result$Ok(newState));
      }
    });
  };
  request.onerror = () =>
    resolve(Result$Error(request.error?.name ?? "UnknownError"));
}

export function store_open_cursor(
  tx,
  store,
  query,
  direction,
  initial,
  handler,
) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(store.name)
        .openCursor(queryToIDBKeyRange(query), directionToString(direction));
      runCursor(request, initial, handler, resolve);
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function index_open_cursor(
  tx,
  index,
  query,
  direction,
  initial,
  handler,
) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(index.store.name)
        .index(index.name)
        .openCursor(queryToIDBKeyRange(query), directionToString(direction));
      runCursor(request, initial, handler, resolve);
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function store_open_key_cursor(
  tx,
  store,
  query,
  direction,
  initial,
  handler,
) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(store.name)
        .openKeyCursor(queryToIDBKeyRange(query), directionToString(direction));
      runCursor(request, initial, handler, resolve);
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function index_open_key_cursor(
  tx,
  index,
  query,
  direction,
  initial,
  handler,
) {
  return new Promise((resolve) => {
    try {
      const request = tx.tx
        .objectStore(index.store.name)
        .index(index.name)
        .openKeyCursor(queryToIDBKeyRange(query), directionToString(direction));
      runCursor(request, initial, handler, resolve);
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}
