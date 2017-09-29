pragma solidity ^0.4.15;

import './SafeMath.sol';
import './Incentives.sol';

contract Goals {

	struct goal {
		string description;
		mapping(uint => Incentives) incentives;
		uint incentiveLength;
	}

	mapping(address => goal[]) private goals;

	function addGoal(address _to, string _description) public {
		goals[_to].push(goal(_description, 0));
	}

	function addIncentive(address _to, uint _goal, Incentives _incentive) public {
		goal g = goals[_to][_goal];

		g.incentives[g.incentiveLength] = _incentive;
		SafeMath.add(g.incentiveLength, 1);
	}

	function claim(uint _goal) {
		mapping(uint => Incentives) incentives = goals[msg.sender][_goal].incentives;
		for(uint i=0; i<goals[msg.sender][_goal].incentiveLength; i++) {
			incentives[i].claim(msg.sender, _goal);
		}
	}
}
