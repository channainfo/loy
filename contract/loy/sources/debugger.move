module loy::debugger {
  public fun print_string(vect: vector<u8>) {
    print_delimiter();

    let str: std::string::String = std::string::utf8(vect);
    std::debug::print(&str);
  }

  public fun print_data<T>(data: &T) {
    print_delimiter();
    std::debug::print(data);
  }

  public fun print_delimiter(){
    let delimiter = std::string::utf8(b"=========================================");
    std::debug::print(&delimiter);
  }
}
