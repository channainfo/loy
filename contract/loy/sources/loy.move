module loy::loy {

  use sui::coin::{Self, TreasuryCap};
  use sui::url;

  // OTW struct
  public struct LOY has drop { }

  public struct AdminCap has key {
    id: UID,
  }

  fun init(witness: LOY, ctx: &mut TxContext) {
    create_admin_cap(ctx);
    create_loy_coin(witness, ctx);
  }

  public entry fun mint(treasury_cap: &mut TreasuryCap<LOY>, amount: u64, recipient: address, ctx: &mut TxContext) {
    coin::mint_and_transfer(treasury_cap, amount, recipient, ctx);
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
      let witness = LOY { };
      init(witness, ctx);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      mint(&mut treasury_cap, 47, recipient, ctx);
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

  #[allow(lint(self_transfer))]
  fun create_loy_coin(witness: LOY, ctx: &mut TxContext) {
    let icon_url = option::some(url::new_unsafe_from_bytes(b"https://silver-blushing-woodpecker-143.mypinata.cloud/ipfs/Qmed2qynTAszs9SiZZpf58QeXcNcYgPnu6XzkD4oeLacU4"));
    let (treasury_cap, coin_metadata) = coin::create_currency(
      witness,
      9,
      b"LOY",
      b"LOY OS COIN",
      b"",
      icon_url,
      ctx
    );
    transfer::public_freeze_object(coin_metadata);
    transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
  }

  #[test]
  fun test_create_loy_coin() {
    use sui::test_scenario;
    use loy::debugger;

    let sender = @0x001;
    let mut scenario = test_scenario::begin(sender);

    {
      let witness = LOY {};
      let ctx = test_scenario::ctx(&mut scenario);
      create_loy_coin(witness, ctx);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let has_treasury_cap = test_scenario::has_most_recent_for_sender<TreasuryCap<LOY>>(&scenario);
      debugger::print_data(&has_treasury_cap);
      assert!(has_treasury_cap == true, 0);
    };

    test_scenario::end(scenario);
  }

  fun create_admin_cap(ctx: &mut TxContext) {
    let admin_cap = AdminCap {
      id: object::new(ctx)
    };
    let sender: address = tx_context::sender(ctx);

    transfer::transfer(admin_cap, sender)
  }

  #[test]
  fun test_create_admin_cap() {
    use sui::test_scenario::{Self, Scenario};

    let sender = @0x001;
    let mut scenario: Scenario = test_scenario::begin(sender);

    {
      let ctx = test_scenario::ctx(&mut scenario);
      create_admin_cap(ctx);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let is_admin_cap = test_scenario::has_most_recent_for_sender<AdminCap>(&scenario);
      assert!(is_admin_cap == true, 0);
    };

    test_scenario::end(scenario);
  }
}