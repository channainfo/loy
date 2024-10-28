#[test_only]
module loy::debugger_test {
  use loy::debugger;

  #[test]
  public fun test_print() {
    debugger::print(b"Hola Mundo!");
  }
}
