pragma solidity ^0.4.15;

import './PULSToken.sol';
import './StagedCrowdsale.sol';

/**
 * @title Basic crowdsale
 * @dev Basic crowdsale functionality.
 */
contract Crowdsale is StagedCrowdsale {
	using SafeMath for uint256;

	PULSToken public token;

	// Public variables of the crowdsale
	uint256 public startTime;
	uint256 public endTime;
	address public multiSigWallet; 	// address where funds are collected
	uint256 public totalWeiRaised;	// amount of raised money in wei
	bool public hasEnded;	// amount of raised money in wei

	event TokenReservation(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


	/**
     * @dev Throws if crowdsale has ended.
     */
	modifier notEnded() {
		require(!hasEnded);
		_;
	}


	/**
     * @dev Throws if crowdsale has not ended.
     */
	modifier ended() {
		require(hasEnded);
		_;
	}


	/**
     * @dev The Crowdsale constructor sets the start time, end time and multisig wallet for forwanding funds.
     * Adds stages to the crowdsale. Initialize PULS tokens.
     *
     * @param _startTime The start time of the crowdsale.
     * @param _endTime The end time of the crowdsale.
     * @param _wallet The address of multisig lawyers address.
     */
	function Crowdsale(uint256 _startTime, uint256 _endTime, address _wallet) public {
		require(_startTime >= now);
		require(_endTime >= _startTime);
		require(_wallet != address(0));

		token = createTokenContract();
		startTime = _startTime;
		endTime = _endTime;
		multiSigWallet = _wallet;
		totalWeiRaised = 0;
		hasEnded = false;

		addStage(1,1000);
		addStage(2,2000);
		addStage(3,3000);
	}


	/**
     * @dev Function to create PULS tokens contract.
     *
     * @return PULSToken The instance of PULS token contract.
     */
	function createTokenContract() internal onlyOwner returns (PULSToken) {
		return new PULSToken();
	}


	/**
     * @dev Payable function.
     */
	function () external payable {
		buyTokens(msg.sender);
	}


	/**
     * @dev Function to buy tokens - reserve calculated amount of tokens.
     *
     * @param _beneficiary The address of the buyer.
     */
	function buyTokens(address _beneficiary) payable notEnded {
		require(validPurchase());
		
		uint256 stageIndex = getCurrentStage();
		Stage storage stageCurrent = stages[stageIndex];

		uint256 tokens;

		// if put us in new stage - receives with next stage price
		if (totalWeiRaised.add(msg.value) >= stageCurrent.hardcap){
			stageCurrent.closed = now;

			if (stageIndex + 1 <= stages.length - 1) {
				Stage storage stageNext = stages[stageIndex + 1];

				tokens = msg.value.mul(stageNext.price);
				token.reserveTokens(_beneficiary, tokens);

				totalWeiRaised = totalWeiRaised.add(msg.value);
				stageNext.invested = stageCurrent.invested.add(msg.value);

				stageCurrent.invested = stageCurrent.hardcap;
			}
			else {
				tokens = msg.value.mul(stageCurrent.price);
				token.reserveTokens(_beneficiary, tokens);

				totalWeiRaised = totalWeiRaised.add(msg.value);
				stageCurrent.invested = stageCurrent.invested.add(msg.value);

				hasEnded = true;
			}
		}
		else {
			tokens = msg.value.mul(stageCurrent.price);
			token.reserveTokens(_beneficiary, tokens);

			totalWeiRaised = totalWeiRaised.add(msg.value);
			stageCurrent.invested = stageCurrent.invested.add(msg.value);
		}

		TokenReservation(msg.sender, _beneficiary, msg.value, tokens);
		forwardFunds();
	}


	/**
     * @dev Function to verify buyer's address.
     *
     * @param _addressToVerify The address of buyer to be verified.
     */
	function verifyAddress(address _addressToVerify) public ended onlyOwner {
		token.verifyAddressAndSendTokens(address(this), _addressToVerify);
	}


	/**
     * @dev Internal function to forward funds to multisig wallet.
     */
	function forwardFunds() internal {
		multiSigWallet.transfer(msg.value);
	}


	/**
     * @dev Internal function to check purchase validation.
     *
     * @return A boolean value of purchase validation.
     */
	function validPurchase() internal returns (bool) {
		bool withinPeriod = now >= startTime && now <= endTime;
		bool nonZeroPurchase = msg.value > 0;
		return withinPeriod && nonZeroPurchase;
	}
}

