pragma solidity ^0.4.15;

import './Ownable.sol';
import './SafeMath.sol';

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