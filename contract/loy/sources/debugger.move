module loy::debugger {
  public fun print(vect: vector<u8>) {
    let str: std::string::String = std::string::utf8(vect);
    std::debug::print(&str);
  }
}
