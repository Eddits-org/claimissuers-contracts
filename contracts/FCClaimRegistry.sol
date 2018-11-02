pragma solidity ^0.4.24;

import "./dependencies/Mortal.sol";
import "./dependencies/Owned.sol";
import "./dependencies/ERC735.sol";

import "./lib/Strings.sol";

contract FCClaimRegistry is Mortal {

    using strings for *;

    event ClaimError(string cause);

    struct Claim {
        bool active;
        string sub;
    }

    address public jwtSigner;
    mapping(address => Claim) claims;

    uint public cost;

    function setCost(uint _value) public onlyowner {
        cost = _value;
    }

    function setJwtSigner(address _signer) public onlyowner {
        jwtSigner = _signer;
    }

    function get(address _who) public view returns(
        bool active,
        string sub) {
        active = claims[_who].active;
        sub = claims[_who].sub;
    }

    function certify(string _jwt, uint8 _v, bytes32 _r, bytes32 _s) public payable {
        require(msg.value >= cost, "Insufficient value");

        // Validate JWT signature
        bytes32 jwtHash = keccak256(abi.encodePacked((_jwt)));
        if(ecrecover(jwtHash, _v, _r, _s) == jwtSigner) {
            // Extract nonce from JWT and parse as address
            strings.slice memory jwt = _jwt.toSlice();        
            string memory nonce = extractAttribute(jwt.copy(), "nonce".toSlice());
            address jwtAddress = parseAddr(nonce);

            // Check that msg.sender is the same address that the nonce in JWT
            if(jwtAddress == msg.sender) {
                // Claim is valid: save data
                claims[msg.sender].active = true;
                claims[msg.sender].sub = extractAttribute(jwt.copy(), "sub".toSlice());

                // Build the calldata for the claim
                bytes4 method = bytes4(keccak256("get(address)"));
                bytes32 addr = bytes32(msg.sender);
                bytes memory calldata = new bytes(36);
                for (uint256 i = 0; i < 4; i++) {
                    calldata[i] = method[i];
                }
                for (uint256 j = 4; j < 32+4; j++) {
                    calldata[j] = addr[j - 4];
                }
                // Add claim to identity
                ERC735 claimHolder = ERC735(msg.sender);
                claimHolder.addClaim(
                    1,
                    3,
                    this,
                    new bytes(0),
                    calldata,
                    "https://eddits.io/verify"
                );
            }
            else
                emit ClaimError("Nonce in JWT is not transaction signer");
        }
        else
            emit ClaimError("Invalid JWT signature");
    }

    function extractAttribute(strings.slice jwt, strings.slice attribute) internal pure returns(string) {
        strings.slice memory needle = "\"".toSlice().concat(attribute).toSlice().concat("\":\"".toSlice()).toSlice();
        jwt.find(needle).beyond(needle);
        needle = "\"".toSlice();
        jwt.until(jwt.copy().find(needle).beyond(needle)).toString();
        jwt._len--;
        return jwt.toString();
    }

    function parseAddr(string _a) internal pure returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }

}