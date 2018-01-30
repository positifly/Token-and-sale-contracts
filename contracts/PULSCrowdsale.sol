pragma solidity ^0.4.15;

import './Crowdsale.sol';

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