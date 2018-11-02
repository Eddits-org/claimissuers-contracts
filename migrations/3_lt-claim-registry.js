const Base64Lib = artifacts.require('lib/Base64Lib.sol');
const LTClaimRegistry = artifacts.require('LTClaimRegistry.sol');

module.exports = function(deployer) {
  deployer.link(Base64Lib, LTClaimRegistry);
  deployer.deploy(LTClaimRegistry);
};