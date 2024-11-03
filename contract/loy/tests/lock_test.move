#[test_only]
module loy::lock_test {

  #[test]
  public fun test_mint_and_transfer() {
    use sui::test_scenario;
    use sui::coin::{TreasuryCap};

    use loy::loy::{Self, LOY};
    use loy::lock::{Self, Locker};

    let sender = @0x01;
    let recipient = @0x02;

    let amount = 1_000_000;
    let start_time = 0; // current time
    let current_time = 1_730_457_891_166u64; // Fri 1 Nov 2024
    let duration_5years = 157_784_760 * 1000;
    let commitment_1year = 31_556_952 * 1000;

    let mut scenario = test_scenario::begin(sender);

    {
      // 1. admin publish the package
      let ctx = test_scenario::ctx(&mut scenario);
      loy::init_helper(ctx);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      // 2. admin min the lock token to the recipient
      let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      lock::mint_and_transfer(recipient, amount, start_time, duration_5years, commitment_1year, current_time, &mut treasury_cap, ctx);

      test_scenario::return_to_address(sender, treasury_cap);
    };

    test_scenario::next_tx(&mut scenario, recipient);
    {
      // 3. verify if the recipient recient the lock token correctly
      let locker = test_scenario::take_from_address<Locker<LOY>>(&scenario, recipient);
      let end_time = current_time + duration_5years;
      let matched = lock::match_locker(&locker, recipient, current_time, end_time, commitment_1year, amount, amount);
      assert!(matched == true, 0);
      test_scenario::return_to_address(recipient, locker);
    };

    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=loy::lock::E_NOT_ENOUGH_COMMITMENT_TIME)]
  public fun test_claim_vested_with_6months(){
    use sui::test_scenario;
    use sui::coin::{TreasuryCap};

    use loy::loy::{Self, LOY };
    use loy::lock::{Self, Locker};

    let sender = @0x01;
    let recipient = @0x02;

    let amount = 1_000_000;
    let start_time = 0; // current time
    let current_time = 1_730_457_891_166u64; // Fri 1 Nov 2024
    let duration_5years = 157_784_760 * 1000;
    let commitment_1year = 31_556_952 * 1000;

    let mut scenario = test_scenario::begin(sender);

    {
      let ctx = test_scenario::ctx(&mut scenario);
      loy::init_helper(ctx);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(& scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      lock::mint_and_transfer(recipient, amount, start_time,
        duration_5years, commitment_1year, current_time, &mut treasury_cap, ctx);

      test_scenario::return_to_sender<TreasuryCap<LOY>>(&scenario, treasury_cap);
    };

    test_scenario::next_tx(&mut scenario, recipient);

    {
      let commitment_6months = 15778476*1000;
      let after_6months: u64 = current_time + commitment_6months;
      let mut locker = test_scenario::take_from_sender<Locker<LOY>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      lock::claim_vested<LOY>(&mut locker, after_6months, ctx);

      test_scenario::return_to_sender(&scenario, locker);
    };
    test_scenario::end(scenario);
  }

  #[test]
  public fun test_claim_vested_with_3years(){
    use sui::test_scenario;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::balance;

    use loy::loy::{Self, LOY };
    use loy::lock::{Self, Locker};
    use loy::debugger;

    let sender = @0x01;
    let recipient = @0x02;

    let amount = 1_000_000;
    let start_time = 0; // current time
    let current_time = 1_730_457_891_166u64; // Fri 1 Nov 2024
    let duration_5years = 157_784_760 * 1000;
    let commitment_1year = 31_556_952 * 1000;

    let mut scenario = test_scenario::begin(sender);

    {
      let ctx = test_scenario::ctx(&mut scenario);
      loy::init_helper(ctx);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(& scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      lock::mint_and_transfer(recipient, amount, start_time,
        duration_5years, commitment_1year, current_time, &mut treasury_cap, ctx);

      test_scenario::return_to_sender<TreasuryCap<LOY>>(&scenario, treasury_cap);
    };

    let commitment_3years = 94670856*1000;
    let after_3years: u64 = current_time + commitment_3years;
    let end_time = current_time + duration_5years;

    // After 3 years, he tries to claim the vested token
    test_scenario::next_tx(&mut scenario, recipient);
    {
      let mut locker = test_scenario::take_from_sender<Locker<LOY>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      lock::claim_vested<LOY>(&mut locker, after_3years, ctx);
      test_scenario::return_to_sender(&scenario, locker);
    };

    test_scenario::next_tx(&mut scenario, recipient);
    {
      let loy_coin = test_scenario::take_from_sender<Coin<LOY>>(&scenario);
      let coin_value = balance::value(coin::balance(&loy_coin));

      // He recieves, a half
      assert!(coin_value == 500_000, 0);
      test_scenario::return_to_sender(&scenario, loy_coin);

      // He has left half
      let locker = test_scenario::take_from_sender<Locker<LOY>>(&scenario);
      debugger::print_data(&locker);
      let matched = lock::match_locker(&locker, recipient, current_time, end_time, commitment_1year, amount, 500_000);
      assert!(matched == true, 0);

      test_scenario::return_to_sender(&scenario, locker);
    };

    // He tries to claim the vested token again, nothing changes
    test_scenario::next_tx(&mut scenario, recipient);
    {
      let mut locker = test_scenario::take_from_sender<Locker<LOY>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      lock::claim_vested<LOY>(&mut locker, after_3years, ctx);
      test_scenario::return_to_sender(&scenario, locker);
    };

    test_scenario::next_tx(&mut scenario, recipient);
    {
      let loy_coin = test_scenario::take_from_sender<Coin<LOY>>(&scenario);
      let coin_value = balance::value(coin::balance(&loy_coin));

      // He recieves, a half
      assert!(coin_value == 500_000, 0);
      debugger::print_data(&loy_coin);
      debugger::print_data(&coin_value);
      test_scenario::return_to_sender(&scenario, loy_coin);

      // He has left half
      let locker = test_scenario::take_from_sender<Locker<LOY>>(&scenario);
      debugger::print_data(&locker);
      let matched = lock::match_locker(&locker, recipient, current_time, end_time, commitment_1year, amount, 500_000);
      assert!(matched == true, 0);

      test_scenario::return_to_sender(&scenario, locker);
    };

    test_scenario::end(scenario);
  }
}

