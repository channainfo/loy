#[test_only]
module loy::loy_test {
  use loy::loy::{Self, LOY, AdminCap };
  use sui::coin::{Self, TreasuryCap};

  #[test]
  fun test_init() {
    use sui::test_scenario;
    use loy::debugger;

    let sender = @0x001;
    let mut scenario = test_scenario::begin(sender);

    {
      let ctx = test_scenario::ctx(&mut scenario);
      loy::init_helper(ctx);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      // test coin is created and treasury is sent to package owner  correctly
      let has_treasury_cap = test_scenario::has_most_recent_for_sender<TreasuryCap<LOY>>(&scenario);
      debugger::print_data(&has_treasury_cap);
      assert!(has_treasury_cap == true, 0);

      // test the admin_cap is sent to the package owner correctly
      let is_admin_cap = test_scenario::has_most_recent_for_sender<AdminCap>(&scenario);
      assert!(is_admin_cap == true, 0);
    };

    test_scenario::end(scenario);
  }


  #[test]
  fun test_mint() {
    use sui::test_scenario;
    use loy::debugger;

    let sender = @0x001;
    let recipient = @0x002;
    let mut scenario = test_scenario::begin(sender);

    {
      let ctx = test_scenario::ctx(&mut scenario);
      loy::init_helper(ctx);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      loy::mint(&mut treasury_cap, 47, recipient, ctx);
      test_scenario::return_to_address(sender, treasury_cap);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let loy_coin = test_scenario::take_from_address<coin::Coin<LOY>>(&scenario, recipient);
      let value = sui::balance::value<LOY>(coin::balance(&loy_coin));
      debugger::print_data(&value);
      assert!(value == 47, 0);
      test_scenario::return_to_address(recipient, loy_coin);
    };

    test_scenario::end(scenario);
  }
}