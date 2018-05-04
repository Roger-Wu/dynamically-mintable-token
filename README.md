# dynamically-mintable-token

A token contract allowing users to mint tokens dynamically.

## Contracts

### DynamicallyMintableToken

The contract has the following features:
1. Mintable and burnable ERC20 token.
2. A user can mint tokens at a constant and updatable minting speed.
3. A user does not have to do anything to "claim" their minted tokens. The balance is continuously updated.
4. The totalSupply() and balanceOf() functions return dynamic values as if they are updated every block.

### RecordedDynamicallyMintableToken

The difference between this contract and DynamicallyMintableToken is that the amount of minted tokens is recorded in this contract.

## Getting Started
```
npm install -E openzeppelin-solidity
truffle compile
```