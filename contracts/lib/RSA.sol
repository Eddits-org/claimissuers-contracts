pragma solidity ^0.4.24;

import "./BytesLib.sol";

library RSA {

    function decipher(bytes memory modulus, bytes memory exponent, bytes memory data) internal returns(bytes) {
        bytes memory input = BytesLib.join(data,exponent,modulus);
        bytes memory result = new bytes(modulus.length);
        bool success;
        uint input_len = input.length;
        uint decipher_len = result.length;
        assembly {
          success := call(sub(gas, 2000), 0x0000000000000000000000000000000000000005, 0, add(input,0x20), input_len, add(result,0x20), decipher_len)
          switch success case 0 { invalid }
        }
        return result;
    }

}