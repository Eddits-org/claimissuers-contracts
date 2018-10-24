pragma solidity ^0.4.24;

import "./dependencies/Owned.sol";
import "./lib/ASN1Parser.sol";

contract AuthorityBased is Owned {

    struct CA {
        ASN1Parser.PublicKey key;
        string CN;
        bool active;
    }

    mapping(bytes32 => CA) internal authorities;  

    function addAuthority(string _commonName, bytes _modulus, bytes _exponent) public onlyowner {
        bytes32 hashCN = sha256(abi.encodePacked(_commonName));
        authorities[hashCN].key = ASN1Parser.PublicKey(_modulus, _exponent);
        authorities[hashCN].CN = _commonName;
        authorities[hashCN].active = true;
    }

    function removeAuthority(string _commonName) public onlyowner {
        delete authorities[sha256(abi.encodePacked(_commonName))];
    }

    function trustedAuthority(string _commonName) public view returns(bool) {
        return authorities[sha256(abi.encodePacked(_commonName))].active;
    }

}