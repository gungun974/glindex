import { Result$Ok, Result$Error } from "../gleam.mjs";

export function cursor_direction(cursor) {
  return cursor.direction;
}

export function cursor_key(cursor) {
  return cursor.key;
}

export function cursor_primary_key(cursor) {
  return cursor.primaryKey;
}

export function cursor_value(cursor) {
  return cursor.value;
}

export function cursor_delete(cursor) {
  return new Promise((resolve) => {
    try {
      const request = cursor.delete();
      request.onsuccess = () => resolve(Result$Ok(undefined));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}

export function cursor_update(cursor, value) {
  return new Promise((resolve) => {
    try {
      const request = cursor.update(value);
      request.onsuccess = () => resolve(Result$Ok(undefined));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}
