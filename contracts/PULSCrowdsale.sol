pragma solidity ^0.4.15;

import './Crowdsale.sol';

contract PULSCrowdsale is Crowdsale {
    function PULSCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) Crowdsale(_startTime, _endTime, _rate, _wallet) {

    }
}