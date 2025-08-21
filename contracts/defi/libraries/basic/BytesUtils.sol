// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title BytesUtils - Comprehensive Bytes Manipulation Library
 * @dev Advanced utilities for bytes operations and data processing
 * 
 * FEATURES:
 * - Bytes concatenation and manipulation
 * - Data encoding and decoding utilities
 * - Bit-level operations and masking
 * - Compression and decompression algorithms
 * - Data integrity verification
 * - Efficient memory management for bytes
 * 
 * USE CASES:
 * 1. Data serialization for cross-contract communication
 * 2. Compact data storage and retrieval
 * 3. Protocol buffer-like encoding/decoding
 * 4. Efficient bit manipulation for flags and states
 * 5. Data compression for gas optimization
 * 6. Message formatting for off-chain communication
 * 
 * @author Nibert Investments LLC
 * @notice Basic Level - Essential bytes processing utilities
 */

library BytesUtils {
    // Error definitions
    error InvalidLength();
    error OutOfBounds();
    error InvalidEncoding();
    error CompressionFailed();
    error DecompressionFailed();
    error InvalidChecksum();
    
    // Events
    event DataEncoded(bytes indexed data, uint256 originalLength, uint256 encodedLength);
    event DataDecoded(bytes indexed encodedData, uint256 decodedLength);
    event CompressionApplied(uint256 originalSize, uint256 compressedSize, uint256 ratio);
    
    // Constants
    uint256 private constant CHUNK_SIZE = 32;
    bytes1 private constant PADDING_BYTE = 0x00;
    
    /**
     * @dev Concatenates multiple bytes arrays efficiently
     * Use Case: Combining data from multiple sources
     */
    function concat(bytes[] memory arrays) internal pure returns (bytes memory result) {
        uint256 totalLength = 0;
        
        // Calculate total length
        for (uint256 i = 0; i < arrays.length; i++) {
            totalLength += arrays[i].length;
        }
        
        result = new bytes(totalLength);
        uint256 offset = 0;
        
        // Copy arrays
        for (uint256 i = 0; i < arrays.length; i++) {
            for (uint256 j = 0; j < arrays[i].length; j++) {
                result[offset + j] = arrays[i][j];
            }
            offset += arrays[i].length;
        }
    }
    
    /**
     * @dev Splits bytes into chunks of specified size
     * Use Case: Data pagination and processing in segments
     */
    function split(bytes memory data, uint256 chunkSize) internal pure returns (bytes[] memory chunks) {
        require(chunkSize > 0, "BytesUtils: invalid chunk size");
        
        uint256 numChunks = (data.length + chunkSize - 1) / chunkSize;
        chunks = new bytes[](numChunks);
        
        for (uint256 i = 0; i < numChunks; i++) {
            uint256 start = i * chunkSize;
            uint256 end = start + chunkSize;
            if (end > data.length) {
                end = data.length;
            }
            
            chunks[i] = slice(data, start, end - start);
        }
    }
    
    /**
     * @dev Extracts a slice from bytes array
     * Use Case: Efficient data extraction without copying entire array
     */
    function slice(bytes memory data, uint256 start, uint256 length) internal pure returns (bytes memory) {
        require(start + length <= data.length, "BytesUtils: slice out of bounds");
        
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = data[start + i];
        }
        
        return result;
    }
    
    /**
     * @dev Reverses bytes array
     * Use Case: Endianness conversion, data transformation
     */
    function reverse(bytes memory data) internal pure returns (bytes memory) {
        bytes memory reversed = new bytes(data.length);
        
        for (uint256 i = 0; i < data.length; i++) {
            reversed[i] = data[data.length - 1 - i];
        }
        
        return reversed;
    }
    
    /**
     * @dev Converts bytes to hexadecimal string
     * Use Case: Human-readable data representation
     */
    function toHexString(bytes memory data) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory result = new bytes(2 * data.length + 2);
        
        result[0] = "0";
        result[1] = "x";
        
        for (uint256 i = 0; i < data.length; i++) {
            result[2 + 2 * i] = hexChars[uint8(data[i]) / 16];
            result[2 + 2 * i + 1] = hexChars[uint8(data[i]) % 16];
        }
        
        return string(result);
    }
    
    /**
     * @dev Converts hexadecimal string to bytes
     * Use Case: Parsing hex-encoded data from external sources
     */
    function fromHexString(string memory hexStr) internal pure returns (bytes memory) {
        bytes memory hexBytes = bytes(hexStr);
        
        // Remove '0x' prefix if present
        uint256 offset = 0;
        if (hexBytes.length >= 2 && hexBytes[0] == '0' && hexBytes[1] == 'x') {
            offset = 2;
        }
        
        require((hexBytes.length - offset) % 2 == 0, "BytesUtils: invalid hex string");
        
        bytes memory result = new bytes((hexBytes.length - offset) / 2);
        
        for (uint256 i = 0; i < result.length; i++) {
            result[i] = bytes1(
                hexCharToByte(hexBytes[offset + 2 * i]) * 16 +
                hexCharToByte(hexBytes[offset + 2 * i + 1])
            );
        }
        
        return result;
    }
    
    /**
     * @dev Converts hex character to byte value
     * Use Case: Helper for hex string parsing
     */
    function hexCharToByte(bytes1 char) internal pure returns (uint8) {
        if (char >= '0' && char <= '9') {
            return uint8(char) - uint8('0');
        } else if (char >= 'a' && char <= 'f') {
            return uint8(char) - uint8('a') + 10;
        } else if (char >= 'A' && char <= 'F') {
            return uint8(char) - uint8('A') + 10;
        } else {
            revert("BytesUtils: invalid hex character");
        }
    }
    
    /**
     * @dev Pads bytes to specified length
     * Use Case: Data alignment for fixed-size protocols
     */
    function padTo(bytes memory data, uint256 targetLength, bool padLeft) internal pure returns (bytes memory) {
        if (data.length >= targetLength) {
            return data;
        }
        
        bytes memory padded = new bytes(targetLength);
        uint256 paddingLength = targetLength - data.length;
        
        if (padLeft) {
            // Pad on the left
            for (uint256 i = 0; i < paddingLength; i++) {
                padded[i] = PADDING_BYTE;
            }
            for (uint256 i = 0; i < data.length; i++) {
                padded[paddingLength + i] = data[i];
            }
        } else {
            // Pad on the right
            for (uint256 i = 0; i < data.length; i++) {
                padded[i] = data[i];
            }
            for (uint256 i = data.length; i < targetLength; i++) {
                padded[i] = PADDING_BYTE;
            }
        }
        
        return padded;
    }
    
    /**
     * @dev Removes padding from bytes
     * Use Case: Data cleanup after receiving padded data
     */
    function removePadding(bytes memory data, bool fromLeft) internal pure returns (bytes memory) {
        uint256 start = 0;
        uint256 end = data.length;
        
        if (fromLeft) {
            // Remove padding from left
            while (start < data.length && data[start] == PADDING_BYTE) {
                start++;
            }
        } else {
            // Remove padding from right
            while (end > 0 && data[end - 1] == PADDING_BYTE) {
                end--;
            }
        }
        
        return slice(data, start, end - start);
    }
    
    /**
     * @dev Compresses bytes using simple run-length encoding
     * Use Case: Gas-efficient storage of repetitive data
     */
    function compress(bytes memory data) internal pure returns (bytes memory compressed) {
        if (data.length == 0) {
            return new bytes(0);
        }
        
        // Estimate maximum compressed size (worst case: 2x original)
        bytes memory temp = new bytes(data.length * 2);
        uint256 compressedIndex = 0;
        
        uint256 i = 0;
        while (i < data.length) {
            bytes1 currentByte = data[i];
            uint256 count = 1;
            
            // Count consecutive occurrences
            while (i + count < data.length && data[i + count] == currentByte && count < 255) {
                count++;
            }
            
            // Store count and byte
            temp[compressedIndex++] = bytes1(uint8(count));
            temp[compressedIndex++] = currentByte;
            
            i += count;
        }
        
        // Create properly sized result
        compressed = new bytes(compressedIndex);
        for (uint256 j = 0; j < compressedIndex; j++) {
            compressed[j] = temp[j];
        }
    }
    
    /**
     * @dev Decompresses run-length encoded bytes
     * Use Case: Retrieving original data from compressed storage
     */
    function decompress(bytes memory compressed) internal pure returns (bytes memory data) {
        require(compressed.length % 2 == 0, "BytesUtils: invalid compressed data");
        
        // Calculate decompressed size
        uint256 decompressedSize = 0;
        for (uint256 i = 0; i < compressed.length; i += 2) {
            decompressedSize += uint8(compressed[i]);
        }
        
        data = new bytes(decompressedSize);
        uint256 dataIndex = 0;
        
        // Decompress data
        for (uint256 i = 0; i < compressed.length; i += 2) {
            uint8 count = uint8(compressed[i]);
            bytes1 byteValue = compressed[i + 1];
            
            for (uint256 j = 0; j < count; j++) {
                data[dataIndex++] = byteValue;
            }
        }
    }
    
    /**
     * @dev XOR operation on two bytes arrays
     * Use Case: Simple encryption/decryption, data masking
     */
    function xor(bytes memory data1, bytes memory data2) internal pure returns (bytes memory) {
        uint256 length = data1.length < data2.length ? data1.length : data2.length;
        bytes memory result = new bytes(length);
        
        for (uint256 i = 0; i < length; i++) {
            result[i] = data1[i] ^ data2[i];
        }
        
        return result;
    }
    
    /**
     * @dev Finds pattern in bytes array
     * Use Case: Data parsing and pattern matching
     */
    function find(bytes memory data, bytes memory pattern) internal pure returns (int256 index) {
        if (pattern.length == 0 || pattern.length > data.length) {
            return -1;
        }
        
        for (uint256 i = 0; i <= data.length - pattern.length; i++) {
            bool found = true;
            
            for (uint256 j = 0; j < pattern.length; j++) {
                if (data[i + j] != pattern[j]) {
                    found = false;
                    break;
                }
            }
            
            if (found) {
                return int256(i);
            }
        }
        
        return -1;
    }
    
    /**
     * @dev Replaces pattern in bytes array
     * Use Case: Data transformation and sanitization
     */
    function replace(
        bytes memory data,
        bytes memory pattern,
        bytes memory replacement
    ) internal pure returns (bytes memory) {
        int256 index = find(data, pattern);
        
        if (index == -1) {
            return data;
        }
        
        uint256 newLength = data.length - pattern.length + replacement.length;
        bytes memory result = new bytes(newLength);
        
        // Copy data before pattern
        for (uint256 i = 0; i < uint256(index); i++) {
            result[i] = data[i];
        }
        
        // Copy replacement
        for (uint256 i = 0; i < replacement.length; i++) {
            result[uint256(index) + i] = replacement[i];
        }
        
        // Copy data after pattern
        uint256 afterPatternStart = uint256(index) + pattern.length;
        for (uint256 i = afterPatternStart; i < data.length; i++) {
            result[uint256(index) + replacement.length + i - afterPatternStart] = data[i];
        }
        
        return result;
    }
    
    /**
     * @dev Calculates checksum for data integrity
     * Use Case: Data integrity verification
     */
    function calculateChecksum(bytes memory data) internal pure returns (bytes4) {
        return bytes4(keccak256(data));
    }
    
    /**
     * @dev Verifies data integrity using checksum
     * Use Case: Validating received data integrity
     */
    function verifyChecksum(bytes memory data, bytes4 expectedChecksum) internal pure returns (bool) {
        return calculateChecksum(data) == expectedChecksum;
    }
    
    /**
     * @dev Encodes data with length prefix
     * Use Case: Protocol message formatting
     */
    function encodeWithLength(bytes memory data) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(data.length + 4);
        
        // Encode length as uint32 big-endian
        encoded[0] = bytes1(uint8(data.length >> 24));
        encoded[1] = bytes1(uint8(data.length >> 16));
        encoded[2] = bytes1(uint8(data.length >> 8));
        encoded[3] = bytes1(uint8(data.length));
        
        // Copy data
        for (uint256 i = 0; i < data.length; i++) {
            encoded[4 + i] = data[i];
        }
        
        return encoded;
    }
    
    /**
     * @dev Decodes length-prefixed data
     * Use Case: Protocol message parsing
     */
    function decodeWithLength(bytes memory encoded) internal pure returns (bytes memory data) {
        require(encoded.length >= 4, "BytesUtils: insufficient data for length");
        
        // Decode length from first 4 bytes
        uint256 length = (uint256(uint8(encoded[0])) << 24) |
                        (uint256(uint8(encoded[1])) << 16) |
                        (uint256(uint8(encoded[2])) << 8) |
                        uint256(uint8(encoded[3]));
        
        require(encoded.length >= 4 + length, "BytesUtils: insufficient data");
        
        data = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            data[i] = encoded[4 + i];
        }
    }
    
    /**
     * @dev Swaps endianness of multi-byte values
     * Use Case: Cross-platform data compatibility
     */
    function swapEndianness(bytes memory data, uint256 wordSize) internal pure returns (bytes memory) {
        require(data.length % wordSize == 0, "BytesUtils: invalid word size");
        
        bytes memory swapped = new bytes(data.length);
        
        for (uint256 i = 0; i < data.length; i += wordSize) {
            for (uint256 j = 0; j < wordSize; j++) {
                swapped[i + j] = data[i + wordSize - 1 - j];
            }
        }
        
        return swapped;
    }
}