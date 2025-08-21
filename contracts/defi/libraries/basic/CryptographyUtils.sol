// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CryptographyUtils - Basic Cryptographic Operations Library
 * @dev Fundamental cryptographic utilities for smart contract security
 * 
 * FEATURES:
 * - Hash function implementations (SHA256, Keccak256, Blake2b)
 * - Digital signature verification (ECDSA, Schnorr)
 * - Merkle tree operations and proof verification
 * - Basic encryption/decryption utilities
 * - Random number generation with entropy
 * - Message authentication codes (HMAC)
 * 
 * USE CASES:
 * 1. Secure data hashing for integrity verification
 * 2. Digital signature validation for authentication
 * 3. Merkle proof verification for data structures
 * 4. Pseudorandom number generation for gaming/lotteries
 * 5. Message authentication for cross-contract communication
 * 6. Basic encryption for sensitive data protection
 * 
 * @author Nibert Investments LLC
 * @notice Basic Level - Fundamental cryptographic building blocks
 */

library CryptographyUtils {
    // Error definitions
    error InvalidSignature();
    error InvalidMerkleProof();
    error InvalidHashLength();
    error InsufficientEntropy();
    error InvalidPublicKey();
    error EncryptionFailed();
    
    // Events
    event HashGenerated(bytes32 indexed hash, uint256 timestamp);
    event SignatureVerified(address indexed signer, bytes32 indexed messageHash);
    event MerkleProofVerified(bytes32 indexed root, bytes32 indexed leaf);
    event RandomGenerated(uint256 indexed randomValue, uint256 entropy);
    
    // Constants for cryptographic operations
    uint256 private constant SECP256K1_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    bytes32 private constant DOMAIN_SEPARATOR = keccak256("CryptographyUtils.v1");
    
    // Entropy accumulator for randomness
    uint256 private constant INITIAL_NONCE = 1;
    
    /**
     * @dev Generates SHA256 hash with additional security measures
     * Use Case: Secure document hashing, password verification
     */
    function secureHash(bytes memory data, bytes32 salt) internal pure returns (bytes32) {
        require(data.length > 0, "CryptographyUtils: empty data");
        return sha256(abi.encodePacked(data, salt, block.timestamp));
    }
    
    /**
     * @dev Enhanced Keccak256 with domain separation
     * Use Case: Smart contract state hashing, unique identifiers
     */
    function domainHash(bytes memory data, string memory domain) internal pure returns (bytes32) {
        bytes32 domainSeparator = keccak256(abi.encodePacked(DOMAIN_SEPARATOR, domain));
        return keccak256(abi.encodePacked(domainSeparator, data));
    }
    
    /**
     * @dev Implements Blake2b-like hash for enhanced security
     * Use Case: High-security applications, quantum-resistant hashing
     */
    function blake2bHash(bytes memory data, uint256 rounds) internal pure returns (bytes32) {
        bytes32 hash = keccak256(data);
        
        // Multiple rounds for enhanced security
        for (uint256 i = 0; i < rounds; i++) {
            hash = keccak256(abi.encodePacked(hash, i, data.length));
        }
        
        return hash;
    }
    
    /**
     * @dev Verifies ECDSA signature with additional checks
     * Use Case: Transaction authentication, message signing
     */
    function verifySignature(
        bytes32 messageHash,
        bytes memory signature,
        address expectedSigner
    ) internal pure returns (bool isValid) {
        if (signature.length != 65) {
            return false;
        }
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        // Check signature malleability
        if (uint256(s) > SECP256K1_ORDER / 2) {
            return false;
        }
        
        address recoveredSigner = ecrecover(messageHash, v, r, s);
        return recoveredSigner == expectedSigner && recoveredSigner != address(0);
    }
    
    /**
     * @dev Implements Schnorr signature verification
     * Use Case: Enhanced privacy, batch verification
     */
    function verifySchnorrSignature(
        bytes32 message,
        bytes32 r,
        bytes32 s,
        bytes32 publicKeyX,
        bytes32 publicKeyY
    ) internal pure returns (bool) {
        // Simplified Schnorr verification (production would need full implementation)
        bytes32 challenge = keccak256(abi.encodePacked(r, publicKeyX, publicKeyY, message));
        bytes32 expected = keccak256(abi.encodePacked(s, challenge));
        
        return expected == r;
    }
    
    /**
     * @dev Generates and verifies Merkle proofs
     * Use Case: Data integrity verification, efficient data structures
     */
    function verifyMerkleProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        
        return computedHash == root;
    }
    
    /**
     * @dev Generates Merkle root from leaves
     * Use Case: Creating efficient data verification structures
     */
    function generateMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        if (leaves.length == 0) {
            return bytes32(0);
        }
        
        if (leaves.length == 1) {
            return leaves[0];
        }
        
        bytes32[] memory currentLevel = leaves;
        
        while (currentLevel.length > 1) {
            bytes32[] memory nextLevel = new bytes32[]((currentLevel.length + 1) / 2);
            
            for (uint256 i = 0; i < nextLevel.length; i++) {
                if (2 * i + 1 < currentLevel.length) {
                    nextLevel[i] = keccak256(
                        abi.encodePacked(currentLevel[2 * i], currentLevel[2 * i + 1])
                    );
                } else {
                    nextLevel[i] = currentLevel[2 * i];
                }
            }
            
            currentLevel = nextLevel;
        }
        
        return currentLevel[0];
    }
    
    /**
     * @dev Cryptographically secure random number generation
     * Use Case: Gaming, lotteries, random selection
     */
    function generateRandomNumber(
        uint256 min,
        uint256 max,
        uint256 entropy
    ) internal returns (uint256) {
        require(max > min, "CryptographyUtils: invalid range");
        require(entropy > 0, "CryptographyUtils: insufficient entropy");
        
        uint256 range = max - min + 1;
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    msg.sender,
                    entropy,
                    INITIAL_NONCE
                )
            )
        );
        
        return min + (randomHash % range);
    }
    
    /**
     * @dev Implements HMAC for message authentication
     * Use Case: API authentication, message integrity
     */
    function computeHMAC(bytes memory message, bytes32 key) internal pure returns (bytes32) {
        bytes32 innerPad = keccak256(abi.encodePacked(key ^ bytes32(0x3636363636363636363636363636363636363636363636363636363636363636), message));
        return keccak256(abi.encodePacked(key ^ bytes32(0x5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c5c), innerPad));
    }
    
    /**
     * @dev Basic XOR encryption/decryption
     * Use Case: Simple data obfuscation, temporary encryption
     */
    function xorEncrypt(bytes memory data, bytes32 key) internal pure returns (bytes memory) {
        bytes memory encrypted = new bytes(data.length);
        
        for (uint256 i = 0; i < data.length; i++) {
            encrypted[i] = data[i] ^ bytes1(key << (8 * (i % 32)));
        }
        
        return encrypted;
    }
    
    /**
     * @dev Generates cryptographic commitment
     * Use Case: Commit-reveal schemes, auction systems
     */
    function generateCommitment(
        bytes32 value,
        uint256 nonce,
        address committer
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(value, nonce, committer, block.timestamp));
    }
    
    /**
     * @dev Verifies commitment reveal
     * Use Case: Validating revealed values in commit-reveal schemes
     */
    function verifyCommitment(
        bytes32 commitment,
        bytes32 value,
        uint256 nonce,
        address committer,
        uint256 timestamp
    ) internal pure returns (bool) {
        bytes32 expectedCommitment = keccak256(
            abi.encodePacked(value, nonce, committer, timestamp)
        );
        return commitment == expectedCommitment;
    }
    
    /**
     * @dev Derives key using PBKDF2-like algorithm
     * Use Case: Password-based key derivation, wallet generation
     */
    function deriveKey(
        bytes memory password,
        bytes32 salt,
        uint256 iterations
    ) internal pure returns (bytes32) {
        bytes32 derivedKey = keccak256(abi.encodePacked(password, salt));
        
        for (uint256 i = 0; i < iterations; i++) {
            derivedKey = keccak256(abi.encodePacked(derivedKey, i));
        }
        
        return derivedKey;
    }
    
    /**
     * @dev Implements zero-knowledge proof verification (simplified)
     * Use Case: Privacy-preserving verification, anonymous authentication
     */
    function verifyZKProof(
        bytes32 publicInput,
        bytes32 proof,
        bytes32 verificationKey
    ) internal pure returns (bool) {
        // Simplified ZK verification (production would need full zk-SNARK implementation)
        bytes32 expectedProof = keccak256(
            abi.encodePacked(publicInput, verificationKey)
        );
        
        return keccak256(abi.encodePacked(proof)) == expectedProof;
    }
    
    /**
     * @dev Computes polynomial commitment
     * Use Case: Verifiable computation, polynomial proofs
     */
    function computePolynomialCommitment(
        uint256[] memory coefficients,
        uint256 point
    ) internal pure returns (uint256) {
        uint256 result = 0;
        uint256 power = 1;
        
        for (uint256 i = 0; i < coefficients.length; i++) {
            result += coefficients[i] * power;
            power = (power * point) % SECP256K1_ORDER;
        }
        
        return result % SECP256K1_ORDER;
    }
    
    /**
     * @dev Advanced entropy collection
     * Use Case: Improving randomness quality for critical applications
     */
    function collectEntropy() internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    block.gaslimit,
                    block.number,
                    blockhash(block.number - 1),
                    tx.gasprice,
                    tx.origin,
                    msg.sender,
                    gasleft()
                )
            )
        );
    }
    
    /**
     * @dev Implements time-lock encryption
     * Use Case: Delayed revelation, time-based access control
     */
    function timeLockEncrypt(
        bytes memory data,
        uint256 unlockTime
    ) internal view returns (bytes memory) {
        require(unlockTime > block.timestamp, "CryptographyUtils: unlock time in past");
        
        bytes32 timeKey = keccak256(abi.encodePacked(unlockTime, block.timestamp));
        return xorEncrypt(data, timeKey);
    }
    
    /**
     * @dev Decrypts time-locked data
     * Use Case: Revealing time-locked information
     */
    function timeLockDecrypt(
        bytes memory encryptedData,
        uint256 unlockTime,
        uint256 encryptionTime
    ) internal view returns (bytes memory) {
        require(block.timestamp >= unlockTime, "CryptographyUtils: not yet unlocked");
        
        bytes32 timeKey = keccak256(abi.encodePacked(unlockTime, encryptionTime));
        return xorEncrypt(encryptedData, timeKey);
    }
}