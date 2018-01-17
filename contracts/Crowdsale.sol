pragma solidity ^0.4.15;

import './PULSToken.sol';
import './Ownable.sol';
import './StagedCrowdsale.sol';

contract Crowdsale is StagedCrowdsale {
	using SafeMath for uint256;

	PULSToken public token;

	uint256 public startTime;
	uint256 public endTime;
	address public multiSigWallet; 	// address where funds are collected
	uint256 public totalWeiRaised;	// amount of raised money in wei
	bool public hasEnded;	// amount of raised money in wei

	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	modifier notEnded() {
		require(!hasEnded);
		_;
	}

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

	function createTokenContract() internal onlyOwner returns (PULSToken) {
		return new PULSToken();
	}

	function () external payable {
		buyTokens(msg.sender);
	}

	function buyTokens(address beneficiary) payable notEnded {
		require(validPurchase());
		
		uint stageIndex = getCurrentStage();
		Stage storage stageCurrent = stages[stageIndex];

		uint tokens;

		// if put us in new stage - receives with next stage price
		if (totalWeiRaised.add(msg.value) >= stageCurrent.hardcap){
			stageCurrent.closed = now;

			if (stageIndex + 1 <= stages.length - 1) {
				Stage storage stageNext = stages[stageIndex + 1];

				tokens = msg.value.mul(stageNext.price);
				token.buy(address(this), beneficiary, tokens);

				totalWeiRaised = totalWeiRaised.add(msg.value);
				stageNext.invested = stageCurrent.invested.add(msg.value);
			}
			else {
				tokens = msg.value.mul(stageCurrent.price);
				token.buy(address(this), beneficiary, tokens);

				totalWeiRaised = totalWeiRaised.add(msg.value);
				stageCurrent.invested = stageCurrent.invested.add(msg.value);

				hasEnded = true;
			}
		}
		else {
			tokens = msg.value.mul(stageCurrent.price);
			token.buy(address(this), beneficiary, tokens);

			totalWeiRaised = totalWeiRaised.add(msg.value);
			stageCurrent.invested = stageCurrent.invested.add(msg.value);
		}

		TokenPurchase(msg.sender, beneficiary, msg.value, tokens);
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
}

