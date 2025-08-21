// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AddressUtils - Address Manipulation and Validation Library
 * @dev Comprehensive utilities for Ethereum address operations
 * 
 * FEATURES:
 * - Address validation and format checking
 * - Contract vs EOA detection and verification
 * - Address generation and derivation utilities
 * - Multi-signature address calculations
 * - CREATE2 address prediction and validation
 * - Address blacklisting and whitelisting
 * 
 * USE CASES:
 * 1. Smart contract deployment address prediction
 * 2. Multi-signature wallet address generation
 * 3. Address validation for security purposes
 * 4. Contract interaction safety checks
 * 5. Address-based access control systems
 * 6. Deterministic address generation for factories
 * 
 * @author Nibert Investments LLC
 * @notice Basic Level - Essential address manipulation tools
 */

library AddressUtils {
    // Error definitions
    error InvalidAddress();
    error NotContractAddress();
    error NotEOAAddress();
    error AddressZero();
    error InvalidSalt();
    error BlacklistedAddress();
    error UnauthorizedAddress();
    
    // Events
    event AddressValidated(address indexed addr, bool isContract);
    event CREATE2AddressPredicted(address indexed predicted, bytes32 indexed salt);
    event AddressWhitelisted(address indexed addr, uint256 timestamp);
    event AddressBlacklisted(address indexed addr, uint256 timestamp);
    
    // Constants
    bytes32 private constant CREATE2_INIT_CODE_HASH = keccak256("CREATE2_FACTORY");
    uint256 private constant ADDRESS_LENGTH = 20;
    
    /**
     * @dev Validates if address is not zero and properly formatted
     * Use Case: Input validation for all address parameters
     */
    function isValidAddress(address addr) internal pure returns (bool) {
        return addr != address(0) && addr != address(0xdead);
    }
    
    /**
     * @dev Checks if address is a smart contract
     * Use Case: Differentiating between EOAs and contracts
     */
    function isContract(address addr) internal view returns (bool) {
        if (addr == address(0)) {
            return false;
        }
        
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    
    /**
     * @dev Enhanced contract check with additional validation
     * Use Case: Comprehensive contract detection with safety checks
     */
    function isContractWithValidation(address addr) internal view returns (bool isContractAddr, bytes32 codeHash) {
        if (addr == address(0)) {
            return (false, bytes32(0));
        }
        
        uint256 size;
        assembly {
            size := extcodesize(addr)
            codeHash := extcodehash(addr)
        }
        
        isContractAddr = size > 0;
        
        // Additional validation for proxy contracts
        if (isContractAddr && codeHash == keccak256("")) {
            isContractAddr = false;
        }
    }
    
    /**
     * @dev Verifies if address is an Externally Owned Account (EOA)
     * Use Case: Ensuring transactions come from user accounts
     */
    function isEOA(address addr) internal view returns (bool) {
        return addr != address(0) && !isContract(addr);
    }
    
    /**
     * @dev Predicts CREATE2 deployment address
     * Use Case: Deterministic address generation for factory patterns
     */
    function predictCREATE2Address(
        address deployer,
        bytes32 salt,
        bytes32 initCodeHash
    ) internal pure returns (address predicted) {
        predicted = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            deployer,
                            salt,
                            initCodeHash
                        )
                    )
                )
            )
        );
    }
    
    /**
     * @dev Generates multi-signature wallet address
     * Use Case: Multi-sig wallet deployment and verification
     */
    function generateMultiSigAddress(
        address[] memory owners,
        uint256 threshold,
        bytes32 salt
    ) internal pure returns (address) {
        require(owners.length > 0, "AddressUtils: no owners");
        require(threshold > 0 && threshold <= owners.length, "AddressUtils: invalid threshold");
        
        bytes memory initCode = abi.encodePacked(
            owners,
            threshold,
            salt
        );
        
        bytes32 initCodeHash = keccak256(initCode);
        
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            initCodeHash
                        )
                    )
                )
            )
        );
    }
    
    /**
     * @dev Derives address from private key (conceptual)
     * Use Case: Address generation and verification
     */
    function deriveAddressFromPublicKey(
        uint256 publicKeyX,
        uint256 publicKeyY
    ) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(publicKeyX, publicKeyY));
        return address(uint160(uint256(hash)));
    }
    
    /**
     * @dev Validates address checksum (EIP-55)
     * Use Case: Ensuring address integrity and preventing typos
     */
    function validateChecksum(string memory addr) internal pure returns (bool) {
        bytes memory addrBytes = bytes(addr);
        
        // Remove '0x' prefix if present
        uint256 offset = 0;
        if (addrBytes.length == 42 && addrBytes[0] == '0' && addrBytes[1] == 'x') {
            offset = 2;
        }
        
        require(addrBytes.length - offset == 40, "AddressUtils: invalid length");
        
        bytes32 hash = keccak256(abi.encodePacked(toLowerCase(addr)));
        
        for (uint256 i = offset; i < addrBytes.length; i++) {
            uint8 char = uint8(addrBytes[i]);
            uint8 hashByte = uint8(hash[i / 2]);
            
            if (char >= 65 && char <= 70) { // A-F
                if ((i % 2 == 0 ? hashByte >> 4 : hashByte & 0x0f) < 8) {
                    return false;
                }
            } else if (char >= 97 && char <= 102) { // a-f
                if ((i % 2 == 0 ? hashByte >> 4 : hashByte & 0x0f) >= 8) {
                    return false;
                }
            }
        }
        
        return true;
    }
    
    /**
     * @dev Converts string to lowercase for checksum validation
     * Use Case: Address normalization for validation
     */
    function toLowerCase(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        
        for (uint256 i = 0; i < bStr.length; i++) {
            if (uint8(bStr[i]) >= 65 && uint8(bStr[i]) <= 90) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        
        return string(bLower);
    }
    
    /**
     * @dev Generates vanity address with specific prefix
     * Use Case: Creating memorable or branded addresses
     */
    function generateVanityAddress(
        bytes memory prefix,
        uint256 maxAttempts
    ) internal view returns (address vanityAddr, uint256 nonce) {
        require(prefix.length > 0, "AddressUtils: empty prefix");
        
        for (uint256 i = 0; i < maxAttempts; i++) {
            nonce = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        i
                    )
                )
            );
            
            vanityAddr = address(uint160(nonce));
            
            if (hasPrefix(abi.encodePacked(vanityAddr), prefix)) {
                return (vanityAddr, nonce);
            }
        }
        
        revert("AddressUtils: vanity address not found");
    }
    
    /**
     * @dev Checks if address bytes have specific prefix
     * Use Case: Vanity address validation
     */
    function hasPrefix(bytes memory addr, bytes memory prefix) internal pure returns (bool) {
        if (prefix.length > addr.length) {
            return false;
        }
        
        for (uint256 i = 0; i < prefix.length; i++) {
            if (addr[i] != prefix[i]) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @dev Computes address distance for proximity checks
     * Use Case: Address clustering and proximity analysis
     */
    function addressDistance(address addr1, address addr2) internal pure returns (uint256) {
        uint256 a1 = uint160(addr1);
        uint256 a2 = uint160(addr2);
        
        return a1 > a2 ? a1 - a2 : a2 - a1;
    }
    
    /**
     * @dev Validates address against multiple criteria
     * Use Case: Comprehensive address validation for security
     */
    function validateAddressSecurity(
        address addr,
        bool requireContract,
        bool requireEOA,
        address[] memory blacklist,
        address[] memory whitelist
    ) internal view returns (bool isValid, string memory reason) {
        // Check for zero address
        if (addr == address(0)) {
            return (false, "Zero address");
        }
        
        // Check blacklist
        for (uint256 i = 0; i < blacklist.length; i++) {
            if (addr == blacklist[i]) {
                return (false, "Blacklisted address");
            }
        }
        
        // Check whitelist (if provided)
        if (whitelist.length > 0) {
            bool inWhitelist = false;
            for (uint256 i = 0; i < whitelist.length; i++) {
                if (addr == whitelist[i]) {
                    inWhitelist = true;
                    break;
                }
            }
            if (!inWhitelist) {
                return (false, "Not whitelisted");
            }
        }
        
        // Check contract requirement
        if (requireContract && !isContract(addr)) {
            return (false, "Not a contract");
        }
        
        // Check EOA requirement
        if (requireEOA && isContract(addr)) {
            return (false, "Not an EOA");
        }
        
        return (true, "Valid address");
    }
    
    /**
     * @dev Generates deterministic address from seed
     * Use Case: Reproducible address generation for testing/deployment
     */
    function generateDeterministicAddress(
        bytes32 seed,
        uint256 index
    ) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(seed, index));
        return address(uint160(uint256(hash)));
    }
    
    /**
     * @dev Batch validates multiple addresses
     * Use Case: Efficient validation of address arrays
     */
    function batchValidateAddresses(
        address[] memory addresses,
        bool requireNonZero
    ) internal view returns (bool[] memory validationResults) {
        validationResults = new bool[](addresses.length);
        
        for (uint256 i = 0; i < addresses.length; i++) {
            if (requireNonZero) {
                validationResults[i] = isValidAddress(addresses[i]);
            } else {
                validationResults[i] = true;
            }
        }
    }
    
    /**
     * @dev Sorts addresses for consistent ordering
     * Use Case: Creating deterministic address sets
     */
    function sortAddresses(address[] memory addresses) internal pure returns (address[] memory) {
        // Simple bubble sort for small arrays
        for (uint256 i = 0; i < addresses.length; i++) {
            for (uint256 j = i + 1; j < addresses.length; j++) {
                if (uint160(addresses[i]) > uint160(addresses[j])) {
                    address temp = addresses[i];
                    addresses[i] = addresses[j];
                    addresses[j] = temp;
                }
            }
        }
        
        return addresses;
    }
    
    /**
     * @dev Removes duplicate addresses from array
     * Use Case: Cleaning address lists for efficient processing
     */
    function removeDuplicateAddresses(
        address[] memory addresses
    ) internal pure returns (address[] memory uniqueAddresses) {
        if (addresses.length == 0) {
            return new address[](0);
        }
        
        address[] memory sorted = sortAddresses(addresses);
        uint256 uniqueCount = 1;
        
        // Count unique addresses
        for (uint256 i = 1; i < sorted.length; i++) {
            if (sorted[i] != sorted[i - 1]) {
                uniqueCount++;
            }
        }
        
        // Create array with unique addresses
        uniqueAddresses = new address[](uniqueCount);
        uniqueAddresses[0] = sorted[0];
        uint256 index = 1;
        
        for (uint256 i = 1; i < sorted.length; i++) {
            if (sorted[i] != sorted[i - 1]) {
                uniqueAddresses[index] = sorted[i];
                index++;
            }
        }
    }
    
    /**
     * @dev Computes weighted average of addresses (conceptual)
     * Use Case: Address consensus in multi-party systems
     */
    function computeAddressConsensus(
        address[] memory addresses,
        uint256[] memory weights
    ) internal pure returns (address consensus) {
        require(addresses.length == weights.length, "AddressUtils: length mismatch");
        require(addresses.length > 0, "AddressUtils: empty arrays");
        
        uint256 totalWeight = 0;
        uint256 weightedSum = 0;
        
        for (uint256 i = 0; i < addresses.length; i++) {
            totalWeight += weights[i];
            weightedSum += uint160(addresses[i]) * weights[i];
        }
        
        consensus = address(uint160(weightedSum / totalWeight));
    }
}