pragma solidity ^0.4.15;

import './Incentives.sol';
import './ProviderRegistry.sol';

contract ProviderUnlockedIncentives is Incentives {

	mapping(address => mapping(uint => bool)) unlocked;
	ProviderRegistry providerRegistry;

	function ProviderUnlockedIncentives(address _reg) {
		providerRegistry = ProviderRegistry(_reg);
	}

	modifier onlyProvider() {
		require(providerRegistry.isProvider(msg.sender));
		_;
	}

	function unlock(address _target, uint _goal) onlyProvider {
		unlocked[_target][_goal] = true;
	}

	modifier isUnlocked(address _target, uint _goal) {
		require(unlocked[_target][_goal]);
		_;
	}

	function claim(address _target, uint _goal)
		isUnlocked(_target, _goal) {
		super.claim(_target, _goal);
	}
}
