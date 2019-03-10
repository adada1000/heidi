var RewardTokenFactory = artifacts.require("RewardTokenFactory");

module.exports = function(deployer) {
  deployer.deploy(RewardTokenFactory);
};


