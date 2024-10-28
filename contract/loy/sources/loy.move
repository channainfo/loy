module loy::loy {

  public struct AdminCap has key {
    id: UID,
  }

  fun init(ctx: &mut TxContext) {
    create_admin_cap(ctx);
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