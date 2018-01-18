pragma solidity ^0.4.15;

import './BasicERC20Token.sol';

contract PULSToken is BasicERC20Token {
	string public constant name = 'PulsToken';
	string public constant symbol = 'PULS';
	uint8 public constant decimals = 18;
	uint256 public constant INITIAL_SUPPLY = 88888888000000000000000000;

	struct Reserve {
        uint256 amount;
        bool verified;
    }

	mapping (address => Reserve) reserved;

	event Verify(address indexed verifiedAddress, uint256 amount);

	function PULSToken() public {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}

	function sendTokens(address _wallet, address _beneficiary, uint256 _amount) internal onlyOwner returns (bool) {
		require (_beneficiary != 0x0);                       // Prevent transfer to 0x0 address
		require (totalSupply >= _amount);               // Check if suchTokens amount left

		balances[_wallet] = balances[_wallet].sub(_amount);
		balances[_beneficiary] = balances[_beneficiary].add(_amount);

		reserved[_beneficiary].amount = 0;
		reserved[_beneficiary].verified = false;

		Transfer(_wallet, _beneficiary, _amount);
		return true;
	}

	function reserve(address _beneficiary, uint256 _amount) public onlyOwner returns (bool) {
		require (_beneficiary != 0x0);                       // Prevent transfer to 0x0 address
		require (totalSupply >= _amount);               // Check if suchTokens amount left

		totalSupply = totalSupply.sub(_amount);
		reserved[_beneficiary].amount = reserved[_beneficiary].amount.add(_amount);
		reserved[_beneficiary].verified = false;
		return true;
	}

	//onlyOwner address is PULSCrowdsale address
	function verifyAddressAndTransferTokens(address _wallet, address _addressToVerify) public onlyOwner returns (bool) {
		require (_addressToVerify != 0x0);                       // Prevent transfer to 0x0 address
		require(reserved[_addressToVerify].amount > 0);
		require(reserved[_addressToVerify].verified == false);

		reserved[_addressToVerify].verified = true;
		Verify(_addressToVerify, reserved[_addressToVerify].amount);
		sendTokens(_wallet, _addressToVerify, reserved[_addressToVerify].amount);	
		return true;
	}

	function reserveOf(address _owner) public constant returns (uint256) {
		return reserved[_owner].amount;
	}
}