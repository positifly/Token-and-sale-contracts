pragma solidity ^0.4.15;

import './SafeMath.sol';
import './Ownable.sol';


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