const ASN1Parser = artifacts.require('lib/ASN1Parser.sol');
const BytesLib = artifacts.require('lib/BytesLib.sol');
const RSA = artifacts.require('lib/RSA.sol');
const Base64Lib = artifacts.require('lib/Base64Lib.sol');
const Strings = artifacts.require('lib/Strings.sol');

module.exports = function(deployer) {
  deployer.deploy(BytesLib);
  deployer.deploy(Base64Lib);
  deployer.deploy(ASN1Parser);
  deployer.deploy(RSA);
  deployer.deploy(Strings);
};