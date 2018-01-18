pragma solidity ^0.4.15;

contract Ownable {
	address public owner;

	function Ownable() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner {
		require(newOwner != address(0));
		owner = newOwner;
	}
}











contract BasicERC20Token is Ownable {
	using SafeMath for uint256;

	uint256 public totalSupply;
	mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;

	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Approval(address indexed owner, address indexed spender, uint256 amount);
	
	function transfer(address _to, uint256 _amount) public returns (bool) {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address
        require (balances[msg.sender] >= _amount);          // Check if the sender has enough
        require (balances[_to] + _amount > balances[_to]); // Check for overflows

		balances[msg.sender] = balances[msg.sender].sub(_amount);
		balances[_to] = balances[_to].add(_amount);
		Transfer(msg.sender, _to, _amount);
		return true;
	}

	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}

	function getTotalSupply() public constant returns (uint256) {
        return totalSupply;
    }

	function transferFrom(address _from, address _to, uint256 _amount) returns (bool) {
		require (_from != 0x0);                       // Prevent transfer to 0x0 address
		require (_to != 0x0);                         // Prevent transfer to 0x0 address
        require (balances[_from] >= _amount);          // Check if the sender has enough

		var _allowance = allowed[_from][msg.sender];
        require (_allowance > 0);					  // Check if allowed amount is greater then 0

		balances[_to] = balances[_to].add(_amount);
		balances[_from] = balances[_from].sub(_amount);
		allowed[_from][msg.sender] = _allowance.sub(_amount);
		Transfer(_from, _to, _amount);
		return true;
	}

	function approve(address _spender, uint256 _amount) returns (bool) {
		require (_spender != 0x0);                       // Prevent transfer to 0x0 address
		require (balances[msg.sender] >= _amount);		 // Check if the allowencer has enough to allow 
		require ((_amount == 0) || (allowed[msg.sender][_spender] == 0));

		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
	}

	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
}

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





library SafeMath {
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract StagedCrowdsale is Ownable {

    using SafeMath for uint256;

    struct Stage {
        uint256 hardcap;
        uint256 price;
        uint256 invested;
        uint256 closed;
    }

    Stage[] public stages;

    function getCurrentStage() public constant returns(uint256) {
        for(uint256 i=0; i < stages.length; i++) {
            if(stages[i].closed == 0) {
                return i;
            }
        }
        revert();
    }

    function addStage(uint256 hardcap, uint256 price) public onlyOwner {
        require(hardcap > 0 && price > 0);
        Stage memory stage = Stage(hardcap.mul(1 ether), price, 0, 0);
        stages.push(stage);
    }
}

contract Crowdsale is StagedCrowdsale {
	using SafeMath for uint256;

	PULSToken public token;

	uint256 public startTime;
	uint256 public endTime;
	address public multiSigWallet; 	// address where funds are collected
	uint256 public totalWeiRaised;	// amount of raised money in wei
	bool public hasEnded;	// amount of raised money in wei

	event TokenReservation(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

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

	//onlyOwner address is deployer address
	function createTokenContract() internal onlyOwner returns (PULSToken) {
		return new PULSToken();
	}

	function () external payable {
		buyTokens(msg.sender);
	}

	function buyTokens(address beneficiary) payable notEnded {
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
				token.reserve(beneficiary, tokens);

				totalWeiRaised = totalWeiRaised.add(msg.value);
				stageNext.invested = stageCurrent.invested.add(msg.value);

				stageCurrent.invested = stageCurrent.hardcap;
			}
			else {
				tokens = msg.value.mul(stageCurrent.price);
				token.reserve(beneficiary, tokens);

				totalWeiRaised = totalWeiRaised.add(msg.value);
				stageCurrent.invested = stageCurrent.invested.add(msg.value);

				hasEnded = true;
			}
		}
		else {
			tokens = msg.value.mul(stageCurrent.price);
			token.reserve(beneficiary, tokens);

			totalWeiRaised = totalWeiRaised.add(msg.value);
			stageCurrent.invested = stageCurrent.invested.add(msg.value);
		}

		TokenReservation(msg.sender, beneficiary, msg.value, tokens);
		forwardFunds();
	}

	function verifyAddress(address _addressToVerify) public onlyOwner returns(bool) {
		require(hasEnded);
		token.verifyAddressAndTransferTokens(address(this), _addressToVerify);
		return true;
	}

	function forwardFunds() internal {
		multiSigWallet.transfer(msg.value);
	}

	function validPurchase() internal returns (bool) {
		bool withinPeriod = now >= startTime && now <= endTime;
		bool nonZeroPurchase = msg.value > 0;
		return withinPeriod && nonZeroPurchase;
	}
}



contract PULSCrowdsale is Crowdsale {
    function PULSCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet) Crowdsale(_startTime, _endTime, _wallet) {

    }
}