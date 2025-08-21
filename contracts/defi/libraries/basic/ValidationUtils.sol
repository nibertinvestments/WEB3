// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ValidationUtils - Comprehensive Input Validation Library
 * @dev Advanced validation utilities for smart contract security
 * 
 * FEATURES:
 * - Address validation and verification
 * - Numeric range and boundary checking
 * - String format validation (email, URL, identifier patterns)
 * - Cryptographic signature verification
 * - Business logic validation patterns
 * 
 * USE CASES:
 * 1. User input sanitization and validation
 * 2. Smart contract parameter verification
 * 3. Access control and permission validation
 * 4. Financial transaction validation
 * 5. Data integrity and format checking
 * 6. Security-critical operation validation
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library ValidationUtils {
    // Custom errors for gas-efficient error handling
    error InvalidAddress();
    error InvalidRange();
    error InvalidFormat();
    error InvalidSignature();
    error InvalidLength();
    
    /**
     * @dev Validates Ethereum address format and properties
     * Use Case: Address input validation, contract interaction safety
     */
    function isValidAddress(address addr) internal pure returns (bool) {
        return addr != address(0) && addr != address(0xdead);
    }
    
    /**
     * @dev Validates address is not zero and not a known burn address
     * Use Case: Token transfer validation, recipient verification
     */
    function requireValidAddress(address addr) internal pure {
        if (!isValidAddress(addr)) revert InvalidAddress();
    }
    
    /**
     * @dev Validates address is a contract (has code)
     * Use Case: Contract interaction validation, proxy verification
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    
    /**
     * @dev Validates numeric value is within specified range
     * Use Case: Parameter bounds checking, financial limits
     */
    function isInRange(uint256 value, uint256 min, uint256 max) 
        internal pure returns (bool) {
        return value >= min && value <= max;
    }
    
    /**
     * @dev Requires numeric value to be within specified range
     * Use Case: Enforcing business rule constraints
     */
    function requireInRange(uint256 value, uint256 min, uint256 max) internal pure {
        if (!isInRange(value, min, max)) revert InvalidRange();
    }
    
    /**
     * @dev Validates percentage is between 0 and 100 (with 18 decimals)
     * Use Case: Fee validation, allocation percentage checking
     */
    function isValidPercentage(uint256 percentage) internal pure returns (bool) {
        return percentage <= 100 * 1e18; // 100% with 18 decimals
    }
    
    /**
     * @dev Validates basis points (0-10000, where 10000 = 100%)
     * Use Case: Fee calculation validation, precise percentage handling
     */
    function isValidBasisPoints(uint256 bps) internal pure returns (bool) {
        return bps <= 10000;
    }
    
    /**
     * @dev Validates string length within specified bounds
     * Use Case: Username validation, description length checking
     */
    function isValidStringLength(string memory str, uint256 minLen, uint256 maxLen) 
        internal pure returns (bool) {
        uint256 len = bytes(str).length;
        return len >= minLen && len <= maxLen;
    }
    
    /**
     * @dev Validates email format (basic pattern matching)
     * Use Case: User registration, contact information validation
     */
    function isValidEmail(string memory email) internal pure returns (bool) {
        bytes memory emailBytes = bytes(email);
        if (emailBytes.length < 5) return false; // Minimum: a@b.c
        
        bool hasAt = false;
        bool hasDot = false;
        uint256 atPosition = 0;
        uint256 dotPosition = 0;
        
        for (uint256 i = 0; i < emailBytes.length; i++) {
            if (emailBytes[i] == '@') {
                if (hasAt) return false; // Multiple @ symbols
                hasAt = true;
                atPosition = i;
            } else if (emailBytes[i] == '.') {
                if (hasAt && i > atPosition) {
                    hasDot = true;
                    dotPosition = i;
                }
            }
        }
        
        return hasAt && hasDot && 
               atPosition > 0 && // @ not at start
               dotPosition > atPosition + 1 && // dot after @
               dotPosition < emailBytes.length - 1; // dot not at end
    }
    
    /**
     * @dev Validates URL format (basic HTTP/HTTPS pattern)
     * Use Case: Metadata URL validation, external link verification
     */
    function isValidURL(string memory url) internal pure returns (bool) {
        bytes memory urlBytes = bytes(url);
        if (urlBytes.length < 7) return false; // Minimum: http://
        
        // Check for http:// or https://
        bool isHttp = true;
        bool isHttps = true;
        
        string memory httpPrefix = "http://";
        string memory httpsPrefix = "https://";
        
        if (urlBytes.length < 7) isHttp = false;
        if (urlBytes.length < 8) isHttps = false;
        
        // Check HTTP prefix
        for (uint256 i = 0; i < 7 && isHttp; i++) {
            if (urlBytes[i] != bytes(httpPrefix)[i]) {
                isHttp = false;
            }
        }
        
        // Check HTTPS prefix
        for (uint256 i = 0; i < 8 && isHttps && urlBytes.length >= 8; i++) {
            if (urlBytes[i] != bytes(httpsPrefix)[i]) {
                isHttps = false;
            }
        }
        
        return isHttp || isHttps;
    }
    
    /**
     * @dev Validates alphanumeric identifier (letters, numbers, underscore)
     * Use Case: Token symbol validation, identifier checking
     */
    function isValidIdentifier(string memory identifier) internal pure returns (bool) {
        bytes memory idBytes = bytes(identifier);
        if (idBytes.length == 0) return false;
        
        for (uint256 i = 0; i < idBytes.length; i++) {
            uint8 char = uint8(idBytes[i]);
            if (!((char >= 48 && char <= 57) ||  // 0-9
                  (char >= 65 && char <= 90) ||  // A-Z
                  (char >= 97 && char <= 122) || // a-z
                  char == 95)) {                 // underscore
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @dev Validates hex string format
     * Use Case: Hash validation, hexadecimal input checking
     */
    function isValidHex(string memory hexStr) internal pure returns (bool) {
        bytes memory hexBytes = bytes(hexStr);
        
        // Check for 0x prefix
        if (hexBytes.length < 2) return false;
        if (hexBytes[0] != '0' || hexBytes[1] != 'x') return false;
        
        // Check remaining characters are valid hex
        for (uint256 i = 2; i < hexBytes.length; i++) {
            uint8 char = uint8(hexBytes[i]);
            if (!((char >= 48 && char <= 57) ||  // 0-9
                  (char >= 65 && char <= 70) ||  // A-F
                  (char >= 97 && char <= 102))) { // a-f
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @dev Validates timestamp is not in the future
     * Use Case: Event validation, chronological ordering
     */
    function isValidPastTimestamp(uint256 timestamp) internal view returns (bool) {
        return timestamp <= block.timestamp;
    }
    
    /**
     * @dev Validates timestamp is within acceptable future range
     * Use Case: Scheduled event validation, deadline checking
     */
    function isValidFutureTimestamp(uint256 timestamp, uint256 maxFuture) 
        internal view returns (bool) {
        return timestamp > block.timestamp && 
               timestamp <= block.timestamp + maxFuture;
    }
    
    /**
     * @dev Validates array has no duplicate addresses
     * Use Case: Unique recipient validation, voter verification
     */
    function hasNoDuplicateAddresses(address[] memory addresses) 
        internal pure returns (bool) {
        for (uint256 i = 0; i < addresses.length; i++) {
            for (uint256 j = i + 1; j < addresses.length; j++) {
                if (addresses[i] == addresses[j]) {
                    return false;
                }
            }
        }
        return true;
    }
    
    /**
     * @dev Validates array elements sum to expected total
     * Use Case: Allocation validation, distribution verification
     */
    function sumEqualsTotal(uint256[] memory values, uint256 expectedTotal) 
        internal pure returns (bool) {
        uint256 actualTotal = 0;
        for (uint256 i = 0; i < values.length; i++) {
            actualTotal += values[i];
        }
        return actualTotal == expectedTotal;
    }
    
    /**
     * @dev Validates ECDSA signature
     * Use Case: Message authentication, permit function validation
     */
    function isValidSignature(
        bytes32 hash,
        bytes memory signature,
        address expectedSigner
    ) internal pure returns (bool) {
        if (signature.length != 65) return false;
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        if (v < 27) v += 27;
        if (v != 27 && v != 28) return false;
        
        address recoveredSigner = ecrecover(hash, v, r, s);
        return recoveredSigner == expectedSigner && recoveredSigner != address(0);
    }
    
    /**
     * @dev Validates EIP-712 typed data signature
     * Use Case: Advanced signature validation, structured data signing
     */
    function isValidTypedSignature(
        bytes32 domainSeparator,
        bytes32 structHash,
        bytes memory signature,
        address expectedSigner
    ) internal pure returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        return isValidSignature(digest, signature, expectedSigner);
    }
    
    /**
     * @dev Validates business hours (24-hour format)
     * Use Case: Time-restricted operations, scheduled execution
     */
    function isDuringBusinessHours(uint256 hour) internal pure returns (bool) {
        return hour >= 9 && hour <= 17; // 9 AM to 5 PM
    }
    
    /**
     * @dev Validates weekday (Monday-Friday)
     * Use Case: Business day restrictions, scheduled operations
     */
    function isWeekday(uint256 dayOfWeek) internal pure returns (bool) {
        return dayOfWeek >= 1 && dayOfWeek <= 5; // Monday = 1, Friday = 5
    }
    
    /**
     * @dev Validates amount against minimum and includes fee tolerance
     * Use Case: Payment validation with fee consideration
     */
    function isValidPaymentAmount(
        uint256 amount,
        uint256 expectedAmount,
        uint256 feePercentage
    ) internal pure returns (bool) {
        uint256 minAcceptable = expectedAmount - (expectedAmount * feePercentage / 10000);
        return amount >= minAcceptable && amount <= expectedAmount;
    }
    
    /**
     * @dev Comprehensive validation for token transfer parameters
     * Use Case: Token transfer security validation
     */
    function validateTransfer(
        address from,
        address to,
        uint256 amount,
        uint256 balance
    ) internal pure returns (bool) {
        return isValidAddress(from) &&
               isValidAddress(to) &&
               amount > 0 &&
               amount <= balance &&
               from != to;
    }
    
    /**
     * @dev Validates contract deployment parameters
     * Use Case: Factory contract validation, deployment security
     */
    function validateDeployment(
        bytes memory bytecode,
        uint256 value,
        bytes32 salt
    ) internal pure returns (bool) {
        return bytecode.length > 0 &&
               value >= 0 &&
               salt != bytes32(0);
    }
}