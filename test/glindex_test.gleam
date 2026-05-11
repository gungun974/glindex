import gleam/order
import gleeunit
import glindex

@external(javascript, "./glindex_test_ffi.mjs", "fake_indexeddb")
fn fake_indexeddb() -> Nil

pub fn main() {
  gleeunit.main()
}

pub fn cmp_test() {
  fake_indexeddb()
  let assert order.Lt = glindex.cmp(glindex.int(1), glindex.int(2))
  let assert order.Eq = glindex.cmp(glindex.int(1), glindex.int(1))
  let assert order.Gt = glindex.cmp(glindex.int(2), glindex.int(1))
}
