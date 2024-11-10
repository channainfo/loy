#[test_only]
module loy::marketplace_test {
  public struct Item has key, store {
    id: UID,
    name: Option<vector<u8>>,
    url: Option<vector<u8>>
  }

  #[test]
  public fun test_launch_default_marketplace(){
    use loy::marketplace::{Self, Marketplace};
    use sui::test_scenario;

    let sender = @0x001;

    let mut scenario = test_scenario::begin(sender);

    {
      let ctx = test_scenario::ctx(&mut scenario);
      marketplace::launch_default_marketplace(ctx);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let has_marketplace = test_scenario::has_most_recent_shared<Marketplace>();
      assert!(has_marketplace == true, 0);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_list_item() {
    use sui::test_scenario;
    use loy::marketplace::{Self, Marketplace};
    use loy::loy::{LOY};


    let sender = @0x001;
    let other = @002;
    let mut scenario = test_scenario::begin(sender);

    let listing_price = 1_000_000;
    let listing_date = 1_380_000_000_000;

    {
      let ctx = test_scenario::ctx(&mut scenario);
      marketplace::launch_default_marketplace(ctx);
    };

    test_scenario::next_tx(&mut scenario, other);
    {
      let ctx = test_scenario::ctx(&mut scenario);

      let item = Item {
        id: object::new(ctx),
        name: option::some(b"LOY CARD"),
        url: option::none()
      };

      transfer::public_transfer(item, other);
    };

    test_scenario::next_tx(&mut scenario, other);
    {
      let mut marketplace = test_scenario::take_shared<Marketplace>(&scenario);
      let item = test_scenario::take_from_address<Item>(&scenario, other);
      let ctx = test_scenario::ctx(&mut scenario);

      marketplace::list_item<Item, LOY>(item, listing_price, listing_date, &mut marketplace, ctx);
      test_scenario::return_shared<Marketplace>(marketplace);
    };

    test_scenario::end(scenario);
  }
}
