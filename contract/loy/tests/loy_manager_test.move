#[test_only]
module loy::loy_manager_test {
  #[test]
  public fun test_mint_to() {
    use sui::coin::{Self, TreasuryCap};
    use sui::test_scenario;
    use loy::loy::{Self, LOY};
    use loy::loy_manager;

    let sender = @0x001;
    let recipient = @0x002;

    let mint_amount = 6_000_000;

    let mut scenario = test_scenario::begin(sender);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      loy::init_helper(ctx);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      loy_manager::mint_to<LOY>(recipient, mint_amount, &mut treasury_cap, ctx);

      test_scenario::return_to_sender<TreasuryCap<LOY>>(&scenario, treasury_cap);
    };

    test_scenario::next_tx(&mut scenario, recipient);
    {
      let coin_amount = test_scenario::take_from_sender<coin::Coin<LOY>>(&scenario);
      let total_amount = sui::balance::value(coin::balance(&coin_amount));

      assert!(total_amount == mint_amount, 0);

      test_scenario::return_to_sender(&scenario, coin_amount);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_burn() {
    use sui::coin::{Self, TreasuryCap};
    use sui::test_scenario;
    use loy::loy::{Self, LOY};
    use loy::loy_manager;
    use loy::debugger;

    let sender = @0x001;
    let mint_amount = 6_000_000;

    let mut scenario = test_scenario::begin(sender);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      loy::init_helper(ctx);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      loy_manager::mint_to<LOY>(sender, mint_amount, &mut treasury_cap, ctx);

      test_scenario::return_to_sender<TreasuryCap<LOY>>(&scenario, treasury_cap);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let coin_amount = test_scenario::take_from_sender<coin::Coin<LOY>>(&scenario);
      let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      loy_manager::burn(coin_amount, &mut treasury_cap, ctx);

      test_scenario::return_to_sender<TreasuryCap<LOY>>(&scenario, treasury_cap);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let coin_exist = test_scenario::has_most_recent_for_sender<coin::Coin<LOY>>(&scenario);
      assert!(coin_exist == false, 0);
      debugger::print_data(&coin_exist);
    };

    test_scenario::end(scenario);
  }
}
