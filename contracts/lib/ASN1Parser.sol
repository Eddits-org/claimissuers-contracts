pragma solidity ^0.4.24;

import "./BytesLib.sol";

library ASN1Parser {

  struct Parser {
    uint offset;
    bytes data;
    uint fieldLen;
  }
  
  struct Certificate {
    string commonName;
    string countryName;
    string issuerCommonName;
    PublicKey key;
    bytes tbsCertificate;
    bytes signature;
  }

  struct PublicKey {
    bytes modulus;
    bytes exponent;
  }

  function forData(bytes _data) internal pure returns (Parser p) {
    p.offset = 0;
    p.data = _data;
    p.fieldLen = 0;
  }

  function readTag(Parser p) internal pure returns (uint8 tag) {
    tag = uint8(p.data[p.offset]);
    p.offset++;
    var (len,offset) = parseLength(p.data, p.offset);
    p.offset = offset;
    p.fieldLen = len;
  }

  function readBytes(Parser p) internal pure returns (bytes memory value) {
    value = BytesLib.slice(p.data, p.offset, p.fieldLen);
    p.offset += p.fieldLen;
  }

  function readInt(Parser p) internal pure returns (uint value) {
    value = parseInt(p.data, p.offset, p.fieldLen);
    p.offset += p.fieldLen;
  }

  function readString(Parser p) internal pure returns (string value) {
    bytes memory str = BytesLib.slice(p.data, p.offset, p.fieldLen);
    p.offset += p.fieldLen;
    value = string(str);
  }

  function skipValue(Parser p) internal pure {
    p.offset += p.fieldLen;
  }

  function readCertificate(ASN1Parser.Parser parser) internal pure returns (Certificate cert) {
    assert(readTag(parser) == 0x30);
    assert(readTag(parser) == 0x30);
    cert.tbsCertificate = BytesLib.slice(parser.data, parser.offset - 4, parser.fieldLen + 4); // TODO -4
    readTag(parser); // context-specific
    assert(readTag(parser) == 0x02);
    skipValue(parser);
    assert(readTag(parser) == 0x02);
    skipValue(parser);
    assert(readTag(parser) == 0x30); // sha256WithRSAEncryption
    skipValue(parser);
    assert(readTag(parser) == 0x30);
    cert.issuerCommonName = extractStringFromSequence(parser, hex"550403"); // 0x550403 => Common Name OID
    assert(readTag(parser) == 0x30);
    skipValue(parser);
    assert(readTag(parser) == 0x30);
    uint seqLen = parser.fieldLen;
    uint seqStartOffset = parser.offset;
    cert.countryName = extractStringFromSequence(parser, hex"550406");  // 0x550406 => Country Name OID
    parser.fieldLen = seqLen;
    parser.offset = seqStartOffset;
    cert.commonName = extractStringFromSequence(parser, hex"550403");  // 0x550403 => Common Name OID
    assert(readTag(parser) == 0x30);
    assert(readTag(parser) == 0x30);
    skipValue(parser);
    assert(readTag(parser) == 0x03);
    parser.offset ++;
    assert(readTag(parser) == 0x30);
    assert(readTag(parser) == 0x02);
    cert.key.modulus = readBytes(parser);
    assert(readTag(parser) == 0x02);
    cert.key.exponent = readBytes(parser);
    assert(readTag(parser) == 0xa3);
    skipValue(parser);
    assert(readTag(parser) == 0x30);
    skipValue(parser);
    assert(readTag(parser) == 0x03);
    cert.signature = readBytes(parser);
  }

  function extractStringFromSequence(Parser p, bytes oid) private pure returns (string) {
    uint seqLen = p.fieldLen;
    uint seqStartOffset = p.offset;
    while (p.offset < seqStartOffset + seqLen) {
      assert(readTag(p) == 0x31); // SET
      assert(readTag(p) == 0x30); // SEQUENCE
      assert(readTag(p) == 0x06); // OID
      if (BytesLib.compare(readBytes(p),oid)) {
        uint8 tag = readTag(p);
        if (tag == 0x13 || tag == 0x0c) { // PrintableString OR UTF8String
          string memory result = readString(p);
          p.offset = seqStartOffset + seqLen;
          return result;
        }
      } else {
        readTag(p);
        skipValue(p);
      }
    }
    p.offset = seqStartOffset + seqLen;
    return "";
  }

  function parseLength(bytes _value, uint offset) private pure returns (uint, uint) {
		if (_value[offset] >= 0x80) {
			uint nbBytes = uint(_value[offset] & 0x7f);
			uint size = parseInt(_value, offset+1, nbBytes);
			return (size,offset+1+nbBytes);
		} else {
			return (uint(_value[offset]),offset+1);
		}
	}

  function parseInt(bytes _value, uint offset, uint length) private pure returns (uint) {
    uint256 result = uint(_value[offset + (length-1)]);
    for (uint i = 1; i < length; i++) {
      result += (uint(_value[offset + (length-i-1)]) * 16**uint(i+1));
    }
    return result;
  }

}