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

contract BasicERC20Token {
	using SafeMath for uint256;

	uint256 public totalSupply;
	mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	
	function transfer(address _to, uint256 _value) public returns (bool) {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address
        require (balances[msg.sender] >= _value);          // Check if the sender has enough
        require (balances[_to] + _value > balances[_to]); // Check for overflows

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}

	function getTotalSupply() public constant returns (uint) {
        return totalSupply;
    }

	function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
		require (_from != 0x0);                       // Prevent transfer to 0x0 address
		require (_to != 0x0);                         // Prevent transfer to 0x0 address
        require (balances[_from] >= _value);          // Check if the sender has enough

		var _allowance = allowed[_from][msg.sender];
        require (_allowance > 0);					  // Check if allowed amount is greater then 0

		balances[_to] = balances[_to].add(_value);
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) returns (bool) {
		require (_spender != 0x0);                       // Prevent transfer to 0x0 address
		require (balances[msg.sender] >= _value);		 // Check if the allowencer has enough to allow 
		require ((_value == 0) || (allowed[msg.sender][_spender] == 0));

		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
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

	event Buy(address indexed buyer, uint256 amount);

	function PULSToken() public {
		totalSupply = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
		Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}

	function buy(address _buyer, uint256 _amount) returns (bool) { // or public??
		require (_buyer != 0x0);                       // Prevent transfer to 0x0 address
		require (totalSupply >= _amount);               // Check if suchTokens amount left

		totalSupply = totalSupply.sub(_amount);
		balances[_buyer] = balances[_buyer].add(_amount);
		Buy(_buyer, _amount);
		Transfer(address(this), _buyer, _amount);
		return true;
	}
}


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

contract PULSCrowdsale is Crowdsale {
    function PULSCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) Crowdsale(_startTime, _endTime, _rate, _wallet) {

    }
}