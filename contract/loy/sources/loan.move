module loy::loan {
  use sui::coin::{Self, Coin};
  use sui::balance::{Self,Balance};

  const E_NOT_ENOUGH_AMOUNT: u64 = 1;
  const E_INCORRECT_REPAY_AMOUNT: u64 = 2;

  // Shared pool: money vault
  public struct LoanPool<phantom TCOIN> has key {
    id: UID,
    name: vector<u8>,
    amount: Balance<TCOIN>,
    interest: u64,
  }

  public struct Loan {
    amount: u64,
    interest: u64,
  }

  public fun create_loan_pool<TCOIN>(name: vector<u8>, amount: Coin<TCOIN>, interest: u64, ctx: &mut TxContext) {
    let id = object::new(ctx);
    let amount = coin::into_balance<TCOIN>(amount);

    let loan_pool = LoanPool<TCOIN> {
      id,
      name,
      amount,
      interest
    };

    transfer::share_object(loan_pool);
  }

  public fun deposit_load_pool<TCOIN>(loan_pool: &mut LoanPool<TCOIN>, amount: Coin<TCOIN>, _ctx: &mut TxContext) {
    balance::join(&mut loan_pool.amount, coin::into_balance(amount));
  }

  public fun borrow<TCOIN>(loan_pool: &mut LoanPool<TCOIN>, amount: u64, ctx: &mut TxContext ): (Coin<TCOIN>, Loan) {
    loy::debugger::print_string(b"Amount: ");
    loy::debugger::print_data(&amount);

    let available_amount = balance::value(&loan_pool.amount);

    loy::debugger::print_string(b"Available in the pool:");
    loy::debugger::print_data(&available_amount);
    loy::debugger::print_data(&(amount > available_amount));

    assert!(available_amount > amount, E_NOT_ENOUGH_AMOUNT);

    let borrow_balance = balance::split(&mut loan_pool.amount, amount);
    let borrow_coin = coin::from_balance(borrow_balance, ctx);

    (
      borrow_coin,

      // This ensures the loan is protected since the loan object must be consumed to complete the transaction.
      // We need to define a method, such as 'repay', to allow the loan to be consumed.
      Loan {
        amount: amount,
        interest: loan_pool.interest
      }
    )
  }

  public fun repay<TCOIN>(loan_pool: &mut LoanPool<TCOIN>, loan: Loan, payment: Coin<TCOIN>, _ctx: &mut TxContext) {
    let Loan { amount, interest } = loan;
    let to_repay = amount + ( amount * interest ) / 100;

    assert!( coin::value(&payment) >= to_repay, E_INCORRECT_REPAY_AMOUNT);

    let repay_balance = coin::into_balance(payment);
    balance::join(&mut loan_pool.amount, repay_balance);
  }

  public fun loan_pool_amount<TCOIN>(loan_pool: &LoanPool<TCOIN>): u64 {
    balance::value<TCOIN>(&loan_pool.amount)
  }
}
