pragma solidity ^0.4.24;

import "./dependencies/Owned.sol";
import "./dependencies/Mortal.sol";
import "./dependencies/ERC735.sol";

import "./lib/ASN1Parser.sol";
import "./lib/RSA.sol";
import "./lib/BytesLib.sol";
import "./lib/Base64Lib.sol";

import "./AuthorityBased.sol";

contract LTClaimRegistry is Mortal,AuthorityBased {

    using ASN1Parser for ASN1Parser.Parser;

    struct Claim {
        bool active;
        string cn;
        string country;
        string issuer_cn;
        bytes modulus;
        bytes exponent;
    }

    mapping(address => Claim) private claims;

    uint public cost;

    // --- public functions

    function certify(string _signInfo, bytes _signature, string _manifest, bytes _certificate) payable public {
        require(msg.value >= cost, "Insufficient value");
        ASN1Parser.Parser memory parser = ASN1Parser.forData(_certificate);
        ASN1Parser.Certificate memory cert = parser.readCertificate();
        CA memory ca = authorities[sha256(abi.encodePacked(cert.issuerCommonName))];
        if(ca.active && verifyCertificateSignature(cert.signature, cert.tbsCertificate, ca.key)) {
            if(verifySignInfoSignature(_signInfo, _signature, cert.key.modulus, cert.key.exponent)) {
                if(verifyManifestHash(_signInfo, _manifest)){
                    if(verifyAddressHash(_manifest)) {
                        claims[msg.sender].active = true;
                        claims[msg.sender].cn = cert.commonName;
                        claims[msg.sender].country = cert.countryName;
                        claims[msg.sender].issuer_cn = cert.issuerCommonName;
                        claims[msg.sender].modulus = cert.key.modulus;
                        claims[msg.sender].exponent = cert.key.exponent;

                        bytes4 method = bytes4(keccak256("get(address)"));
                        bytes32 addr = bytes32(msg.sender);
                        bytes memory calldata = new bytes(36);
                        for (uint256 i = 0; i < 4; i++) {
                            calldata[i] = method[i];
                        }
                        for (uint256 j = 4; j < 32+4; j++) {
                            calldata[j] = addr[j - 4];
                        }
                        ERC735 claimHolder = ERC735(msg.sender);
                        claimHolder.addClaim(
                            1 /* _claimType = Biometric data */, 
                            3 /* _scheme = contract verification */,
                            this,
                            new bytes(0),
                            calldata,
                            "https://eddits.io/verify"
                        );
                    }
            }
        }
        }    
    }

    function setCost(uint _value) public onlyowner {
        cost = _value;
    }

    function drain() public onlyowner {
        msg.sender.transfer(address(this).balance);
    }

    function get(address _who) public view returns(
        bool active,
        string cn,
        string country,
        string issuer_cn,
        bytes modulus,
        bytes exponent) {
        active = claims[_who].active;
        cn = claims[_who].cn;
        country = claims[_who].country;
        issuer_cn = claims[_who].issuer_cn;
        modulus = claims[_who].modulus;
        exponent = claims[_who].exponent;
    }

    // --- private functions

    function verifySignInfoSignature(string _signInfo, bytes _signature, bytes _modulus, bytes _exponent) private returns(bool verified) {
        verified = false;
        bytes memory raw = RSA.decipher(_modulus, _exponent, _signature);
        bytes memory signature = BytesLib.slice(raw, 206, raw.length - 206);
        ASN1Parser.Parser memory parser = ASN1Parser.forData(signature);
        assert(parser.readTag() == 0x30);
        assert(parser.readTag() == 0x30);
        parser.skipValue();
        assert(parser.readTag() == 0x04);
        bytes memory signed = parser.readBytes();
        bytes32 signedHash;
        assembly {
            signedHash := mload(add(signed,32))
        }
        verified = signedHash == sha256(abi.encodePacked(_signInfo));
    }

    function verifyManifestHash(string _signInfo, string _manifest) private pure returns (bool verified) {
        verified = false;
        bytes memory manifestValue = extractFirstTagContent(
            bytes(_signInfo),
            "<dsig:Reference Type=\"http://www.w3.org/2000/09/xmldsig#Manifest\"","</dsig:Reference>"
        );
        bytes memory digestValue = extractFirstTagContent(manifestValue,"<dsig:DigestValue","</dsig:DigestValue>");
        bytes32 signedHash = Base64Lib.decode32(string(digestValue));
        verified = signedHash == sha256(abi.encodePacked(_manifest));
    }

    function verifyCertificateSignature(bytes certSignature, bytes tbs, ASN1Parser.PublicKey memory ca) private returns(bool verified) {
        verified = false;
        // Decrypt certificate signature
        bytes memory raw = RSA.decipher(ca.modulus, ca.exponent, certSignature);
        // TODO: Remove padding
        bytes memory signature = BytesLib.slice(raw, 461, raw.length - 461);
        ASN1Parser.Parser memory parser = ASN1Parser.forData(signature);
        assert(parser.readTag() == 0x30);
        assert(parser.readTag() == 0x30);
        parser.skipValue();
        assert(parser.readTag() == 0x04);
        bytes memory signed = parser.readBytes();
        bytes32 signedHash;
        assembly {
            signedHash := mload(add(signed,32))
        }
        // Verify that signed hash match the sha256 sum of tbs
        verified = signedHash == sha256(abi.encodePacked(tbs));
    }

    function verifyAddressHash(string _manifest) private view returns (bool verified) {
        verified = false;
        bytes memory addrDigestValue = extractFirstTagContent(bytes(_manifest), "<dsig:DigestValue", "</dsig:DigestValue>");
        bytes32 signedHash = Base64Lib.decode32(string(addrDigestValue));
        verified = signedHash == sha256(abi.encodePacked(msg.sender));
    }

    function extractFirstTagContent(bytes _in, string openTag, string closeTag) private pure returns (bytes) {
        uint start_offset = indexOf(_in, bytes(openTag), 0);
        for (uint i = start_offset; i < _in.length; i++) {
            if (_in[i] == ">") {
                start_offset = i + 1;
                break;
            }
        }
        uint end_offset = indexOf(_in, bytes(closeTag), start_offset);
        bytes memory value = BytesLib.slice(_in, start_offset, end_offset - start_offset);
        return value;
    }

    function indexOf(bytes _in, bytes _search, uint from) private pure returns (uint) {
        assert(_in.length > 0 && _search.length > 0 && _search.length < _in.length);
        uint subindex = 0;
        for (uint i = from; i < _in.length; i ++) {
            if (_in[i] == _search[0]) {
                subindex = 1;
                while(subindex < _search.length && (i + subindex) < _in.length && _in[i + subindex] == _search[subindex]) {
                    subindex++;
                }
                if(subindex == _search.length)
                return i;
            }
        }
    }

}