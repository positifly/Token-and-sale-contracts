pragma solidity ^0.4.21;

import './PULSToken.sol';
import './StagedCrowdsale.sol';

/**
 * @title PULS crowdsale
 * @dev PULS crowdsale functionality.
 */
contract PULSCrowdsale is StagedCrowdsale {
	using SafeMath for uint256;

	PULSToken public token;

	// Public variables of the crowdsale
	address public multiSigWallet; 	// address where funds are collected
	bool public hasEnded;
	bool public isPaused;	


	event TokenReservation(address purchaser, address indexed beneficiary, uint256 indexed sendEther, uint256 indexed pulsAmount);
	event ForwardingFunds(uint256 indexed value);


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
	modifier notPaused() {
		require(!isPaused);
		_;
	}


	/**
     * @dev The Crowdsale constructor sets the multisig wallet for forwanding funds.
     * Adds stages to the crowdsale. Initialize PULS tokens.
     */
	function PULSCrowdsale() public {
		token = createTokenContract();

		multiSigWallet = 0x00955149d0f425179000e914F0DFC2eBD96d6f43;
		hasEnded = false;
		isPaused = false;

		addStage(3000, 1600, 1, 0);   //3rd value is actually div 10
		addStage(3500, 1550, 1, 0);   //3rd value is actually div 10
		addStage(4000, 1500, 1, 0);   //3rd value is actually div 10
		addStage(4500, 1450, 1, 0);   //3rd value is actually div 10
		addStage(42500, 1400, 1, 0);  //3rd value is actually div 10
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
	function buyTokens(address _beneficiary) payable notEnded notPaused public {
		require(msg.value >= 0);
		
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
				token.reserveTokens(_beneficiary, tokens, msg.value, 0);

				stageNext.invested = stageCurrent.invested.add(msg.value);

				stageCurrent.invested = stageCurrent.hardcap;
			}
			else {
				tokens = msg.value.mul(stageCurrent.price);
				token.reserveTokens(_beneficiary, tokens, msg.value, 0);

				stageCurrent.invested = stageCurrent.invested.add(msg.value);

				hasEnded = true;
			}
		}
		else {
			tokens = msg.value.mul(stageCurrent.price);
			token.reserveTokens(_beneficiary, tokens, msg.value, 0);

			stageCurrent.invested = stageCurrent.invested.add(msg.value);
		}

		emit TokenReservation(msg.sender, _beneficiary, msg.value, tokens);
		forwardFunds();
	}


	/**
     * @dev Function to buy tokens - reserve calculated amount of tokens.
     *
     * @param _beneficiary The address of the buyer.
     */
	function privatePresaleTokenReservation(address _beneficiary, uint256 _amount, uint256 _reserveTypeId) onlyOwner public {
		require (_reserveTypeId > 0);
		token.reserveTokens(_beneficiary, _amount, 0, _reserveTypeId);
		emit TokenReservation(msg.sender, _beneficiary, 0, _amount);
	}


	/**
     * @dev Internal function to forward funds to multisig wallet.
     */
	function forwardFunds() internal {
		multiSigWallet.transfer(msg.value);
		emit ForwardingFunds(msg.value);
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
	function unpauseCrowdsale() onlyOwner notEnded public returns (bool) {
		isPaused = false;
		return true;
	}


	/**
     * @dev Function to change multisgwallet.
     *
     * @return True if the operation was successful.
     */ 
	function changeMultiSigWallet(address _newMultiSigWallet) onlyOwner public returns (bool) {
		multiSigWallet = _newMultiSigWallet;
		return true;
	}
}