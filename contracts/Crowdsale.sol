pragma solidity ^0.4.15;

import './PULSToken.sol';
import './Ownable.sol';

contract Crowdsale is Ownable {
	using SafeMath for uint256;

	PULSToken public token;

	uint256 public startTime;
	uint256 public endTime;
	address public multiSigWallet; 	// address where funds are collected
	uint256 public rate;	// how many token units a buyer gets per wei
	uint256 public weiRaised;	// amount of raised money in wei

	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
		require(_startTime >= now);
		require(_endTime >= _startTime);
		require(_rate > 0);
		require(_wallet != address(0));

		token = createTokenContract();
		startTime = _startTime;
		endTime = _endTime;
		rate = _rate;
		multiSigWallet = _wallet;
	}

	function createTokenContract() internal onlyOwner returns (PULSToken) {  // or without onlyOwner modifier
		return new PULSToken();
	}

	function () external payable {
		buyTokens(msg.sender);
	}

	function buyTokens(address beneficiary) payable {
		require(validPurchase());
		

		uint256 weiAmount = msg.value;
		uint256 tokens = weiAmount.mul(rate);	// calculate token amount to be created
		weiRaised = weiRaised.add(weiAmount);	// update state
		
		token.buy(beneficiary, tokens);

		TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
		forwardFunds();
	}

	function forwardFunds() internal {
		multiSigWallet.transfer(msg.value);
	}

	function validPurchase() internal returns (bool) {
		bool withinPeriod = now >= startTime && now <= endTime;
		bool nonZeroPurchase = msg.value != 0;
		return withinPeriod && nonZeroPurchase;
	}

	function hasEnded() public returns (bool) {
		return now > endTime;
	}
}