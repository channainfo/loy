module loy::marketplace {
  use sui::bag::{Self, Bag};
  use sui::clock::{Self, Clock};
  use sui::coin::{Self, Coin};

  const E_OWNER_INCORRECT: u64 = 1;
  const E_PAID_PRICE_INCORRECT: u64 = 2;

  const DEFAULT_NAME: vector<u8> = b"default";

  public struct Marketplace has key, store {
    id: UID,
    name: vector<u8>,
    product_counts: u64,

    listing_fee: u8,
    purchase_fee: u8,

    products: Bag,
    payments: Bag,
  }

  public struct ItemListing< T: key+store, phantom TCOIN> has key, store {
    id: UID,
    item: T,
    listing_price: u64,
    listing_date: u64,
    owner_address: address,
  }

  fun init(ctx: &mut TxContext) {
    let default_marketplace = Marketplace {
      id: object::new(ctx),
      name: DEFAULT_NAME,
      listing_fee: 0,
      purchase_fee: 0,
      product_counts: 0,
      products: bag::new(ctx),
      payments: bag::new(ctx),
    };

    transfer::public_share_object(default_marketplace);
  }

  public fun launch_marketplace(name: vector<u8>, listing_fee: u8, purchase_fee: u8, ctx: &mut TxContext): Marketplace {
    let id = object::new(ctx);

     Marketplace {
      id,
      name,
      product_counts: 0,
      listing_fee,
      purchase_fee,
      products: bag::new(ctx),
      payments: bag::new(ctx),
     }
  }

  public fun list_item<T: key+store, TCOIN>(listing_price: u64, item: T, marketplace: &mut Marketplace, clock: &Clock, ctx: &mut TxContext) {

    let id = object::new(ctx);
    let listing_date = clock::timestamp_ms(clock);
    let owner_address = tx_context::sender(ctx);

    let product_listing = ItemListing<T, TCOIN> {
      id,
      item,
      listing_price,
      listing_date,
      owner_address
    };

    let key = object::id(&product_listing);
    bag::add<ID, ItemListing<T, TCOIN>>(&mut marketplace.products, key, product_listing);
    marketplace.product_counts = marketplace.product_counts + 1;
  }

  #[allow(lint(self_transfer))]
  public fun delist_item<T: key+store, TCOIN>(item_id: ID, marketplace: &mut Marketplace, ctx: &mut TxContext) {
    let owner_address = tx_context::sender(ctx);
    let product_listing = bag::remove<ID, ItemListing<T, TCOIN>>(&mut marketplace.products, item_id);

    assert!(product_listing.owner_address == owner_address, E_OWNER_INCORRECT);

    let ItemListing { id: id, item, listing_price:_price, listing_date: _date, owner_address: _owner } = product_listing;
    marketplace.product_counts = marketplace.product_counts - 1;

    object::delete(id);
    transfer::public_transfer(item, owner_address);
  }

  #[allow(lint(self_transfer))]
  public fun purchase_product<T: key+store, TCOIN>(paid_amount: Coin<TCOIN>, item_id: ID, marketplace: &mut Marketplace, ctx: &mut TxContext){
    let product_listing = bag::remove<ID, ItemListing<T, TCOIN>>(&mut marketplace.products, item_id);
    let ItemListing { id: id, item, listing_price, listing_date: _date, owner_address } = product_listing;

    assert!(coin::value(&paid_amount) == listing_price, E_PAID_PRICE_INCORRECT);

    if(bag::contains(&marketplace.payments, owner_address)) {
      let total_coin = bag::borrow_mut<address, Coin<TCOIN>>(&mut marketplace.payments, owner_address);
      coin::join(total_coin, paid_amount);
    }
    else {
      bag::add(&mut marketplace.payments, owner_address, paid_amount);
    };

    object::delete(id);

    let sender = tx_context::sender(ctx);
    transfer::public_transfer(item, sender);
  }
}
