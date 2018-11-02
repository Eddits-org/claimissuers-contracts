const Strings = artifacts.require('lib/Strings.sol');
const FCClaimRegistry = artifacts.require('FCClaimRegistry.sol');

module.exports = function(deployer) {
  deployer.link(Strings, FCClaimRegistry);
  deployer.deploy(FCClaimRegistry);
};