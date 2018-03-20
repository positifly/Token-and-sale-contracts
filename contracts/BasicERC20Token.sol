pragma solidity ^0.4.21;

import './SafeMath.sol';
import './Ownable.sol';

/**
 * @title BasicERC20 token.
 * @dev Basic version of ERC20 token with allowances.
 */
contract BasicERC20Token is Ownable {
    using SafeMath for uint256;

    uint256 public totalSupply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);


    /**
     * @dev Function to check the amount of tokens for address.
     *
     * @param _owner Address which owns the tokens.
     * 
     * @return A uint256 specifing the amount of tokens still available to the owner.
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    /**
     * @dev Function to check the total supply of tokens.
     *
     * @return The uint256 specifing the amount of tokens which are held by the contract.
     */
    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }


    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     *
     * @param _owner Address which owns the funds.
     * @param _spender Address which will spend the funds.
     *
     * @return The uint256 specifing the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    /**
     * @dev Internal function to transfer tokens.
     *
     * @param _from Address of the sender.
     * @param _to Address of the recipient.
     * @param _amount Amount to send.
     *
     * @return True if the operation was successful.
     */
    function _transfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        require (_from != 0x0);                               // Prevent transfer to 0x0 address
        require (_to != 0x0);                               // Prevent transfer to 0x0 address
        require (balances[_from] >= _amount);          // Check if the sender has enough tokens
        require (balances[_to] + _amount > balances[_to]);  // Check for overflows

        uint256 length;
        assembly {
            length := extcodesize(_to)
        }
        require (length == 0);

        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(_from, _to, _amount);
        
        return true;
    }


    /**
     * @dev Function to transfer tokens.
     *
     * @param _to Address of the recipient.
     * @param _amount Amount to send.
     *
     * @return True if the operation was successful.
     */
    function transfer(address _to, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _to, _amount);

        return true;
    }


    /**
     * @dev Transfer tokens from other address.
     *
     * @param _from Address of the sender.
     * @param _to Address of the recipient.
     * @param _amount Amount to send.
     *
     * @return True if the operation was successful.
     */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require (allowed[_from][msg.sender] >= _amount);          // Check if the sender has enough

        _transfer(_from, _to, _amount);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        return true;
    }


    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * 
     * @param _spender Address which will spend the funds.
     * @param _amount Amount of tokens to be spent.
     *
     * @return True if the operation was successful.
     */
    function approve(address _spender, uint256 _amount) public returns (bool) {
        require (_spender != 0x0);                       // Prevent transfer to 0x0 address
        require (_amount >= 0);
        require (balances[msg.sender] >= _amount);       // Check if the msg.sender has enough to allow 

        if (_amount == 0) allowed[msg.sender][_spender] = _amount;
        else allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_amount);

        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
}