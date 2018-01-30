pragma solidity ^0.4.15;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control.
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;

	/**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
	function Ownable() {
		owner = tx.origin;
	}


	/**
     * @dev Throws if called by any account other than the owner.
     */
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     *
     * @param _newOwner The address to transfer ownership to.
     */
	function transferOwnership(address _newOwner) onlyOwner {
		require(_newOwner != address(0));
		owner = _newOwner;
	}
}










/**
 * @title BasicERC20 token.
 * @dev Basic version of ERC20 token with allowances.
 */
contract BasicERC20Token is Ownable {
	using SafeMath for uint256;

	uint256 public totalSupply;
	mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;

	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Approval(address indexed owner, address indexed spender, uint256 amount);

	/**
     * @dev Function to transfer tokens.
     *
     * @param _to The address of the recipient.
     * @param _amount the amount to send.
     *
     * @return The boolean value depending on function result.
     */
	function transfer(address _to, uint256 _amount) public returns (bool) {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address
        require (balances[msg.sender] >= _amount);          // Check if the sender has enough
        require (balances[_to] + _amount > balances[_to]);  // Check for overflows

		balances[msg.sender] = balances[msg.sender].sub(_amount);
		balances[_to] = balances[_to].add(_amount);
		Transfer(msg.sender, _to, _amount);
		return true;
	}


	/**
     * @dev Function to check the amount of tokens for address.
     *
     * @param _owner address The address which owns the tokens.
     * 
     * @return A uint256 specifing the amount of tokens still avaible for the spender.
     */
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}


	/**
     * @dev Function to check the total supply of tokens.
     *
     * @return The uint256 specifing the amount of tokens which are holding by the contract.
     */
	function getTotalSupply() public constant returns (uint256) {
        return totalSupply;
    }


    /**
     * @dev Transfer tokens from other address.
     *
     * @param _from The address of the sender.
     * @param _to The address of the recipient.
     * @param _amount the amount to send.
     *
  	 * @return The boolean value depending on function result.
     */
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


	/**
     * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * 
     * @param _spender The address which will spend the funds.
     * @param _amount The amount of tokens to be spent.
     *
     * @return The boolean value depending on function result.
     */
	function approve(address _spender, uint256 _amount) returns (bool) {
		require (_spender != 0x0);                       // Prevent transfer to 0x0 address
		require (balances[msg.sender] >= _amount);		 // Check if the allowencer has enough to allow 
		require ((_amount == 0) || (allowed[msg.sender][_spender] == 0));

		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
	}


    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     *
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     *
     * @return The uint256 specifing the amount of tokens still avaible for the spender.
     */
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
}

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





/**
 * @title SafeMath.
 * @dev Math operations with safety checks that throw on error.
 */
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

/**
 * @title Staged crowdsale.
 * @dev Functionality of staged crowdsale.
 */
contract StagedCrowdsale is Ownable {

    using SafeMath for uint256;

    // Public structure of crowdsale's stages.
    struct Stage {
        uint256 hardcap;
        uint256 price;
        uint256 invested;
        uint256 closed;
    }

    Stage[] public stages;


    /**
     * @dev Function to get current stage number.
     * 
     * @return A uint256 specifing the currnet stage number.
     */
    function getCurrentStage() public constant returns(uint256) {
        for(uint256 i=0; i < stages.length; i++) {
            if(stages[i].closed == 0) {
                return i;
            }
        }
        revert();
    }


    /**
     * @dev Function add the stage to the crowdsale.
     *
     * @param _hardcap The hardcap of the stage.
     * @param _price The amount of tokens you will receive per 1 ETH for this stage.
     */
    function addStage(uint256 _hardcap, uint256 _price) public onlyOwner {
        require(_hardcap > 0 && _price > 0);
        Stage memory stage = Stage(_hardcap.mul(1 ether), _price, 0, 0);
        stages.push(stage);
    }
}

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



/**
 * @title Puls crowdsale.
 * @dev Contract to deploy into blockchain.
 */
contract PULSCrowdsale is Crowdsale {

	/**
     * @dev The PULS Crowdsale constructor initialize Crowdsale smart contracts.
     *
     * @param _startTime The start time of the crowdsale.
     * @param _endTime The end time of the crowdsale.
     * @param _wallet The address of multisig lawyers address.
     */
    function PULSCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet) Crowdsale(_startTime, _endTime, _wallet) {

    }
}