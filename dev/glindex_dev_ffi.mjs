import "fake-indexeddb/auto";
import { IDBFactory } from "fake-indexeddb";

export function fake_indexeddb() {
  indexedDB = new IDBFactory();
  return undefined;
}
