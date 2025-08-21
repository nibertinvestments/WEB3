// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CrossChainIdentityVerification - Multi-Chain Identity Management
 * @dev Manages identity verification across multiple blockchain networks
 */

contract CrossChainIdentityVerification {
    struct Identity {
        bytes32 identityId;
        address owner;
        uint256[] verifiedChains;
        mapping(uint256 => bool) isVerifiedOnChain;
        uint256 reputationScore;
        uint256 creationTime;
        bool isActive;
    }
    
    mapping(bytes32 => Identity) public identities;
    mapping(address => bytes32) public userIdentities;
    
    event IdentityCreated(bytes32 indexed identityId, address owner);
    event ChainVerified(bytes32 indexed identityId, uint256 chainId);
    
    function createIdentity() external returns (bytes32 identityId) {
        require(userIdentities[msg.sender] == bytes32(0), "Identity already exists");
        
        identityId = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        
        Identity storage identity = identities[identityId];
        identity.identityId = identityId;
        identity.owner = msg.sender;
        identity.reputationScore = 100;
        identity.creationTime = block.timestamp;
        identity.isActive = true;
        
        userIdentities[msg.sender] = identityId;
        
        emit IdentityCreated(identityId, msg.sender);
        return identityId;
    }
    
    function verifyOnChain(bytes32 identityId, uint256 chainId) external {
        Identity storage identity = identities[identityId];
        require(identity.owner == msg.sender, "Not owner");
        require(!identity.isVerifiedOnChain[chainId], "Already verified");
        
        identity.isVerifiedOnChain[chainId] = true;
        identity.verifiedChains.push(chainId);
        identity.reputationScore += 10;
        
        emit ChainVerified(identityId, chainId);
    }
}