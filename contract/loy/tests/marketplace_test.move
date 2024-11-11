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

      assert!(marketplace::match_marketplace(&marketplace, marketplace::default_marketplace(), 1 ) == true, 0);

      test_scenario::return_shared<Marketplace>(marketplace);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_delist() {

    use sui::test_scenario;
    use sui::coin::{Coin};
    use loy::loy::{LOY};
    use loy::marketplace::{Self, Marketplace};

    let sender = @0x001;
    let other = @0x002;
    let listing_price: u64 = 25_000;
    let listing_date: u64 = 1_870_000_000_000;
    let marketplace_name = b"New Arrival";

    let mut scenario = test_scenario::begin(sender);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      marketplace::launch_marketplace(marketplace_name, ctx);
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
    let item_id = {
      let item = test_scenario::take_from_sender<Item>(&scenario);
      let item_id = object::id(&item);

      let mut mk = test_scenario::take_shared<Marketplace>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      marketplace::list_item<Item, Coin<LOY>>(item, listing_price, listing_date, &mut mk, ctx);
      test_scenario::return_shared(mk);

      item_id
    };

    loy::debugger::print_data(&item_id);

    test_scenario::next_tx(&mut scenario, other);
    {
      let mut mk = test_scenario::take_shared<Marketplace>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      marketplace::delist_item<Item, Coin<LOY>>(item_id, &mut mk, ctx);
      test_scenario::return_shared(mk);
    };

    test_scenario::next_tx(&mut scenario, other);
    {
      let item = test_scenario::take_from_sender<Item>(&scenario);
      let mk = test_scenario::take_shared<Marketplace>(&scenario);

      assert!(item.name == option::some(b"LOY CARD"), 0);
      assert!(marketplace::match_marketplace(&mk, marketplace_name, 0) == true, 0);

      test_scenario::return_to_sender<Item>(&scenario, item);
      test_scenario::return_shared<Marketplace>(mk);
    };
    test_scenario::end(scenario);

  }
}
