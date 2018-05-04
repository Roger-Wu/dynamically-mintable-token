pragma solidity ^0.4.21;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

/// @title Dynamically mintable and burnable ERC20 token.
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev The contract has the following features:
///   1. A user can mint tokens at a constant and updatable minting speed.
///   2. A user does not have to do anything to "claim" their minted tokens.
///      The balance is continuously updated.
///   3. The totalSupply() and balanceOf() functions return dynamic values
///      as if they are updated every block.
/// @dev Beware that the totalSupply may overflow if total minting speed
///      and the elapsed time is high enough.
contract DynamicallyMintableToken is Ownable, DetailedERC20, StandardToken {
  using SafeMath for uint;

  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);

  // uint public totalSupply_; // declared in BasicToken
  uint public totalMintingSpeed;
  uint public lastMintedTime;
  mapping (address => uint) public userMintingSpeed;
  mapping (address => uint) public userLastMintedTime;

  function DynamicallyMintableToken(string _name, string _symbol, uint8 _decimals) public DetailedERC20(_name, _symbol, _decimals) {}

  /// ERC20 interfaces

  /// totalSupply_ + totalMintingSpeed * (now - lastMintedTime)
  function totalSupply() public view returns (uint) {
    return totalSupply_.add(totalMintingSpeed.mul(now.sub(lastMintedTime)));
  }

  /// balances[_user] + userMintingSpeed[_user] * (now - userLastMintedTime[_user])
  function balanceOf(address _user) public view returns (uint) {
    return balances[_user].add(userMintingSpeed[_user].mul(now.sub(userLastMintedTime[_user])));
  }

  function transfer(address _to, uint _value) public returns (bool) {
    require(_value <= balanceOf(msg.sender));
    if (_value > balances[msg.sender]) {
      _updateBalanceOf(msg.sender);
    }
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    require(_value <= balanceOf(_from));
    if (_value > balances[_from]) {
      _updateBalanceOf(_from);
    }
    return super.transferFrom(_from, _to, _value);
  }

  /// external functions

  function transferAll(address _to) public returns (bool) {
    _updateBalanceOf(msg.sender);
    return super.transfer(_to, balances[msg.sender]);
  }

  /// @notice Allow the contract owner to burn tokens from a user.
  ///   The contract owner can be another contract.
  function burn(address _user, uint _value) public onlyOwner {
    require(_value <= balanceOf(_user));
    // require(_value <= totalSupply()); // should holds if _value <= balanceOf(_user)

    /// update user balance
    if (_value > balances[_user]) {
      _updateBalanceOf(_user);
    }
    balances[_user] = balances[_user].sub(_value);

    /// update total supply
    if (_value > totalSupply_) {
      _updateTotalSupply();
    }
    totalSupply_ = totalSupply_.sub(_value);

    emit Burn(_user, _value);
    emit Transfer(_user, address(0), _value);
  }

  function burnAll(address _user) public onlyOwner returns(uint _balance) {
    _balance = balanceOf(_user);
    burn(_user, _balance);
  }

  /// @notice Allow the contract owner to mint tokens for a user.
  function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  function setMintingSpeed(address _user, uint _value) public onlyOwner {
    uint _oldMintingSpeed = userMintingSpeed[_user];

    /// update user minting speed
    _updateBalanceOf(_user);
    userMintingSpeed[_user] = _value;

    /// update total minting speed
    _updateTotalSupply();
    totalMintingSpeed = totalMintingSpeed.sub(_oldMintingSpeed).add(_value);
  }

  function increaseMintingSpeed(address _user, uint _value) public onlyOwner {
    /// update user minting speed
    _updateBalanceOf(_user);
    userMintingSpeed[_user] = userMintingSpeed[_user].add(_value);

    /// update total minting speed
    _updateTotalSupply();
    totalMintingSpeed = totalMintingSpeed.add(_value);
  }

  function decreaseMintingSpeed(address _user, uint _value) public onlyOwner {
    require(_value <= userMintingSpeed[_user]);
    require(_value <= totalMintingSpeed); // should always holds

    /// update user minting speed
    _updateBalanceOf(_user);
    userMintingSpeed[_user] = userMintingSpeed[_user].sub(_value);

    /// update total minting speed
    _updateTotalSupply();
    totalMintingSpeed = totalMintingSpeed.sub(_value);
  }

  /// getters

  function getTotalMintingState() public view returns (uint _totalSupply, uint _totalMintingSpeed, uint _lastMintedTime) {
    _totalSupply = totalSupply_;
    _totalMintingSpeed = totalMintingSpeed;
    _lastMintedTime = lastMintedTime;
  }

  function getUserMintingState(address _user) public view returns (uint _balance, uint _mintingSpeed, uint _lastMintedTime) {
    _balance = balances[_user];
    _mintingSpeed = userMintingSpeed[_user];
    _lastMintedTime = userLastMintedTime[_user];
  }

  /// internal functions

  function _updateTotalSupply() internal {
    uint _minted = totalMintingSpeed.mul(now.sub(lastMintedTime));
    if (_minted > 0) {
      totalSupply_ = totalSupply_.add(_minted);
    }
    if (lastMintedTime != now) {
      lastMintedTime = now;
    }
  }

  function _updateBalanceOf(address _user) internal {
    uint _minted = userMintingSpeed[_user].mul(now.sub(userLastMintedTime[_user]));
    if (_minted > 0) {
      balances[_user] = balances[_user].add(_minted);
    }
    if (userLastMintedTime[_user] != now) {
      userLastMintedTime[_user] = now;
    }
  }
}
