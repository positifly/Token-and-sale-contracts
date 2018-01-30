pragma solidity ^0.4.15;

import './BasicERC20Token.sol';

/**
 * @title PULS token
 * @dev Extended ERC20 token.
 */
contract PULSToken is BasicERC20Token {
	// Public variables of the token
	string public constant name = 'PulsToken';
	string public constant symbol = 'PULS';
	uint8 public constant decimals = 18;
	uint256 public constant INITIAL_SUPPLY = 88888888000000000000000000;

	address public crowdsaleAddress;

	// Public structure of reserved tokens.
	struct Reserve {
        uint256 amount;
        bool verified;
    }

	mapping (address => Reserve) reserved;


	/**
     * @dev Throws if called by any account other than the crowdsale address.
     */
	modifier onlyCrowdsaleAddress() {
		require(msg.sender == crowdsaleAddress);
		_;
	}

	event Verify(address indexed verifiedAddress, uint256 amount);


	/**
     * @dev The PULSToken constructor sets the initial supply of tokens to the crowdsale address
     * account.
     */
	function PULSToken() public {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		
		crowdsaleAddress = msg.sender;

		Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}


	/**
     * @dev Function to send tokens after verifing KYC form.
     *
     * @param _crowdsaleWallet The address of the crowdsale wallet.
     * @param _beneficiary The address of tokens receiver.
     * @param _amount The amount of tokens to send.
     *
     * @return The boolean value depending on function result.
     */
	function sendTokens(address _crowdsaleWallet, address _beneficiary, uint256 _amount) internal onlyCrowdsaleAddress returns (bool) {
		require (_beneficiary != 0x0);                       // Prevent transfer to 0x0 address
		require (balances[_crowdsaleWallet] >= _amount);

		balances[_crowdsaleWallet] = balances[_crowdsaleWallet].sub(_amount);
		balances[_beneficiary] = balances[_beneficiary].add(_amount);

		reserved[_beneficiary].amount = 0;

		Transfer(_crowdsaleWallet, _beneficiary, _amount);
		return true;
	}


	/**
     * @dev Function to reserve tokens for buyer after sending ETH to crowdsale address.
     *
     * @param _beneficiary The address of tokens reserver.
     * @param _amount The amount of tokens to reserve.
     *
     * @return The boolean value depending on function result.
     */
	function reserveTokens(address _beneficiary, uint256 _amount) public onlyCrowdsaleAddress returns (bool) {
		require (_beneficiary != 0x0);                       // Prevent transfer to 0x0 address
		require (totalSupply >= _amount);               	 // Check if suchTokens amount left

		totalSupply = totalSupply.sub(_amount);
		reserved[_beneficiary].amount = reserved[_beneficiary].amount.add(_amount);
		reserved[_beneficiary].verified = false;
		return true;
	}


	/**
     * @dev Function to verify buyer address and send tokens to this address calling internal function sendTokens.
     *
     * @param _crowdsaleWallet The address of the crowdsale wallet.
     * @param _addressToVerify The addrerss to verify.
     *
     * @return The boolean value depending on function result.
     */
	function verifyAddressAndSendTokens(address _crowdsaleWallet, address _addressToVerify) public onlyCrowdsaleAddress returns (bool) {
		require (_addressToVerify != 0x0);                       // Prevent transfer to 0x0 address
		require(reserved[_addressToVerify].amount > 0);
		require(reserved[_addressToVerify].verified == false);

		reserved[_addressToVerify].verified = true;
		Verify(_addressToVerify, reserved[_addressToVerify].amount);
		sendTokens(_crowdsaleWallet, _addressToVerify, reserved[_addressToVerify].amount);	
		return true;
	}

	/**
     * @dev Function to check reserved amount of tokens for address.
     *
     * @return The uint256 specifing the amount of tokens which are holding by this address.
     */
	function reserveOf(address _owner) public constant returns (uint256) {
		return reserved[_owner].amount;
	}

	// function freezeTokens(uint256 _amount){
	// 	require(msg.sender != 0x0);
	// 	require(balances[msg.sender] >= _amount);
	// }
}