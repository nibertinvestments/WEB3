// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AtomicCrossChainSwap - Trustless Multi-Chain Asset Exchange
 * @dev Implements atomic swaps across different blockchain networks
 */

contract AtomicCrossChainSwap {
    uint256 private constant PRECISION = 1e18;
    
    struct AtomicSwap {
        uint256 swapId;
        address initiator;
        address participant;
        uint256 sourceChain;
        uint256 destinationChain;
        uint256 amount1;
        uint256 amount2;
        address token1;
        address token2;
        bytes32 hashLock;
        uint256 timelock;
        uint256 status; // 0: initiated, 1: participated, 2: redeemed, 3: refunded
    }
    
    mapping(uint256 => AtomicSwap) public swaps;
    uint256 public nextSwapId;
    
    event SwapInitiated(uint256 indexed swapId, address initiator, bytes32 hashLock);
    event SwapParticipated(uint256 indexed swapId, address participant);
    event SwapRedeemed(uint256 indexed swapId, bytes32 secret);
    event SwapRefunded(uint256 indexed swapId);
    
    function initiateSwap(
        address participant,
        uint256 destinationChain,
        uint256 amount1,
        uint256 amount2,
        address token1,
        address token2,
        bytes32 hashLock,
        uint256 timelock
    ) external returns (uint256 swapId) {
        require(timelock > block.timestamp, "Invalid timelock");
        
        swapId = nextSwapId++;
        
        swaps[swapId] = AtomicSwap({
            swapId: swapId,
            initiator: msg.sender,
            participant: participant,
            sourceChain: block.chainid,
            destinationChain: destinationChain,
            amount1: amount1,
            amount2: amount2,
            token1: token1,
            token2: token2,
            hashLock: hashLock,
            timelock: timelock,
            status: 0
        });
        
        emit SwapInitiated(swapId, msg.sender, hashLock);
        return swapId;
    }
    
    function participateSwap(uint256 swapId) external {
        AtomicSwap storage swap = swaps[swapId];
        require(swap.participant == msg.sender, "Not participant");
        require(swap.status == 0, "Invalid status");
        require(block.timestamp < swap.timelock, "Timelock expired");
        
        swap.status = 1;
        emit SwapParticipated(swapId, msg.sender);
    }
    
    function redeemSwap(uint256 swapId, bytes32 secret) external {
        AtomicSwap storage swap = swaps[swapId];
        require(swap.status == 1, "Invalid status");
        require(keccak256(abi.encodePacked(secret)) == swap.hashLock, "Invalid secret");
        require(block.timestamp < swap.timelock, "Timelock expired");
        
        swap.status = 2;
        emit SwapRedeemed(swapId, secret);
    }
    
    function refundSwap(uint256 swapId) external {
        AtomicSwap storage swap = swaps[swapId];
        require(swap.initiator == msg.sender, "Not initiator");
        require(block.timestamp >= swap.timelock, "Timelock not expired");
        require(swap.status < 2, "Already redeemed");
        
        swap.status = 3;
        emit SwapRefunded(swapId);
    }
}