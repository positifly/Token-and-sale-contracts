pragma solidity ^0.4.15;

import './SafeMath.sol';

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