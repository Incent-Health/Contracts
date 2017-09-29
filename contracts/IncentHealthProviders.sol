pragma solidity ^0.4.15;

import './ProviderRegistry.sol';

contract IncentHealthProviders is ProviderRegistry {

	mapping(address => bool) providerIsInNetwork;

	function addProvider(address a) public {
		providerIsInNetwork[a] = true;
	}

	function isProvider(address a) public constant returns (bool) {
		return providerIsInNetwork[a];
	}
}
