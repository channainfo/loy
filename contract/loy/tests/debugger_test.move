#[test_only]
module loy::debugger_test {
  use loy::debugger;

  #[test]
  public fun test_print_string() {
    debugger::print_string(b"Hola Mundo!");
  }

  #[test]
  public fun test_print_data() {
    let age = 27u8;
    debugger::print_data<u8>(&age);
  }

  #[test]
  public fun test_print_delimiter(){
    debugger::print_delimiter();
  }

}
