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
	address public multiSigWallet; 	// address where funds are collected
	uint256 public totalWeiRaised;	// amount of raised money in wei
	bool public hasEnded;
	bool public isPaused;	

	event TokenReservation(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
	event ForwardingFunds(uint256 value);


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
     * @dev Throws if crowdsale has not ended.
     */
	modifier notPaused() {
		require(!isPaused);
		_;
	}


	/**
     * @dev Throws if crowdsale is not paused.
     */
	modifier paused() {
		require(isPaused);
		_;
	}


	/**
     * @dev The Crowdsale constructor sets the multisig wallet for forwanding funds.
     * Adds stages to the crowdsale. Initialize PULS tokens.
     */
	function Crowdsale() public {
		token = createTokenContract();

		multiSigWallet = '0x00E9c72F684De1C49E45B1c9403d4DD152f93C32';
		totalWeiRaised = 0;
		hasEnded = false;
		isPaused = false;

		addStage(2500, 2000, 10);  //3rd value is actually div 10
		addStage(3000, 1600, 1);   //3rd value is actually div 10
		addStage(3500, 1550, 1);   //3rd value is actually div 10
		addStage(4000, 1500, 1);   //3rd value is actually div 10
		addStage(4500, 1450, 1);   //3rd value is actually div 10
		addStage(42500, 1400, 1);  //3rd value is actually div 10
	}


	/**
     * @dev Function to create PULS tokens contract.
     *
     * @return PULSToken The instance of PULS token contract.
     */
	function createTokenContract() internal returns (PULSToken) {
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
	function buyTokens(address _beneficiary) payable notEnded notPaused {
		require(msg.value > 0);
		
		uint256 stageIndex = getCurrentStage();
		Stage storage stageCurrent = stages[stageIndex];

		require(msg.value >= stageCurrent.minInvestment);

		uint256 tokens;

		// if puts us in new stage - receives with next stage price
		if (stageCurrent.invested.add(msg.value) >= stageCurrent.hardcap){
			stageCurrent.closed = now;

			if (stageIndex + 1 <= stages.length - 1) {
				Stage storage stageNext = stages[stageIndex + 1];

				tokens = msg.value.mul(stageCurrent.price);
				token.reserveTokens(_beneficiary, tokens, msg.value);

				totalWeiRaised = totalWeiRaised.add(msg.value);
				stageNext.invested = stageCurrent.invested.add(msg.value);

				stageCurrent.invested = stageCurrent.hardcap;
			}
			else {
				tokens = msg.value.mul(stageCurrent.price);
				token.reserveTokens(_beneficiary, tokens, msg.value);

				totalWeiRaised = totalWeiRaised.add(msg.value);
				stageCurrent.invested = stageCurrent.invested.add(msg.value);

				hasEnded = true;
			}
		}
		else {
			tokens = msg.value.mul(stageCurrent.price);
			token.reserveTokens(_beneficiary, tokens, msg.value);

			totalWeiRaised = totalWeiRaised.add(msg.value);
			stageCurrent.invested = stageCurrent.invested.add(msg.value);
		}

		TokenReservation(msg.sender, _beneficiary, msg.value, tokens);
		forwardFunds();
	}


	/**
     * @dev Function to buy tokens - reserve calculated amount of tokens.
     *
     * @param _beneficiary The address of the buyer.
     */
	function privatePresaleTokenReservation(address _beneficiary, uint256 _amount) onlyOwner public {
		require (_beneficiary != 0x0);					// Prevent transfer to 0x0 address

		token.reserveTokens(_beneficiary, _amount, 0);
		TokenReservation(msg.sender, _beneficiary, 0, _amount);
	}


	/**
     * @dev Internal function to forward funds to multisig wallet.
     */
	function forwardFunds() internal {
		multiSigWallet.transfer(msg.value);
		ForwardingFunds(msg.value);
	}


	/**
     * @dev Function to finish the crowdsale.
     *
     * @return True if the operation was successful.
     */ 
	function finishCrowdsale() onlyOwner notEnded public returns (bool) {
		hasEnded = true;
		return true;
	}


	/**
     * @dev Function to pause the crowdsale.
     *
     * @return True if the operation was successful.
     */ 
	function pauseCrowdsale() onlyOwner notEnded notPaused public returns (bool) {
		isPaused = true;
		return true;
	}


	/**
     * @dev Function to unpause the crowdsale.
     *
     * @return True if the operation was successful.
     */ 
	function unpauseCrowdsale() onlyOwner notEnded paused public returns (bool) {
		isPaused = false;
		return true;
	}
}

