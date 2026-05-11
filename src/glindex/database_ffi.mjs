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
  next,
) {
  const indexedDB = getIndexedDB();
  const request = indexedDB.open(name, version);

  const on_blocked_cb = optionToCallback(on_blocked_opt);
  const on_blocking_cb = optionToCallback(on_blocking_opt);
  const on_close_cb = optionToCallback(on_close_opt);

  request.onerror = () => {
    next(Result$Error(request.error?.name ?? "UnknownError"));
  };

  request.onblocked = (event) => {
    if (on_blocked_cb) {
      on_blocked_cb(event.oldVersion ?? 0, event.newVersion ?? 0);
    }
    next(Result$Error("BlockedError"));
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

    next(Result$Ok(db));
  };

  return undefined;
}

export function close_database(db) {
  db.close();
  return undefined;
}

export function databases(next) {
  const indexedDB = getIndexedDB();
  indexedDB
    .databases()
    .then((dbs) => {
      let list = List$Empty();
      for (let i = dbs.length - 1; i >= 0; i--) {
        list = List$NonEmpty([dbs[i].name, dbs[i].version], list);
      }
      next(Result$Ok(list));
    })
    .catch((e) => {
      next(Result$Error(e?.name ?? "UnknownError"));
    });
}

export function delete_database(name, next) {
  const indexedDB = getIndexedDB();
  const request = indexedDB.deleteDatabase(name);
  request.onsuccess = () => next(Result$Ok(undefined));
  request.onerror = () =>
    next(Result$Error(request.error?.name ?? "UnknownError"));
  request.onblocked = () => next(Result$Error("BlockedError"));
}
