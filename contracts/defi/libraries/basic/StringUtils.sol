// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title StringUtils - Advanced String Manipulation Library
 * @dev Comprehensive string processing utilities for smart contracts
 * 
 * FEATURES:
 * - String validation and sanitization
 * - Pattern matching and regular expression-like operations
 * - Case conversion and normalization
 * - String encoding/decoding utilities
 * - Gas-optimized string operations
 * 
 * USE CASES:
 * 1. User input validation for DApps
 * 2. Domain name and ENS processing
 * 3. Token metadata and NFT attributes
 * 4. Data formatting for external APIs
 * 5. Access control with string-based permissions
 * 6. Multi-language support and localization
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library StringUtils {
    /**
     * @dev Converts string to lowercase
     * Use Case: Normalizing user input, case-insensitive comparisons
     */
    function toLowerCase(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        
        return string(bLower);
    }
    
    /**
     * @dev Converts string to uppercase
     * Use Case: Data normalization, consistent formatting
     */
    function toUpperCase(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bUpper = new bytes(bStr.length);
        
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 97) && (uint8(bStr[i]) <= 122)) {
                bUpper[i] = bytes1(uint8(bStr[i]) - 32);
            } else {
                bUpper[i] = bStr[i];
            }
        }
        
        return string(bUpper);
    }
    
    /**
     * @dev Compares two strings for equality
     * Use Case: String-based access control, data validation
     */
    function isEqual(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    
    /**
     * @dev Checks if string is empty
     * Use Case: Input validation, required field checking
     */
    function isEmpty(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }
    
    /**
     * @dev Gets the length of a string
     * Use Case: Validation, formatting constraints
     */
    function length(string memory str) internal pure returns (uint256) {
        return bytes(str).length;
    }
    
    /**
     * @dev Concatenates two strings
     * Use Case: Dynamic string building, metadata generation
     */
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    
    /**
     * @dev Concatenates multiple strings
     * Use Case: Complex string building, template processing
     */
    function concatMultiple(string[] memory strs) internal pure returns (string memory) {
        bytes memory result;
        
        for (uint256 i = 0; i < strs.length; i++) {
            result = abi.encodePacked(result, strs[i]);
        }
        
        return string(result);
    }
    
    /**
     * @dev Extracts substring from start to end index
     * Use Case: String parsing, data extraction
     */
    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex <= endIndex && endIndex <= strBytes.length, "StringUtils: invalid indices");
        
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        
        return string(result);
    }
    
    /**
     * @dev Finds the index of a character in string
     * Use Case: String parsing, delimiter detection
     */
    function indexOf(string memory str, string memory searchStr) internal pure returns (int256) {
        bytes memory strBytes = bytes(str);
        bytes memory searchBytes = bytes(searchStr);
        
        if (searchBytes.length > strBytes.length) return -1;
        
        for (uint256 i = 0; i <= strBytes.length - searchBytes.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < searchBytes.length; j++) {
                if (strBytes[i + j] != searchBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return int256(i);
        }
        
        return -1;
    }
    
    /**
     * @dev Replaces all occurrences of search string with replacement
     * Use Case: String templating, data sanitization
     */
    function replace(
        string memory str,
        string memory search,
        string memory replacement
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory searchBytes = bytes(search);
        bytes memory replacementBytes = bytes(replacement);
        
        if (searchBytes.length == 0) return str;
        
        uint256 count = 0;
        uint256 i = 0;
        
        // Count occurrences
        while (i <= strBytes.length - searchBytes.length) {
            bool found = true;
            for (uint256 j = 0; j < searchBytes.length; j++) {
                if (strBytes[i + j] != searchBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                count++;
                i += searchBytes.length;
            } else {
                i++;
            }
        }
        
        if (count == 0) return str;
        
        // Calculate new length
        uint256 newLength = strBytes.length + 
            count * (replacementBytes.length - searchBytes.length);
        bytes memory result = new bytes(newLength);
        
        uint256 resultIndex = 0;
        i = 0;
        
        while (i < strBytes.length) {
            bool found = false;
            if (i <= strBytes.length - searchBytes.length) {
                found = true;
                for (uint256 j = 0; j < searchBytes.length; j++) {
                    if (strBytes[i + j] != searchBytes[j]) {
                        found = false;
                        break;
                    }
                }
            }
            
            if (found) {
                for (uint256 j = 0; j < replacementBytes.length; j++) {
                    result[resultIndex++] = replacementBytes[j];
                }
                i += searchBytes.length;
            } else {
                result[resultIndex++] = strBytes[i++];
            }
        }
        
        return string(result);
    }
    
    /**
     * @dev Trims whitespace from both ends of string
     * Use Case: Input sanitization, data cleaning
     */
    function trim(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length == 0) return str;
        
        uint256 start = 0;
        uint256 end = strBytes.length;
        
        // Find start position (skip leading whitespace)
        while (start < strBytes.length && isWhitespace(strBytes[start])) {
            start++;
        }
        
        // Find end position (skip trailing whitespace)
        while (end > start && isWhitespace(strBytes[end - 1])) {
            end--;
        }
        
        if (start == 0 && end == strBytes.length) return str;
        
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = strBytes[i];
        }
        
        return string(result);
    }
    
    /**
     * @dev Checks if a byte is whitespace character
     * Use Case: Internal helper for trim function
     */
    function isWhitespace(bytes1 char) internal pure returns (bool) {
        return char == 0x20 || // space
               char == 0x09 || // tab
               char == 0x0A || // line feed
               char == 0x0D;   // carriage return
    }
    
    /**
     * @dev Validates that string contains only alphanumeric characters
     * Use Case: Username validation, identifier checking
     */
    function isAlphanumeric(string memory str) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        
        for (uint256 i = 0; i < strBytes.length; i++) {
            uint8 char = uint8(strBytes[i]);
            if (!((char >= 48 && char <= 57) ||  // 0-9
                  (char >= 65 && char <= 90) ||  // A-Z
                  (char >= 97 && char <= 122))) { // a-z
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @dev Validates that string contains only numeric characters
     * Use Case: Number validation, input checking
     */
    function isNumeric(string memory str) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length == 0) return false;
        
        for (uint256 i = 0; i < strBytes.length; i++) {
            uint8 char = uint8(strBytes[i]);
            if (char < 48 || char > 57) { // 0-9
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @dev Converts string to bytes32 (truncates if longer)
     * Use Case: Storage optimization, mapping keys
     */
    function stringToBytes32(string memory str) internal pure returns (bytes32) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length <= 32, "StringUtils: string too long");
        
        bytes32 result;
        assembly {
            result := mload(add(strBytes, 32))
        }
        
        return result;
    }
    
    /**
     * @dev Converts bytes32 to string (removes null bytes)
     * Use Case: Reading stored string data
     */
    function bytes32ToString(bytes32 data) internal pure returns (string memory) {
        uint256 length = 0;
        while (length < 32 && data[length] != 0) {
            length++;
        }
        
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = data[i];
        }
        
        return string(result);
    }
    
    /**
     * @dev Splits string by delimiter
     * Use Case: CSV parsing, data extraction
     */
    function split(string memory str, string memory delimiter) 
        internal pure returns (string[] memory) {
        bytes memory strBytes = bytes(str);
        bytes memory delimiterBytes = bytes(delimiter);
        
        if (strBytes.length == 0) {
            return new string[](0);
        }
        
        // Count delimiters to determine array size
        uint256 count = 1;
        uint256 i = 0;
        
        while (i <= strBytes.length - delimiterBytes.length) {
            bool found = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                count++;
                i += delimiterBytes.length;
            } else {
                i++;
            }
        }
        
        string[] memory result = new string[](count);
        uint256 resultIndex = 0;
        uint256 lastIndex = 0;
        i = 0;
        
        while (i <= strBytes.length - delimiterBytes.length) {
            bool found = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    found = false;
                    break;
                }
            }
            
            if (found) {
                result[resultIndex++] = substring(str, lastIndex, i);
                i += delimiterBytes.length;
                lastIndex = i;
            } else {
                i++;
            }
        }
        
        // Add final part
        if (lastIndex < strBytes.length) {
            result[resultIndex] = substring(str, lastIndex, strBytes.length);
        }
        
        return result;
    }
}