pragma solidity ^0.4.21;

import "./DynamicallyMintableToken.sol";

/// @title Recorded dynamically mintable and burnable ERC20 token.
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev The difference between this contract and DynamicallyMintableToken
///   is that the amount of minted tokens is recorded in this contract.
contract RecordedDynamicallyMintableToken is DynamicallyMintableToken {
  using SafeMath for uint;

  uint public totalMinted;
  mapping (address => uint) public userMinted;

  function RecordedDynamicallyMintableToken(string _name, string _symbol, uint8 _decimals) public DynamicallyMintableToken(_name, _symbol, _decimals) {}

  /// getters

  function getTotalState() public view returns (uint _totalSupply, uint _totalMinted, uint _totalMintingSpeed, uint _lastMintedTime) {
    _totalSupply = totalSupply_;
    _totalMinted = totalMinted;
    _totalMintingSpeed = totalMintingSpeed;
    _lastMintedTime = lastMintedTime;
  }

  function getUserState(address _user) public view returns (uint _balance, uint _minted, uint _mintingSpeed, uint _lastMintedTime) {
    _balance = balances[_user];
    _minted = userMinted[_user];
    _mintingSpeed = userMintingSpeed[_user];
    _lastMintedTime = userLastMintedTime[_user];
  }

  function getTotalMinted() public view returns (uint) {
    return totalMinted.add(totalMintingSpeed.mul(now.sub(lastMintedTime)));
  }

  function getUserMinted(address _user) public view returns (uint) {
    return userMinted[_user].add(userMintingSpeed[_user].mul(now.sub(userLastMintedTime[_user])));
  }

  /// internal functions

  function _updateTotalSupply() internal {
    uint _minted = totalMintingSpeed.mul(now.sub(lastMintedTime));
    if (_minted > 0) {
      totalMinted = totalMinted.add(_minted);
      totalSupply_ = totalSupply_.add(_minted);
    }
    if (lastMintedTime != now) {
      lastMintedTime = now;
    }
  }

  function _updateBalanceOf(address _user) internal {
    uint _minted = userMintingSpeed[_user].mul(now.sub(userLastMintedTime[_user]));
    if (_minted > 0) {
      userMinted[_user] = userMinted[_user].add(_minted);
      balances[_user] = balances[_user].add(_minted);
    }
    if (userLastMintedTime[_user] != now) {
      userLastMintedTime[_user] = now;
    }
  }
}
