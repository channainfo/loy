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
  public fun test_list_item_helper() {
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

      marketplace::list_item_helper<Item, LOY>(item, listing_price, listing_date, &mut marketplace, ctx);

      assert!(marketplace::match_marketplace(&marketplace, marketplace::default_marketplace(), 1 ) == true, 0);

      test_scenario::return_shared<Marketplace>(marketplace);
    };

    test_scenario::end(scenario);
  }

  #[test]
  public fun test_delist_item_helper() {

    use sui::test_scenario;
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

      marketplace::list_item_helper<Item, LOY>(item, listing_price, listing_date, &mut mk, ctx);
      test_scenario::return_shared(mk);

      item_id
    };

    loy::debugger::print_data(&item_id);

    test_scenario::next_tx(&mut scenario, other);
    {
      let mut mk = test_scenario::take_shared<Marketplace>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      marketplace::delist_item<Item, LOY>(item_id, &mut mk, ctx);
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

  #[test]
  public fun test_buy_item_sucesss() {

    use sui::test_scenario;
    use sui::coin::{Self, Coin, TreasuryCap};

    use loy::marketplace::{Self, Marketplace};
    use loy::loy::{Self, LOY};
    use loy::coin_manager;

    let owner = @0x001;
    let user1 = @0x0021;
    let user2 = @0x0022;
    let name = b"LOY Default";
    let listing_price: u64 = 25_000;
    let listing_date: u64 = 1_870_000_000_000;

    let total_mint: u64 = 400_000;

    let mut scenario = test_scenario::begin(user1);

    // launch a market place
    {
      let ctx = test_scenario::ctx(&mut scenario);
      marketplace::launch_marketplace(name, ctx)
    };

    // mint an item for user2
    test_scenario::next_tx(&mut scenario, user2);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let item = Item {
        id: object::new(ctx),
        name: option::some(b"LOY CARD"),
        url: option::none()
      };

      transfer::public_transfer(item, user2);
    };

    // user2 send item to be listed
    test_scenario::next_tx(&mut scenario, user2);
    let item_id = {
      let item = test_scenario::take_from_sender<Item>(&scenario);
      let item_id = object::id(&item);

      let mut mk = test_scenario::take_shared<Marketplace>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      marketplace::list_item_helper<Item, LOY>(item, listing_price, listing_date, &mut mk, ctx);
      test_scenario::return_shared(mk);

      item_id
    };

    ::loy::debugger::print_data(&item_id);

    // init coin to the owner
    test_scenario::next_tx(&mut scenario, owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      loy::init_helper(ctx);
    };

    // mint the owner mint coin to user1 for total_mint
    test_scenario::next_tx(&mut scenario, owner);
    {
      let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      coin_manager::mint_to(user1, total_mint, &mut treasury_cap, ctx);
      test_scenario::return_to_sender(&scenario, treasury_cap);
    };

    // user1 buy the item
    test_scenario::next_tx(&mut scenario, user1);
    {
      let mut loy_coin = test_scenario::take_from_sender<Coin<LOY>>(&scenario);
      let mut marketplace = test_scenario::take_shared<Marketplace>(&scenario);

      let ctx = test_scenario::ctx(&mut scenario);

      let paid_coin = coin::split(&mut loy_coin, listing_price, ctx);

      marketplace::buy_item<Item, LOY>(paid_coin, item_id, &mut marketplace, ctx);

      test_scenario::return_shared(marketplace);
      test_scenario::return_to_sender(&scenario, loy_coin);
    };

    test_scenario::next_tx(&mut scenario, user1);
    {
      let item = test_scenario::take_from_sender<Item>(&scenario);
      let loy_coin = test_scenario::take_from_sender<Coin<LOY>>(&scenario);

      assert!(item.name == option::some(b"LOY CARD"), 0);
      assert!(coin::value(&loy_coin) == ( total_mint - listing_price) , 0);

      test_scenario::return_to_sender(&scenario, loy_coin);
      test_scenario::return_to_sender(&scenario, item);
    };
    test_scenario::end(scenario);
  }

  #[test]
  #[expected_failure(abort_code=loy::marketplace::E_PAID_PRICE_INCORRECT)]
  public fun test_buy_item_failure() {

    use sui::test_scenario;
    use sui::coin::{Coin, TreasuryCap};

    use loy::marketplace::{Self, Marketplace};
    use loy::loy::{Self, LOY};
    use loy::coin_manager;

    let owner = @0x001;
    let user1 = @0x0021;
    let user2 = @0x0022;
    let name = b"LOY Default";
    let listing_price: u64 = 25_000;
    let listing_date: u64 = 1_870_000_000_000;

    let total_mint: u64 = 400_000;

    let mut scenario = test_scenario::begin(user1);

    // launch a market place
    {
      let ctx = test_scenario::ctx(&mut scenario);
      marketplace::launch_marketplace(name, ctx)
    };

    // mint an item for user2
    test_scenario::next_tx(&mut scenario, user2);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      let item = Item {
        id: object::new(ctx),
        name: option::some(b"LOY CARD"),
        url: option::none()
      };

      transfer::public_transfer(item, user2);
    };

    // user2 send item to be listed
    test_scenario::next_tx(&mut scenario, user2);
    let item_id = {
      let item = test_scenario::take_from_sender<Item>(&scenario);
      let item_id = object::id(&item);

      let mut mk = test_scenario::take_shared<Marketplace>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      marketplace::list_item_helper<Item, LOY>(item, listing_price, listing_date, &mut mk, ctx);
      test_scenario::return_shared(mk);

      item_id
    };

    ::loy::debugger::print_data(&item_id);

    // init coin to the owner
    test_scenario::next_tx(&mut scenario, owner);
    {
      let ctx = test_scenario::ctx(&mut scenario);
      loy::init_helper(ctx);
    };

    // mint the owner mint coin to user1 for total_mint
    test_scenario::next_tx(&mut scenario, owner);
    {
      let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);

      coin_manager::mint_to(user1, total_mint, &mut treasury_cap, ctx);
      test_scenario::return_to_sender(&scenario, treasury_cap);
    };

    // user1 buy the item
    test_scenario::next_tx(&mut scenario, user1);
    {
      let loy_coin = test_scenario::take_from_sender<Coin<LOY>>(&scenario);
      let mut marketplace = test_scenario::take_shared<Marketplace>(&scenario);

      let ctx = test_scenario::ctx(&mut scenario);

      marketplace::buy_item<Item, LOY>(loy_coin, item_id, &mut marketplace, ctx);

      test_scenario::return_shared(marketplace);
    };
    test_scenario::end(scenario);
  }
}
