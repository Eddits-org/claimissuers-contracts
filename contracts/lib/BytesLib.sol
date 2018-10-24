pragma solidity ^0.4.24;

library BytesLib {

  function slice(bytes input, uint index, uint size) internal pure returns (bytes) {
    bytes memory result = new bytes(size);
    uint rindex;
    uint oindex = 0;
    if (size == 0 || index + size >= input.length) {
      rindex = input.length;
    } else {
      rindex = index + size;
    }
    for (uint i=index; i< rindex; i++) {
      result[oindex] = input[i];
      oindex++;
    }
    return result;
  }

  function compare(bytes a, bytes b) internal pure returns (bool) {
      uint minLength = a.length;
      if (b.length < minLength) minLength = b.length;
      for (uint i = 0; i < minLength; i ++)
          if (a[i] < b[i])
              return false;
          else if (a[i] > b[i])
              return false;
      if (a.length < b.length)
          return false;
      else if (a.length > b.length)
          return false;
      else
          return true;
  }

  function memcpy(uint dest, uint src, uint len) internal pure {
      for(; len >= 32; len -= 32) {
          assembly {
              mstore(dest, mload(src))
          }
          dest += 32;
          src += 32;
      }
      uint mask = 256 ** (32 - len) - 1;
      assembly {
          let srcpart := and(mload(src), not(mask))
          let destpart := and(mload(dest), mask)
          mstore(dest, or(destpart, srcpart))
      }
  }

  function join(bytes s, bytes e, bytes m) internal pure returns (bytes) {
      uint input_len = 0x60+s.length+e.length+m.length;
      
      uint s_len = s.length;
      uint e_len = e.length;
      uint m_len = m.length;
      uint s_ptr;
      uint e_ptr;
      uint m_ptr;
      uint input_ptr;
      
      bytes memory input = new bytes(input_len);
      assembly {
          s_ptr := add(s,0x20)
          e_ptr := add(e,0x20)
          m_ptr := add(m,0x20)
          mstore(add(input,0x20),s_len)
          mstore(add(input,0x40),e_len)
          mstore(add(input,0x60),m_len)
          input_ptr := add(input,0x20)
      }
      memcpy(input_ptr+0x60,s_ptr,s.length);        
      memcpy(input_ptr+0x60+s.length,e_ptr,e.length);        
      memcpy(input_ptr+0x60+s.length+e.length,m_ptr,m.length);

      return input;
  }

}