pragma solidity ^0.4.15;

import './SafeMath.sol';
import './Ownable.sol';

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