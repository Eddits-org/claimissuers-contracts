pragma solidity ^0.4.24;

library Base64Lib {

  function decode32(string _value) pure public returns(bytes32 out) {
    bytes memory _out = decode(_value, 32);
    assembly {
      out := mload(add(_out,32))
    }
  }

  function decode(string _value, uint outLen) pure private returns(bytes) {
    bytes memory _out = new bytes(outLen);
    bytes memory str = bytes(_value);
    uint outOffset = 0;
    for (uint i = 0; i < str.length; i += 4) {
      uint buff = 0;
      buff = buff << 6 | value(str[i]);
      buff = buff << 6 | value(str[i+1]);
      buff = buff << 6 | value(str[i+2]);
      buff = buff << 6 | value(str[i+3]);
      if (outOffset < 32) {
        _out[outOffset++] = bytes1(uint8((buff >> 16) & 0xff));
      }
      if (outOffset < 32) {
        _out[outOffset++] = bytes1(uint8((buff >> 8) & 0xff));
      }
      if (outOffset < 32) {
        _out[outOffset++] = bytes1(uint8(buff & 0xff));
      }
    }
    return _out;
  }

  function value(bytes1 _in) pure private returns(uint8 out) {
    uint8 v = uint8(_in);
    if (v >= 0x30 && v <= 0x39)
      return v + 0x4;
    if (v >= 0x41 && v <= 0x5a)
      return v - 0x41;
    if (v >= 0x61 && v <= 0x7a)
      return v - 0x47;
    if (v == 0x2b)
      return 0x3e;
    if (v == 0x2f)
      return 0x3f;
    return 0;
  }
  
}