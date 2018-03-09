pragma solidity ^0.4.15;

import './Ownable.sol';
import './SafeMath.sol';

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
        uint256 minInvestment;
        uint256 invested;
        uint256 closed;
    }

    Stage[] public stages;


    /**
     * @dev Function to get the current stage number.
     * 
     * @return A uint256 specifing the current stage number.
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
     * @dev Function to add the stage to the crowdsale.
     *
     * @param _hardcap The hardcap of the stage.
     * @param _price The amount of tokens you will receive per 1 ETH for this stage.
     */
    function addStage(uint256 _hardcap, uint256 _price, uint256 _minInvestment) onlyOwner public {
        require(_hardcap > 0 && _price > 0);
        Stage memory stage = Stage(_hardcap.mul(1 ether), _price, _minInvestment.mul(1 ether).div(10), 0, 0);
        stages.push(stage);
    }


    /**
     * @dev Function to close the stage manually.
     *
     * @param _stageNumber Stage number to close.
     */
    function closeStage(uint256 _stageNumber) onlyOwner public {
        require(stages[_stageNumber].closed == 0);
        if (_stageNumber != 0) require(stages[_stageNumber - 1].closed != 0);

        stages[_stageNumber].closed = now;
        stages[_stageNumber].invested = stages[_stageNumber].hardcap;

        if (_stageNumber + 1 <= stages.length - 1) {
            stages[_stageNumber + 1].invested = stages[_stageNumber].hardcap;
        }
    }
}