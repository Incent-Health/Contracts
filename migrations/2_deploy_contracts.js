var Goals = artifacts.require("./Goals.sol");
var IncentHealthProviders = artifacts.require("./IncentHealthProviders.sol");
var ProviderUnlockedIncentives = artifacts.require("./ProviderUnlockedIncentives.sol");

module.exports = function(deployer) {
	
  deployer.deploy(Goals)
  deployer.deploy(IncentHealthProviders).then(function() {
	deployer.deploy(ProviderUnlockedIncentives, IncentHealthProviders.address);
  });

};
