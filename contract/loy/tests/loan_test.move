#[test_only]
module loy::loan_test {
  use sui::balance::{Balance};
  use sui::coin::{Self, Coin, TreasuryCap};

  use loy::loy::{Self, LOY};
  use loy::loan::{Self, LoanPool};
  use loy::debugger;

  public struct CardTest has key {
    id: UID,
    price: Balance<LOY>,
    point: u64
  }

  public fun mint_card(payment: Coin<LOY>, ctx: &mut TxContext): CardTest {

    let id = object::new(ctx);

    CardTest {
      id,
      price: coin::into_balance(payment),
      point: 0
    }
  }

  public fun sell_card(card: CardTest, ctx: &mut TxContext): Coin<LOY> {
    let CardTest { id, price, point: _point } = card;

    object::delete(id);
    coin::from_balance(price, ctx)
  }

  #[test]
  public fun test_ptb(){
    use sui::test_scenario;

    let sender = @0x001;
    // let other = @0x002;
    let minted_amount: u64 = 50_000_000;
    let pool_name = b"LoadLOY";
    let interest: u64 = 5;


    let mut scenario = test_scenario::begin(sender);

    {
      let ctx = test_scenario::ctx(&mut scenario);
      loy::init_helper(ctx);
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);
      let ctx = test_scenario::ctx(&mut scenario);
      let minted = loy::mint(&mut treasury_cap, minted_amount, ctx);
      loan::create_loan_pool<LOY>(pool_name, minted, interest, ctx);
      test_scenario::return_to_sender(&scenario, treasury_cap)
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<LOY>>(&scenario);
      let mut loan_pool = test_scenario::take_shared<LoanPool<LOY>>(&scenario);

      debugger::print_data(&loan::loan_pool_amount(&loan_pool));

      let ctx = test_scenario::ctx(&mut scenario);
      // let minted = loy::mint(&mut treasury_cap, minted_amount, ctx);

      let borrow_amount: u64 = 1_000_000;
      let (mut borrow_coin, borrow_loan) = loan::borrow<LOY>(&mut loan_pool, borrow_amount, ctx);

      let interest_amount = (borrow_amount * interest ) / 100;
      let earn = loy::mint(&mut treasury_cap, interest_amount, ctx);

      coin::join(&mut borrow_coin, earn);

      loan::repay<LOY>(&mut loan_pool, borrow_loan, borrow_coin, ctx);

      test_scenario::return_shared(loan_pool);
      test_scenario::return_to_sender(&scenario, treasury_cap)
    };

    test_scenario::next_tx(&mut scenario, sender);
    {
      let loan_pool = test_scenario::take_shared<LoanPool<LOY>>(&scenario);
      let balance_amount = loan::loan_pool_amount(&loan_pool);

      assert!(balance_amount == 50_050_000, 0);

      test_scenario::return_shared(loan_pool);
    };
    test_scenario::end(scenario);
  }

}