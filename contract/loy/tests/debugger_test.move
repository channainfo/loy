#[test_only]
module loy::debugger_test {
  use loy::debugger;

  #[test]
  public fun test_print_string() {
    debugger::print_string(b"Hola Mundo!");
  }
}
