var Dai = artifacts.require("DSToken");

module.exports = function(deployer) {
  deployer.deploy(Dai,'0x4441490000000000000000000000000000000000000000000000000000000000');
};


