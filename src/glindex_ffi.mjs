import {
  List$isNonEmpty,
  List$NonEmpty$first,
  List$NonEmpty$rest,
} from "./gleam.mjs";

export function null_value() {
  return null;
}

export function coerce(a) {
  return a;
}

export function object(entries) {
  return Object.fromEntries(entries);
}

export function map_value(entries) {
  return new Map(entries);
}

export function set_value(list) {
  return new Set(list);
}

export function array(list) {
  const result = [];
  while (List$isNonEmpty(list)) {
    result.push(List$NonEmpty$first(list));
    list = List$NonEmpty$rest(list);
  }
  return result;
}

export function cmp(a, b) {
  return indexedDB.cmp(a, b);
}
