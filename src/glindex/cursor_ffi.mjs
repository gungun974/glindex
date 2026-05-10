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
  cursor.delete();
  return undefined;
}

export function cursor_update(cursor, value) {
  cursor.update(value);
  return undefined;
}
