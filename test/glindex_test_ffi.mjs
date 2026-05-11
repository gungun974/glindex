import "fake-indexeddb/auto";
import { IDBFactory } from "fake-indexeddb";

export function fake_indexeddb() {
  indexedDB = new IDBFactory();
  return undefined;
}

export function make_tracker() {
  let called = false;
  const set = () => {
    called = true;
    return undefined;
  };
  const verify = () => called;
  return [set, verify];
}
