import { Result$Ok, Result$Error } from "../gleam.mjs";

export function open_database(name, version, on_upgrade_needed, next) {
  const indexedDB =
    (typeof window !== "undefined" &&
      (window.indexedDB ||
        window.mozIndexedDB ||
        window.webkitIndexedDB ||
        window.msIndexedDB ||
        window.shimIndexedDB)) ||
    (typeof globalThis !== "undefined" && globalThis.indexedDB);

  const request = indexedDB.open(name, version);

  request.onerror = () => {
    next(Result$Error(request.error?.name ?? "UnknownError"));
  };

  request.onblocked = () => {
    next(Result$Error("BlockedError"));
  };

  request.onupgradeneeded = (event) => {
    const db = request.result;
    const tx = request.transaction;
    const old_version = event.oldVersion;

    on_upgrade_needed(old_version, {
      db,
      tx,
    });
  };

  request.onsuccess = () => {
    next(Result$Ok(request.result));
  };
  return undefined;
}

export function close_database(db) {
  db.close();
  return undefined;
}
