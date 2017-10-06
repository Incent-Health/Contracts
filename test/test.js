var Goals = artifacts.require("./Goals.sol");
var ProviderUnlockedIncentives = artifacts.require("./ProviderUnlockedIncentives.sol");
var IncentHealthProviders = artifacts.require("./IncentHealthProviders.sol");

contract('simple goal', function(accounts) {
  it("single provider adds, funds, signs off on goal, patient collects", function() {
    var patient = accounts[0];
    var provider = accounts[1];
    var goals;
    var providerUnlockedIncentives;
    var incentHealthProviders;
    var patBeforeBalance;

    return ProviderUnlockedIncentives.deployed().then((instance) => {
      providerUnlockedIncentives = instance;
      return Goals.deployed();
    }).then((instance) => {
      goals = instance;
      return IncentHealthProviders.deployed();
    }).then((instance) => {
      incentHealthProviders = instance;
      return goals.addGoal(patient, "quit smoking", {from: provider});
    }).then((_goal) => {
      return goals.addIncentive(patient, 0, providerUnlockedIncentives.address, {from: provider});
    }).then(() => {
     return providerUnlockedIncentives.fund(patient, 0, web3.eth.getBlock("latest").timestamp + 30*24*60*60,
	      {from: provider, value: web3.toWei(1, "ether")});
    }).then(() => {
      return incentHealthProviders.addProvider(provider);
    }).then(() => {
      return providerUnlockedIncentives.unlock(patient, 0, {from: provider});
    }).then(() => {
      patBeforeBalance = web3.eth.getBalance(patient).toNumber();
      return goals.claim(0, {from: patient, gasPrice: 0});
    }).then(() => {
      return assert.equal(patBeforeBalance + 1000000000000000000, web3.eth.getBalance(patient).toNumber());
    });
  });
});
