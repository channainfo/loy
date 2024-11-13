# Getting Started

## Sui CLI

To begin interacting with the Sui network, use the Sui CLI.

```sh
sui client

> Generated new keypair and alias for address with scheme "ed25519" [musing-carnelian: 0xb8e9c7271d32e3a60c3f008be3b51e941c38dad4c722299c8f4846ae002d72d9]
> Secret Recovery Phrase : [resist *** awake]
# Client for interacting with the Sui network
```

### Sui Networks

#### Listing Networks

Check available Sui network environments.

```sh
sui client envs

> https://fullnode.testnet.sui.io:443
```

**Output:**

```plaintext
│ alias   │ url                                   │ active │
├─────────┼───────────────────────────────────────┼────────┤
│ testnet │ <https://fullnode.testnet.sui.io:443> │ *      │
```

Available Networks:

- **Testnet**: <https://fullnode.testnet.sui.io:443>
- **Devnet**: <https://fullnode.devnet.sui.io:443>

To add a new environment:

```sh
sui client new-env --alias devnet --rpc https://fullnode.devnet.sui.io:443
sui client envs
```

The output will now show both environments.

#### Switching Networks

To switch between environments, use:

```sh
sui client switch --env devnet
```

#### Check Active Network

```sh
sui client active-env
```

### Sui Address Management

#### Create a New Address

To generate a new address:

```sh
sui client new-address ed25519
```

**Output:**

```plaintext
│ alias          │ naughty-hiddenite                                                    │
│ address        │ 0x778bcc16e6aaa7eb69f25afb6e12a0d2682f29871017cc70723b282c5cb9eebd   │
│ keyScheme      │ ed25519                                                              │
│ recoveryPhrase │ riot *** blouse...
```

#### List Local Addresses

To view all local addresses, use:

```sh
sui keytool list
```

or

```sh
sui client addresses
```

#### Switch Active Address

Switch the active address to a different one:

```sh
sui client switch --address naughty-hiddenite
# Active address switched to 0x778bcc16e6aaa7eb69f25afb6e12a0d2682f29871017cc70723b282c5cb9eebd
```

#### Check Active Address

```sh
sui client active-address
# 0x778bcc16e6aaa7eb69f25afb6e12a0d2682f29871017cc70723b282c5cb9eebd
```

#### Local Private Keys

Your local private keys for Sui are stored in:

```sh
cat ~/.sui/sui_config/sui.keystore
```

### Obtaining Sui Tokens

Verify the active environment to ensure it’s set correctly.

#### Request Sui Tokens

```sh
sui client faucet
# Request successful. It can take up to 1 minute to get the coin. Run sui client gas to check your gas coins.
```

#### Check Sui Token Balance

To check your Sui token balance:

```plaintext
╭────────────────────────────────────────────────────────────────────┬────────────────────┬──────────────────╮
│ gasCoinId                                                          │ mistBalance (MIST) │ suiBalance (SUI) │
├────────────────────────────────────────────────────────────────────┼────────────────────┼──────────────────┤
│ 0xc7b33b8bed15849918d04b24439f6b7433d2c7a33eda3cd4b139ba89122b0039 │ 10000000000        │ 10.00            │
╰────────────────────────────────────────────────────────────────────┴────────────────────┴──────────────────╯
```

## Sui Project Setup

Create a new Sui Move project:

```sh
sui move new loy
```

To build and publish the project:

```sh
sui move build
sui client publish --gas-budget 100000000
```

## Running Tests

To run all tests:

```sh
sui move test
```

To run specific tests by name:

```sh
# Run all tests that contain `test_print`
sui move test test_print

# Run all tests from modules containing `debugger`
sui move test debugger

# Learn about other options
sui move test --help
```

## Import to SUI wallet

```sh
cat ~/.sui/sui_config/sui.keystore
[
  "AFYb***DYzG",
  "AAv***OOmV",
  "AKhO***Sars"
]

sui keytool convert AAv***OOmV
```

╭────────────────┬──────────────────────────────────────────────────────────────────────────╮
│ bech32WithFlag │  suiprivkey1qq***etr  │
│ base64WithFlag │  AAv***OOmV                            │
│ hexWithoutFlag │  0bfe24bbab8f88053d63bd6b603b267f98d86ab29191148454ed13172c38e995        │
│ scheme         │  ed25519                                                                 │
╰────────────────┴──────────────────────────────────────────────────────────────────────────╯

Import the private key bech32WithFlag (suiprivkey1qq***etr) to SUI Wallet

## Sui explorer

- PackageID: 0xbebc4482ae0e42472228e324d20b68c68bbfca75d53669678e692c1eabf6f6b9 <https://suiscan.xyz/testnet/object/0xbebc4482ae0e42472228e324d20b68c68bbfca75d53669678e692c1eabf6f6b9/contracts>

## References

### Dev resources

- Test Scenario: <https://github.com/MystenLabs/sui/blob/testnet-v1.36.2/crates/sui-framework/packages/sui-framework/sources/test/test_scenario.move>
- Unit Test: <https://github.com/move-language/move/blob/main/language/documentation/book/src/unit-testing.md#testing-annotations-their-meaning-and-usage>
- Move Std: <https://github.com/MystenLabs/sui/tree/main/crates/sui-framework/packages/move-stdlib/sources>
- Move Lang Ref: <https://github.com/move-language/move/tree/main/language/documentation/book/src>
- SUI Framework: <https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/packages/sui-framework/sources/dynamic_object_field.move>
- SUI Example: <https://github.com/MystenLabs/sui/tree/main/examples>
- Best Practises: <https://docs.sui.io/testnet/build/dev_cheat_sheet>

### Useful links

- Object Type: <https://suiscan.xyz/testnet/object/0xd5120cf05ee931c81baa3eba17867bc170a3925e0ca241c73780697742a7ccd8>

### Invoke contract from CLI

<https://github.com/sui-foundation/sui-move-intro-course/blob/main/unit-three/lessons/2_intro_to_generics.md#calling-functions-with-generics-using-sui-cli>

```sh
sui client call --package $PACKAGE --module $MODULE --function "create_box" --args $OBJECT_ID --type-args 0x2::sui::SUI --gas-budget 10000000
```
