module loy::coin_locker {
  use sui::coin::{Self, TreasuryCap};
  use sui::balance::{Self, Balance};
  use sui::clock::{Self, Clock};

  const E_DURATION_LT_COMMITMENT: u64 = 1;
  const E_NOT_ENOUGH_COMMITMENT_TIME: u64 = 2;


  public struct CoinLocker<phantom TCOIN> has key, store {
    id: UID,
    start_time: u64,
    end_time: u64,

    commitment_time: u64,
    recipient: address,

    issued_amount: u64,
    amount_remaining: Balance<TCOIN>
  }

  // clock address: 0x6 https://github.com/sui-foundation/sui-move-intro-course/blob/main/unit-three/lessons/6_clock_and_locked_coin.md#clock
  public entry fun mint_and_transfer<TCOIN>(recipient: address, amount: u64, start_time: u64, duration: u64, commitment_time: u64,
    clock_obj: &Clock, treasury_cap: &mut TreasuryCap<TCOIN>, ctx: &mut TxContext) {
    let current_time = clock::timestamp_ms(clock_obj);

    mint_and_transfer_helper(recipient, amount, start_time, duration, commitment_time, current_time, treasury_cap, ctx);
  }

  public fun mint_and_transfer_helper<TCOIN>(recipient: address, amount: u64, start_time: u64, duration: u64, commitment_time: u64,
    current_time: u64, treasury_cap: &mut TreasuryCap<TCOIN>, ctx: &mut TxContext) {

    // let init_time = (start_time < current_time) ? current_time : start_time;
    let init_time = if(start_time < current_time) {
      current_time
    }
    else {
      start_time
    };

    assert!( duration > commitment_time, E_DURATION_LT_COMMITMENT);

    let end_time = init_time + duration;
    let coin_amount = coin::mint<TCOIN>(treasury_cap , amount, ctx);
    let balance = coin::into_balance<TCOIN>(coin_amount);

    let locker = CoinLocker<TCOIN>{
      id: object::new(ctx),
      start_time: init_time,
      end_time,
      commitment_time,
      recipient,
      issued_amount: amount,
      amount_remaining: balance
    };

    transfer::public_transfer(locker, recipient);
  }

  public entry fun claim_vested<TCOIN>(locker: &mut CoinLocker<TCOIN>, clock_obj: &Clock, ctx: &mut TxContext) {
    let current_time = clock::timestamp_ms(clock_obj);

    claim_vested_helper<TCOIN>(locker, current_time, ctx);
  }

  #[allow(lint(self_transfer))]
  public fun claim_vested_helper<TCOIN>(locker: &mut CoinLocker<TCOIN>, current_time: u64, ctx: &mut TxContext) {
    let duration_taken = current_time - locker.start_time;

    assert!(duration_taken > locker.commitment_time, E_NOT_ENOUGH_COMMITMENT_TIME);

    let total_vested_time = (locker.end_time - locker.start_time) - locker.commitment_time;
    let actual_vested_time = duration_taken - locker.commitment_time;

    let vested_amount = ( actual_vested_time * locker.issued_amount ) / total_vested_time ;

    let already_taken_amount = locker.issued_amount - balance::value(&locker.amount_remaining);
    let calculated_amount = vested_amount - already_taken_amount;

    if(calculated_amount > 0) {
      let coin_amount = coin::take(&mut locker.amount_remaining, calculated_amount, ctx);

      let sender = tx_context::sender(ctx);
      transfer::public_transfer(coin_amount, sender);
    }
  }

  //[test_only]
  public fun match_locker<TCOIN>(locker: &CoinLocker<TCOIN>, recipient: address, start_time: u64, end_time: u64, commitment_time: u64,
    isseued_amount: u64, amount_remaining: u64): bool {

    locker.recipient == recipient && locker.issued_amount == isseued_amount && locker.start_time == start_time
    && locker.end_time == end_time && locker.commitment_time == commitment_time && balance::value(&locker.amount_remaining) == amount_remaining
  }
}