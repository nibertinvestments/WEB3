// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title EncodingUtils - Advanced Data Encoding and Serialization Library
 * @dev Comprehensive utilities for data encoding, decoding, and serialization
 * 
 * FEATURES:
 * - Base64 encoding and decoding
 * - Protocol buffer-style variable length encoding
 * - JSON-like object serialization
 * - Binary data compression and expansion
 * - Multi-format data conversion utilities
 * - Efficient memory management for large datasets
 * 
 * USE CASES:
 * 1. Off-chain data communication formatting
 * 2. Compact storage of complex data structures
 * 3. Cross-chain message formatting
 * 4. API data serialization for external integrations
 * 5. Efficient encoding for gas optimization
 * 6. Data interchange between different protocols
 * 
 * @author Nibert Investments LLC
 * @notice Basic Level - Essential encoding and serialization tools
 */

library EncodingUtils {
    // Error definitions
    error InvalidBase64();
    error InvalidVarint();
    error SerializationFailed();
    error DeserializationFailed();
    error UnsupportedFormat();
    error BufferOverflow();
    
    // Events
    event DataEncoded(string indexed format, uint256 originalSize, uint256 encodedSize);
    event DataDecoded(string indexed format, uint256 decodedSize);
    event SerializationComplete(bytes32 indexed dataHash, uint256 objectCount);
    
    // Base64 character set
    string private constant BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    /**
     * @dev Encodes bytes to Base64 string
     * Use Case: Encoding binary data for text-based protocols
     */
    function encodeBase64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        bytes memory result = new bytes(encodedLen);
        bytes memory chars = bytes(BASE64_CHARS);
        
        uint256 i = 0;
        uint256 j = 0;
        
        while (i < data.length) {
            uint256 a = uint256(uint8(data[i++]));
            uint256 b = i < data.length ? uint256(uint8(data[i++])) : 0;
            uint256 c = i < data.length ? uint256(uint8(data[i++])) : 0;
            
            uint256 bitmap = (a << 16) | (b << 8) | c;
            
            result[j++] = chars[(bitmap >> 18) & 63];
            result[j++] = chars[(bitmap >> 12) & 63];
            result[j++] = chars[(bitmap >> 6) & 63];
            result[j++] = chars[bitmap & 63];
        }
        
        // Add padding
        if (data.length % 3 == 1) {
            result[encodedLen - 1] = "=";
            result[encodedLen - 2] = "=";
        } else if (data.length % 3 == 2) {
            result[encodedLen - 1] = "=";
        }
        
        return string(result);
    }
    
    /**
     * @dev Decodes Base64 string to bytes
     * Use Case: Parsing Base64-encoded data from external sources
     */
    function decodeBase64(string memory encoded) internal pure returns (bytes memory) {
        bytes memory data = bytes(encoded);
        
        // Remove padding and calculate length
        uint256 paddingCount = 0;
        if (data.length > 0 && data[data.length - 1] == "=") paddingCount++;
        if (data.length > 1 && data[data.length - 2] == "=") paddingCount++;
        
        uint256 decodedLen = (data.length * 3) / 4 - paddingCount;
        bytes memory result = new bytes(decodedLen);
        
        uint256 i = 0;
        uint256 j = 0;
        
        while (i < data.length - paddingCount) {
            uint256 a = base64CharToValue(data[i++]);
            uint256 b = base64CharToValue(data[i++]);
            uint256 c = i < data.length ? base64CharToValue(data[i++]) : 0;
            uint256 d = i < data.length ? base64CharToValue(data[i++]) : 0;
            
            uint256 bitmap = (a << 18) | (b << 12) | (c << 6) | d;
            
            if (j < decodedLen) result[j++] = bytes1(uint8(bitmap >> 16));
            if (j < decodedLen) result[j++] = bytes1(uint8(bitmap >> 8));
            if (j < decodedLen) result[j++] = bytes1(uint8(bitmap));
        }
        
        return result;
    }
    
    /**
     * @dev Converts Base64 character to value
     * Use Case: Helper for Base64 decoding
     */
    function base64CharToValue(bytes1 char) internal pure returns (uint256) {
        if (char >= "A" && char <= "Z") return uint8(char) - 65; // ASCII 'A' = 65
        if (char >= "a" && char <= "z") return uint8(char) - 71; // ASCII 'a' = 97, so 97 - 26 = 71
        if (char >= "0" && char <= "9") return uint8(char) + 4;  // ASCII '0' = 48, so 48 + 4 = 52
        if (char == "+") return 62;
        if (char == "/") return 63;
        revert InvalidBase64();
    }
    
    /**
     * @dev Encodes unsigned integer as variable-length integer (varint)
     * Use Case: Compact integer encoding for protocol buffers
     */
    function encodeVarint(uint256 value) internal pure returns (bytes memory) {
        if (value == 0) {
            return abi.encodePacked(uint8(0));
        }
        
        bytes memory result = new bytes(10); // Max 10 bytes for uint64
        uint256 length = 0;
        
        while (value > 0) {
            uint8 byte_val = uint8(value & 0x7F);
            value >>= 7;
            
            if (value != 0) {
                byte_val |= 0x80; // Set continuation bit
            }
            
            result[length++] = bytes1(byte_val);
        }
        
        // Resize to actual length
        bytes memory encoded = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            encoded[i] = result[i];
        }
        
        return encoded;
    }
    
    /**
     * @dev Decodes variable-length integer (varint)
     * Use Case: Parsing compact integer encoding
     */
    function decodeVarint(bytes memory data, uint256 offset) internal pure returns (uint256 value, uint256 newOffset) {
        value = 0;
        uint256 shift = 0;
        newOffset = offset;
        
        while (newOffset < data.length) {
            uint8 byte_val = uint8(data[newOffset]);
            newOffset++;
            
            value |= uint256(byte_val & 0x7F) << shift;
            
            if ((byte_val & 0x80) == 0) {
                break;
            }
            
            shift += 7;
            require(shift < 64, "EncodingUtils: varint overflow");
        }
    }
    
    /**
     * @dev Serializes struct-like data into compact format
     * Use Case: Efficient storage of complex data structures
     */
    function serializeObject(
        bytes32[] memory keys,
        bytes[] memory values
    ) internal pure returns (bytes memory) {
        require(keys.length == values.length, "EncodingUtils: length mismatch");
        
        // Calculate total size needed
        uint256 totalSize = 4; // Number of fields
        for (uint256 i = 0; i < keys.length; i++) {
            totalSize += 32; // Key size
            totalSize += 4;  // Value length
            totalSize += values[i].length; // Value data
        }
        
        bytes memory serialized = new bytes(totalSize);
        uint256 offset = 0;
        
        // Write number of fields
        writeUint32(serialized, offset, keys.length);
        offset += 4;
        
        // Write key-value pairs
        for (uint256 i = 0; i < keys.length; i++) {
            // Write key
            writeBytes32(serialized, offset, keys[i]);
            offset += 32;
            
            // Write value length
            writeUint32(serialized, offset, values[i].length);
            offset += 4;
            
            // Write value data
            for (uint256 j = 0; j < values[i].length; j++) {
                serialized[offset + j] = values[i][j];
            }
            offset += values[i].length;
        }
        
        return serialized;
    }
    
    /**
     * @dev Deserializes object from compact format
     * Use Case: Retrieving complex data structures from storage
     */
    function deserializeObject(bytes memory data) internal pure returns (
        bytes32[] memory keys,
        bytes[] memory values
    ) {
        require(data.length >= 4, "EncodingUtils: insufficient data");
        
        uint256 offset = 0;
        uint256 fieldCount = readUint32(data, offset);
        offset += 4;
        
        keys = new bytes32[](fieldCount);
        values = new bytes[](fieldCount);
        
        for (uint256 i = 0; i < fieldCount; i++) {
            require(offset + 36 <= data.length, "EncodingUtils: truncated data");
            
            // Read key
            keys[i] = readBytes32(data, offset);
            offset += 32;
            
            // Read value length
            uint256 valueLength = readUint32(data, offset);
            offset += 4;
            
            require(offset + valueLength <= data.length, "EncodingUtils: truncated value");
            
            // Read value data
            values[i] = new bytes(valueLength);
            for (uint256 j = 0; j < valueLength; j++) {
                values[i][j] = data[offset + j];
            }
            offset += valueLength;
        }
    }
    
    /**
     * @dev Writes uint32 to bytes array at offset
     * Use Case: Binary data serialization helper
     */
    function writeUint32(bytes memory data, uint256 offset, uint256 value) internal pure {
        require(offset + 4 <= data.length, "EncodingUtils: write out of bounds");
        
        data[offset] = bytes1(uint8(value >> 24));
        data[offset + 1] = bytes1(uint8(value >> 16));
        data[offset + 2] = bytes1(uint8(value >> 8));
        data[offset + 3] = bytes1(uint8(value));
    }
    
    /**
     * @dev Reads uint32 from bytes array at offset
     * Use Case: Binary data deserialization helper
     */
    function readUint32(bytes memory data, uint256 offset) internal pure returns (uint256) {
        require(offset + 4 <= data.length, "EncodingUtils: read out of bounds");
        
        return (uint256(uint8(data[offset])) << 24) |
               (uint256(uint8(data[offset + 1])) << 16) |
               (uint256(uint8(data[offset + 2])) << 8) |
               uint256(uint8(data[offset + 3]));
    }
    
    /**
     * @dev Writes bytes32 to bytes array at offset
     * Use Case: Binary data serialization helper
     */
    function writeBytes32(bytes memory data, uint256 offset, bytes32 value) internal pure {
        require(offset + 32 <= data.length, "EncodingUtils: write out of bounds");
        
        assembly {
            mstore(add(add(data, 32), offset), value)
        }
    }
    
    /**
     * @dev Reads bytes32 from bytes array at offset
     * Use Case: Binary data deserialization helper
     */
    function readBytes32(bytes memory data, uint256 offset) internal pure returns (bytes32 result) {
        require(offset + 32 <= data.length, "EncodingUtils: read out of bounds");
        
        assembly {
            result := mload(add(add(data, 32), offset))
        }
    }
    
    /**
     * @dev Encodes array of addresses compactly
     * Use Case: Efficient storage of address lists
     */
    function encodeAddressArray(address[] memory addresses) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(4 + addresses.length * 20);
        uint256 offset = 0;
        
        // Write array length
        writeUint32(encoded, offset, addresses.length);
        offset += 4;
        
        // Write addresses
        for (uint256 i = 0; i < addresses.length; i++) {
            bytes20 addr = bytes20(addresses[i]);
            for (uint256 j = 0; j < 20; j++) {
                encoded[offset + j] = addr[j];
            }
            offset += 20;
        }
        
        return encoded;
    }
    
    /**
     * @dev Decodes array of addresses
     * Use Case: Retrieving address lists from compact storage
     */
    function decodeAddressArray(bytes memory data) internal pure returns (address[] memory) {
        require(data.length >= 4, "EncodingUtils: insufficient data");
        
        uint256 length = readUint32(data, 0);
        require(data.length == 4 + length * 20, "EncodingUtils: invalid address array");
        
        address[] memory addresses = new address[](length);
        uint256 offset = 4;
        
        for (uint256 i = 0; i < length; i++) {
            bytes20 addr;
            for (uint256 j = 0; j < 20; j++) {
                addr |= bytes20(data[offset + j]) >> (j * 8);
            }
            addresses[i] = address(addr);
            offset += 20;
        }
        
        return addresses;
    }
    
    /**
     * @dev Encodes string with length prefix
     * Use Case: Variable-length string serialization
     */
    function encodeString(string memory str) internal pure returns (bytes memory) {
        bytes memory strBytes = bytes(str);
        bytes memory encoded = new bytes(4 + strBytes.length);
        
        writeUint32(encoded, 0, strBytes.length);
        
        for (uint256 i = 0; i < strBytes.length; i++) {
            encoded[4 + i] = strBytes[i];
        }
        
        return encoded;
    }
    
    /**
     * @dev Decodes length-prefixed string
     * Use Case: Variable-length string deserialization
     */
    function decodeString(bytes memory data) internal pure returns (string memory) {
        require(data.length >= 4, "EncodingUtils: insufficient data");
        
        uint256 length = readUint32(data, 0);
        require(data.length >= 4 + length, "EncodingUtils: truncated string");
        
        bytes memory strBytes = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            strBytes[i] = data[4 + i];
        }
        
        return string(strBytes);
    }
    
    /**
     * @dev Compresses repeated data using run-length encoding
     * Use Case: Gas-efficient storage of repetitive data patterns
     */
    function runLengthEncode(bytes memory data) internal pure returns (bytes memory) {
        if (data.length == 0) return new bytes(0);
        
        bytes memory compressed = new bytes(data.length * 2);
        uint256 compressedLength = 0;
        
        uint256 i = 0;
        while (i < data.length) {
            bytes1 current = data[i];
            uint256 count = 1;
            
            // Count consecutive identical bytes
            while (i + count < data.length && data[i + count] == current && count < 255) {
                count++;
            }
            
            compressed[compressedLength++] = bytes1(uint8(count));
            compressed[compressedLength++] = current;
            
            i += count;
        }
        
        // Resize to actual length
        bytes memory result = new bytes(compressedLength);
        for (uint256 j = 0; j < compressedLength; j++) {
            result[j] = compressed[j];
        }
        
        return result;
    }
    
    /**
     * @dev Decompresses run-length encoded data
     * Use Case: Retrieving original data from compressed storage
     */
    function runLengthDecode(bytes memory compressed) internal pure returns (bytes memory) {
        require(compressed.length % 2 == 0, "EncodingUtils: invalid RLE data");
        
        // Calculate decompressed size
        uint256 decompressedSize = 0;
        for (uint256 i = 0; i < compressed.length; i += 2) {
            decompressedSize += uint8(compressed[i]);
        }
        
        bytes memory decompressed = new bytes(decompressedSize);
        uint256 outputIndex = 0;
        
        for (uint256 i = 0; i < compressed.length; i += 2) {
            uint8 count = uint8(compressed[i]);
            bytes1 value = compressed[i + 1];
            
            for (uint256 j = 0; j < count; j++) {
                decompressed[outputIndex++] = value;
            }
        }
        
        return decompressed;
    }
}