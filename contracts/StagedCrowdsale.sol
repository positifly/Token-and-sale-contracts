pragma solidity ^0.4.15;

import './Ownable.sol';
import './SafeMath.sol';

contract StagedCrowdsale is Ownable {

    using SafeMath for uint;

    struct Stage {
        uint hardcap;
        uint price;
        uint invested;
        uint closed;
    }

    Stage[] public stages;

    function getCurrentStage() public constant returns(uint) {
        for(uint i=0; i < stages.length; i++) {
            if(stages[i].closed == 0) {
                return i;
            }
        }
        revert();
    }

    function addStage(uint hardcap, uint price) public onlyOwner {
        require(hardcap > 0 && price > 0);
        Stage memory stage = Stage(hardcap.mul(1 ether), price, 0, 0);
        stages.push(stage);
    }
}