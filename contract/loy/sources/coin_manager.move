module loy::coin_manager {
  use sui::coin::{Self, TreasuryCap};

  public entry fun mint_to<TCOIN>(recipient: address, amount: u64, treasury_cap: &mut TreasuryCap<TCOIN>, ctx: &mut TxContext) {
    let coin_amount = coin::mint(treasury_cap, amount, ctx);
    transfer::public_transfer(coin_amount, recipient)
  }

  public entry fun burn<TCOIN>(coin_amount: coin::Coin<TCOIN>, treasury_cap: &mut TreasuryCap<TCOIN>, _ctx: &mut TxContext) {
    coin::burn(treasury_cap, coin_amount);
  }
}