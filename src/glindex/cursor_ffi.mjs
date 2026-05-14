import { Result$Ok, Result$Error } from "../gleam.mjs";

export function extract_cursor(cursor) {
  return [cursor.decoder, cursor.primary_key_decoder, cursor.key_decoder];
}

export function cursor_direction(cursor) {
  return cursor.cursor.direction;
}

export function cursor_key(cursor) {
  return cursor.cursor.key;
}

export function cursor_primary_key(cursor) {
  return cursor.cursor.primaryKey;
}

export function cursor_value(cursor) {
  return cursor.cursor.value;
}

export function cursor_delete(cursor) {
  return new Promise((resolve) => {
    try {
      const request = cursor.cursor.delete();
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
      const request = cursor.cursor.update(cursor.to_value(value));
      request.onsuccess = () => resolve(Result$Ok(undefined));
      request.onerror = () =>
        resolve(Result$Error(request.error?.name ?? "UnknownError"));
    } catch (error) {
      resolve(Result$Error(error?.name ?? "UnknownError"));
    }
  });
}
