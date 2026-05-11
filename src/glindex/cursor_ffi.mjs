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

export function cursor_delete(cursor, next) {
  const request = cursor.delete();
  request.onsuccess = () => next(Result$Ok(undefined));
  request.onerror = () =>
    next(Result$Error(request.error?.name ?? "UnknownError"));
  return undefined;
}

export function cursor_update(cursor, value, next) {
  const request = cursor.update(value);
  request.onsuccess = () => next(Result$Ok(undefined));
  request.onerror = () =>
    next(Result$Error(request.error?.name ?? "UnknownError"));
  return undefined;
}
