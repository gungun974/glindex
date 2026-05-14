import {
  Result$Ok,
  Result$Error,
  List$NonEmpty,
  List$Empty,
} from "../gleam.mjs";
import { Option$isNone } from "../../gleam_stdlib/gleam/option.mjs";

function getIndexedDB() {
  return (
    (typeof window !== "undefined" &&
      (window.indexedDB ||
        window.mozIndexedDB ||
        window.webkitIndexedDB ||
        window.msIndexedDB ||
        window.shimIndexedDB)) ||
    (typeof globalThis !== "undefined" && globalThis.indexedDB)
  );
}

function optionToCallback(opt) {
  return Option$isNone(opt) ? null : opt[0];
}

export function open_database(
  name,
  version,
  on_upgrade_needed,
  on_blocked_opt,
  on_blocking_opt,
  on_close_opt,
) {
  return new Promise((resolve) => {
    try {
      const indexedDB = getIndexedDB();
      const request = indexedDB.open(name, version);

      const on_blocked_cb = optionToCallback(on_blocked_opt);
      const on_blocking_cb = optionToCallback(on_blocking_opt);
      const on_close_cb = optionToCallback(on_close_opt);

      request.onerror = () => {
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
      };

      request.onblocked = (event) => {
        if (on_blocked_cb) {
          on_blocked_cb(event.oldVersion ?? 0, event.newVersion ?? 0);
        }
        resolve(Result$Error("BlockedError"));
      };

      request.onupgradeneeded = (event) => {
        const db = request.result;
        const tx = request.transaction;
        const old_version = event.oldVersion;

        on_upgrade_needed(old_version, { db, tx });
      };

      request.onsuccess = () => {
        const db = request.result;

        if (on_blocking_cb) {
          db.onversionchange = (event) => {
            on_blocking_cb(event.oldVersion ?? 0, event.newVersion ?? 0);
          };
        }

        if (on_close_cb) {
          db.onclose = () => {
            on_close_cb();
          };
        }

        resolve(Result$Ok(db));
      };
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function close_database(db) {
  db.close();
  return undefined;
}

export async function databases() {
  try {
    const indexedDB = getIndexedDB();
    const dbs = await indexedDB.databases();
    let list = List$Empty();
    for (let i = dbs.length - 1; i >= 0; i--) {
      list = List$NonEmpty([dbs[i].name, dbs[i].version], list);
    }
    return Result$Ok(list);
  } catch (e) {
    return Result$Error(e?.name ?? "UnknownError");
  }
}

export function delete_database(name) {
  return new Promise((resolve) => {
    try {
      const indexedDB = getIndexedDB();
      const request = indexedDB.deleteDatabase(name);
      request.onsuccess = () => resolve(Result$Ok(undefined));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
      request.onblocked = () => resolve(Result$Error("BlockedError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}
