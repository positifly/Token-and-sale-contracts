pragma solidity ^0.4.15;

import './BasicERC20Token.sol';

contract PULSToken is BasicERC20Token {
	string public constant name = 'PulsToken';
	string public constant symbol = 'PULS';
	uint8 public constant decimals = 18;
	uint256 public constant INITIAL_SUPPLY = 88888888000000000000000000;

	event Buy(address indexed buyer, uint256 amount);

	function PULSToken() public {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}

	function buy(address _buyer, uint256 _amount) returns (bool) { // or public??
		require (_buyer != 0x0);                       // Prevent transfer to 0x0 address
		require (totalSupply >= _amount);               // Check if suchTokens amount left

		totalSupply = totalSupply.sub(_amount);
		balances[_buyer] = balances[_buyer].add(_amount);
		Transfer(address(this), _buyer, _amount);
		return true;
	}
}