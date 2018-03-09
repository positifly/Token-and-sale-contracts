pragma solidity ^0.4.15;

import './BasicERC20Token.sol';

/**
 * @title PULS token
 * @dev Extends ERC20 token.
 */
contract PULSToken is BasicERC20Token {
	// Public variables of the token
	string public constant name = 'PULS Token';
	string public constant symbol = 'PULS';
	uint8 public constant decimals = 18;
	uint256 public constant INITIAL_SUPPLY = 88888888000000000000000000;

	address public crowdsaleAddress;

	// Public structure to support token reservation.
	struct Reserve {
        uint256 pulsAmount;
        uint256 collectedEther;
    }

	mapping (address => Reserve) reserved;

	// Public structure to record locked tokens for a specific lock.
	struct Lock {
		uint256 amount;
		uint256 startTime;	// in seconds since 01.01.1970
		uint256 timeToLock; // in seconds
		bytes32 pulseLockHash;
	}
	
	// Public list of locked tokens for a specific address.
	struct lockList{
		Lock[] lockedTokens;
	}
	
	// Public list of lockLists.
	mapping (address => lockList) addressLocks;

	/**
     * @dev Throws if called by any account other than the crowdsale address.
     */
	modifier onlyCrowdsaleAddress() {
		require(msg.sender == crowdsaleAddress);
		_;
	}

	event TokenReservation(address indexed beneficiary, uint256 amount);
	event RevertingReservation(address addressToRevert);
	event TokenLocking(address addressToLock, uint256 amount, uint256 timeToLock);
	event TokenUnlocking(address addressToUnlock, uint256 amount);


	/**
     * @dev The PULS token constructor sets the initial supply of tokens to the crowdsale address
     * account.
     */
	function PULSToken() public {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		
		crowdsaleAddress = msg.sender;

		Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}


	/**
     * @dev Payable function.
     */
	function () external payable {
	}


	/**
     * @dev Function to check reserved amount of tokens for address.
     *
     * @param _owner Address of owner of the tokens.
     *
     * @return The uint256 specifing the amount of tokens which are held in reserve for this address.
     */
	function reserveOf(address _owner) public constant returns (uint256) {
		return reserved[_owner].pulsAmount;
	}


	/**
     * @dev Function to check reserved amount of tokens for address.
     *
     * @param _buyer Address of buyer of the tokens.
     *
     * @return The uint256 specifing the amount of tokens which are held in reserve for this address.
     */
	function collectedEtherFrom(address _buyer) public constant returns (uint256) {
		return reserved[_buyer].collectedEther;
	}


	/**
     * @dev Function to get number of locks for an address.
     *
     * @param _address Address who owns locked tokens.
     *
     * @return The uint256 length of array.
     */
	function getAddressLockedLength(address _address) public constant returns(uint256 length) {
	    return addressLocks[_address].lockedTokens.length;
	}


	/**
     * @dev Function to get locked tokens amount for specific address for specific lock.
     *
     * @param _address Address of owner of locked tokens.
     * @param _index Index of specific lock.
     *
     * @return The uint256 specifing the amount of locked tokens.
     */
	function getLockedStructAmount(address _address, uint256 _index) public constant returns(uint256 amount) {
	    return addressLocks[_address].lockedTokens[_index].amount;
	}


	/**
     * @dev Function to get start time of lock for specific address.
     *
     * @param _address Address of owner of locked tokens.
     * @param _index Index of specific lock.
     *
     * @return The uint256 specifing the start time of lock in seconds.
     */
	function getLockedStructStartTime(address _address, uint256 _index) public constant returns(uint256 startTime) {
	    return addressLocks[_address].lockedTokens[_index].startTime;
	}


	/**
     * @dev Function to get duration time of lock for specific address.
     *
     * @param _address Address of owner of locked tokens.
     * @param _index Index of specific lock.
     *
     * @return The uint256 specifing the duration time of lock in seconds.
     */
	function getLockedStructTimeToLock(address _address, uint256 _index) public constant returns(uint256 timeToLock) {
	    return addressLocks[_address].lockedTokens[_index].timeToLock;
	}

	
	/**
     * @dev Function to get pulse hash for specific address for specific lock.
     *
     * @param _address Address of owner of locked tokens.
     * @param _index Index of specific lock.
     *
     * @return The bytes32 specifing the pulse hash.
     */
	function getLockedStructPulseLockHash(address _address, uint256 _index) public constant returns(bytes32 pulseLockHash) {
	    return addressLocks[_address].lockedTokens[_index].pulseLockHash;
	}


	/**
     * @dev Function to send tokens after verifing KYC form.
     *
     * @param _beneficiary Address of receiver of tokens.
     *
     * @return True if the operation was successful.
     */
	function sendTokens(address _beneficiary) onlyOwner returns (bool) {
		require (reserved[_beneficiary].pulsAmount > 0);		 // Check if reserved tokens for _beneficiary address is greater then 0

		_transfer(crowdsaleAddress, _beneficiary, reserved[_beneficiary].pulsAmount);

		reserved[_beneficiary].pulsAmount = 0;

		return true;
	}


	/**
     * @dev Function to reserve tokens for buyer after sending ETH to crowdsale address.
     *
     * @param _beneficiary Address of reserver of tokens.
     * @param _pulsAmount Amount of tokens to reserve.
     * @param _eth Amount of eth sent in transaction.
     *
     * @return True if the operation was successful.
     */
	function reserveTokens(address _beneficiary, uint256 _pulsAmount, uint256 _eth) onlyCrowdsaleAddress public returns (bool) {
		require (_beneficiary != 0x0);                       // Prevent transfer to 0x0 address
		require (totalSupply >= _pulsAmount);                // Check if such tokens amount left

		totalSupply = totalSupply.sub(_pulsAmount);
		reserved[_beneficiary].pulsAmount = reserved[_beneficiary].pulsAmount.add(_pulsAmount);
		reserved[_beneficiary].collectedEther = reserved[_beneficiary].collectedEther.add(_eth);

		TokenReservation(_beneficiary, _pulsAmount);
		return true;
	}


	/**
     * @dev Function to revert reservation for some address.
     *
     * @param _addressToRevert Address to which collected ETH will be returned.
     *
     * @return True if the operation was successful.
     */
	function revertReservation(address _addressToRevert) onlyOwner public returns (bool) {
		require (_addressToRevert != 0x0);                       // Prevent transfer to 0x0 address
		require (reserved[_addressToRevert].pulsAmount > 0);	

		totalSupply = totalSupply.add(reserved[_addressToRevert].pulsAmount);
		reserved[_addressToRevert].pulsAmount = 0;

		_addressToRevert.transfer(reserved[_addressToRevert].collectedEther - (20000000000 * 21000));
		reserved[_addressToRevert].collectedEther = 0;

		RevertingReservation(_addressToRevert);
		return true;
	}


	/**
     * @dev Function to lock tokens for some period of time.
     *
     * @param _amount Amount of locked tokens.
     * @param _minutesToLock Days tokens will be locked.
     * @param _pulseLockHash Hash of locked pulse.
     *
     * @return True if the operation was successful.
     */
	function lockTokens(uint256 _amount, uint256 _minutesToLock, bytes32 _pulseLockHash) public returns (bool){
		require(balances[msg.sender] >= _amount);

		Lock memory lockStruct;
        lockStruct.amount = _amount;
        lockStruct.startTime = now;
        lockStruct.timeToLock = _minutesToLock * 1 minutes;
        lockStruct.pulseLockHash = _pulseLockHash;

        addressLocks[msg.sender].lockedTokens.push(lockStruct);
        balances[msg.sender] = balances[msg.sender].sub(_amount);

        TokenLocking(msg.sender, _amount, _minutesToLock);
        return true;
	}


	/**
     * @dev Function to unlock tokens for some period of time.
     *
     * @param _addressToUnlock Addrerss of person with locked tokens.
     *
     * @return True if the operation was successful.
     */
	function unlockTokens(address _addressToUnlock) public returns (bool){
		uint256 i = 0;
		while(i < addressLocks[_addressToUnlock].lockedTokens.length) {
			if (now > addressLocks[_addressToUnlock].lockedTokens[i].startTime + addressLocks[_addressToUnlock].lockedTokens[i].timeToLock) {

				balances[_addressToUnlock] = balances[_addressToUnlock].add(addressLocks[_addressToUnlock].lockedTokens[i].amount);
				TokenUnlocking(_addressToUnlock, addressLocks[_addressToUnlock].lockedTokens[i].amount);

				if (i < addressLocks[_addressToUnlock].lockedTokens.length) {
					for (uint256 j = i; j < addressLocks[_addressToUnlock].lockedTokens.length - 1; j++){
			            addressLocks[_addressToUnlock].lockedTokens[j] = addressLocks[_addressToUnlock].lockedTokens[j + 1];
			        }
				}
		        delete addressLocks[_addressToUnlock].lockedTokens[addressLocks[_addressToUnlock].lockedTokens.length - 1];
				
				addressLocks[_addressToUnlock].lockedTokens.length = addressLocks[_addressToUnlock].lockedTokens.length.sub(1);
			}
			else {
				i = i.add(1);
			}
		}

        return true;
	}
}