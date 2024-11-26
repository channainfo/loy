module loy::loy {

  use sui::coin::{Self, Coin, TreasuryCap};
  use sui::url;

  // OTW struct
  public struct LOY has drop { }

  public struct AdminCap has key {
    id: UID,
  }

  fun init(witness: LOY, ctx: &mut TxContext) {
    create_loy_coin(witness, ctx);
    create_admin_cap(ctx);
  }

  public entry fun mint_and_transfer(treasury_cap: &mut TreasuryCap<LOY>, amount: u64, recipient: address, ctx: &mut TxContext) {
    coin::mint_and_transfer(treasury_cap, amount, recipient, ctx);
  }

  public fun mint(treasury_cap: &mut TreasuryCap<LOY>, amount: u64, ctx: &mut TxContext): Coin<LOY> {
    coin::mint(treasury_cap, amount, ctx)
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

  fun create_admin_cap(ctx: &mut TxContext) {
    let admin_cap = AdminCap {
      id: object::new(ctx)
    };
    let sender: address = tx_context::sender(ctx);

    transfer::transfer(admin_cap, sender)
  }

  #[test_only]
  public fun init_helper( ctx: &mut TxContext){
    init(LOY {}, ctx);
  }

}