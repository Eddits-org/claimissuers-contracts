const ASN1Parser = artifacts.require('lib/ASN1Parser.sol');
const BytesLib = artifacts.require('lib/BytesLib.sol');
const RSA = artifacts.require('lib/RSA.sol');
const Base64Lib = artifacts.require('lib/Base64Lib.sol');

module.exports = (deployer) => {
  deployer.deploy(BytesLib);
  deployer.deploy(Base64Lib);
  deployer.deploy(ASN1Parser);
  deployer.deploy(RSA);
};