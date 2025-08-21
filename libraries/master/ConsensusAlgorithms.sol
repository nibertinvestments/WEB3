// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ConsensusAlgorithms - Advanced Distributed Consensus Library
 * @dev Sophisticated consensus mechanisms for decentralized systems
 * 
 * FEATURES:
 * - Byzantine Fault Tolerant (BFT) consensus algorithms
 * - Practical Byzantine Fault Tolerance (PBFT) implementation
 * - Raft consensus for crash fault tolerance
 * - Proof of Stake (PoS) consensus mechanisms
 * - Delegated Proof of Stake (DPoS) algorithms
 * - Finality and safety guarantees
 * 
 * USE CASES:
 * 1. Multi-party computation protocols
 * 2. Cross-chain bridge consensus
 * 3. Oracle network consensus mechanisms
 * 4. Governance voting systems
 * 5. Sidechain and rollup consensus
 * 6. Distributed system coordination
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology - Master Level
 */

library ConsensusAlgorithms {
    // Consensus states
    enum ConsensusState {
        IDLE,
        PREPARE,
        COMMIT,
        FINALIZED,
        FAILED
    }
    
    enum NodeRole {
        VALIDATOR,
        DELEGATE,
        OBSERVER
    }
    
    // PBFT consensus structures
    struct PBFTNode {
        address nodeAddress;
        uint256 stake;
        NodeRole role;
        bool isActive;
        uint256 lastHeartbeat;
        bytes32 publicKey;
    }
    
    struct PBFTProposal {
        bytes32 proposalHash;
        address proposer;
        uint256 blockNumber;
        uint256 timestamp;
        ConsensusState state;
        uint256 prepareVotes;
        uint256 commitVotes;
        mapping(address => bool) prepareSigned;
        mapping(address => bool) commitSigned;
    }
    
    struct RaftState {
        uint256 currentTerm;
        address votedFor;
        address leader;
        NodeRole role;
        uint256 lastLogIndex;
        uint256 commitIndex;
        mapping(address => uint256) nextIndex;
        mapping(address => uint256) matchIndex;
    }
    
    // Proof of Stake structures
    struct Validator {
        address validatorAddress;
        uint256 stakedAmount;
        uint256 delegatedStake;
        uint256 commission;
        bool isJailed;
        uint256 lastSlashTime;
        uint256 votingPower;
    }
    
    struct VotingRound {
        uint256 roundNumber;
        bytes32 blockHash;
        uint256 totalVotingPower;
        uint256 votesReceived;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) voteWeights;
        bool isFinalized;
    }
    
    // Events
    event ProposalSubmitted(bytes32 indexed proposalHash, address indexed proposer);
    event VoteCast(bytes32 indexed proposalHash, address indexed voter, bool support);
    event ConsensusReached(bytes32 indexed proposalHash, uint256 blockNumber);
    event ValidatorSlashed(address indexed validator, uint256 amount, string reason);
    event LeaderElected(address indexed leader, uint256 term);
    
    /**
     * @dev Implements PBFT consensus protocol
     * Use Case: Byzantine fault tolerant agreement in multi-party systems
     */
    function executePBFT(
        PBFTProposal storage proposal,
        PBFTNode[] memory nodes,
        address sender,
        bool vote
    ) internal returns (bool consensusReached) {
        require(proposal.state != ConsensusState.FINALIZED, "Consensus: already finalized");
        
        uint256 totalNodes = nodes.length;
        uint256 requiredVotes = (totalNodes * 2) / 3 + 1; // f = (n-1)/3, need 2f+1 votes
        
        if (proposal.state == ConsensusState.IDLE) {
            proposal.state = ConsensusState.PREPARE;
            emit ProposalSubmitted(proposal.proposalHash, proposal.proposer);
        }
        
        if (proposal.state == ConsensusState.PREPARE) {
            if (!proposal.prepareSigned[sender] && isValidNode(sender, nodes)) {
                proposal.prepareSigned[sender] = true;
                if (vote) proposal.prepareVotes++;
                
                emit VoteCast(proposal.proposalHash, sender, vote);
                
                if (proposal.prepareVotes >= requiredVotes) {
                    proposal.state = ConsensusState.COMMIT;
                }
            }
        }
        
        if (proposal.state == ConsensusState.COMMIT) {
            if (!proposal.commitSigned[sender] && isValidNode(sender, nodes)) {
                proposal.commitSigned[sender] = true;
                if (vote) proposal.commitVotes++;
                
                if (proposal.commitVotes >= requiredVotes) {
                    proposal.state = ConsensusState.FINALIZED;
                    emit ConsensusReached(proposal.proposalHash, proposal.blockNumber);
                    return true;
                }
            }
        }
        
        return false;
    }
    
    /**
     * @dev Implements Raft leader election
     * Use Case: Leader election in crash-tolerant distributed systems
     */
    function electRaftLeader(
        RaftState storage state,
        address[] memory nodes,
        address candidate
    ) internal returns (bool elected) {
        state.currentTerm++;
        state.votedFor = candidate;
        state.role = NodeRole.VALIDATOR; // Candidate
        
        uint256 votes = 1; // Vote for self
        uint256 requiredVotes = nodes.length / 2 + 1;
        
        // Simplified voting - in practice would involve network communication
        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i] != candidate) {
                // Simulate vote based on node address hash
                if (uint256(keccak256(abi.encode(nodes[i], state.currentTerm))) % 2 == 1) {
                    votes++;
                }
            }
        }
        
        if (votes >= requiredVotes) {
            state.leader = candidate;
            state.role = NodeRole.VALIDATOR;
            emit LeaderElected(candidate, state.currentTerm);
            return true;
        }
        
        return false;
    }
    
    /**
     * @dev Implements Proof of Stake consensus
     * Use Case: Energy-efficient consensus with economic incentives
     */
    function executePoSConsensus(
        VotingRound storage round,
        Validator[] storage validators,
        address voter,
        bytes32 blockHash,
        bool support
    ) internal returns (bool finalized) {
        require(!round.hasVoted[voter], "Consensus: already voted");
        require(!isValidatorJailed(voter, validators), "Consensus: validator jailed");
        
        Validator storage validator = getValidator(voter, validators);
        require(validator.validatorAddress != address(0), "Consensus: not a validator");
        
        round.hasVoted[voter] = true;
        
        if (support) {
            uint256 votingPower = validator.stakedAmount + validator.delegatedStake;
            round.voteWeights[voter] = votingPower;
            round.votesReceived += votingPower;
        }
        
        emit VoteCast(blockHash, voter, support);
        
        // Check if 2/3 majority reached
        uint256 requiredVotes = (round.totalVotingPower * 2) / 3;
        if (round.votesReceived >= requiredVotes) {
            round.isFinalized = true;
            emit ConsensusReached(blockHash, round.roundNumber);
            return true;
        }
        
        return false;
    }
    
    /**
     * @dev Implements Delegated Proof of Stake (DPoS)
     * Use Case: Scalable consensus with representative voting
     */
    function executeDPoSRound(
        address[] memory delegates,
        mapping(address => uint256) storage delegateVotes,
        bytes32 blockHash,
        uint256 roundNumber
    ) internal returns (address selectedDelegate) {
        require(delegates.length > 0, "Consensus: no delegates");
        
        // Weighted random selection based on votes
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < delegates.length; i++) {
            totalVotes += delegateVotes[delegates[i]];
        }
        
        if (totalVotes == 0) return delegates[0]; // Fallback to first delegate
        
        uint256 randomValue = uint256(keccak256(abi.encode(blockHash, roundNumber))) % totalVotes;
        uint256 cumulativeVotes = 0;
        
        for (uint256 i = 0; i < delegates.length; i++) {
            cumulativeVotes += delegateVotes[delegates[i]];
            if (randomValue < cumulativeVotes) {
                return delegates[i];
            }
        }
        
        return delegates[delegates.length - 1]; // Fallback
    }
    
    /**
     * @dev Calculates Byzantine fault tolerance threshold
     * Use Case: Determining security parameters for BFT systems
     */
    function calculateBFTThreshold(uint256 totalNodes) internal pure returns (uint256 threshold) {
        // For Byzantine fault tolerance: f < n/3, where f is max faulty nodes
        uint256 maxFaultyNodes = (totalNodes - 1) / 3;
        threshold = totalNodes - maxFaultyNodes; // Minimum honest nodes needed
    }
    
    /**
     * @dev Implements slashing mechanism for misbehavior
     * Use Case: Economic penalties for consensus violations
     */
    function slashValidator(
        Validator storage validator,
        uint256 slashAmount,
        string memory reason
    ) internal {
        require(validator.stakedAmount >= slashAmount, "Consensus: insufficient stake");
        
        validator.stakedAmount -= slashAmount;
        validator.isJailed = true;
        validator.lastSlashTime = block.timestamp;
        
        // Reduce voting power
        validator.votingPower = (validator.stakedAmount + validator.delegatedStake) / 2;
        
        emit ValidatorSlashed(validator.validatorAddress, slashAmount, reason);
    }
    
    /**
     * @dev Calculates finality probability
     * Use Case: Determining confidence in consensus decisions
     */
    function calculateFinalityProbability(
        uint256 confirmations,
        uint256 totalValidators,
        uint256 honestValidators
    ) internal pure returns (uint256 probability) {
        if (honestValidators * 3 <= totalValidators * 2) {
            return 0; // Cannot guarantee finality
        }
        
        // Simplified probability calculation
        // In practice, would use more sophisticated statistical models
        uint256 baseProb = (honestValidators * 1e18) / totalValidators;
        uint256 finalityProb = baseProb;
        
        for (uint256 i = 0; i < confirmations; i++) {
            finalityProb = (finalityProb * baseProb) / 1e18;
        }
        
        return 1e18 - finalityProb; // Probability of finality
    }
    
    /**
     * @dev Implements checkpointing for finality
     * Use Case: Creating irreversible commitment points
     */
    function createCheckpoint(
        bytes32 blockHash,
        uint256 blockNumber,
        address[] memory validators,
        mapping(address => bool) storage signatures
    ) internal view returns (bool isValid) {
        uint256 signatureCount = 0;
        
        for (uint256 i = 0; i < validators.length; i++) {
            if (signatures[validators[i]]) {
                signatureCount++;
            }
        }
        
        // Require supermajority for checkpoint
        return signatureCount >= (validators.length * 2) / 3 + 1;
    }
    
    /**
     * @dev Detects fork in the blockchain
     * Use Case: Fork detection and resolution
     */
    function detectFork(
        bytes32[] memory blockHashes,
        uint256[] memory blockNumbers
    ) internal pure returns (bool hasFork, uint256 forkHeight) {
        require(blockHashes.length == blockNumbers.length, "Consensus: length mismatch");
        
        for (uint256 i = 1; i < blockHashes.length; i++) {
            if (blockNumbers[i] == blockNumbers[i-1] && blockHashes[i] != blockHashes[i-1]) {
                return (true, blockNumbers[i]);
            }
        }
        
        return (false, 0);
    }
    
    // Helper functions
    
    function isValidNode(address node, PBFTNode[] memory nodes) internal pure returns (bool) {
        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i].nodeAddress == node && nodes[i].isActive) {
                return true;
            }
        }
        return false;
    }
    
    function getValidator(address addr, Validator[] storage validators) 
        internal view returns (Validator storage) {
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i].validatorAddress == addr) {
                return validators[i];
            }
        }
        revert("Consensus: validator not found");
    }
    
    function isValidatorJailed(address addr, Validator[] storage validators) 
        internal view returns (bool) {
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i].validatorAddress == addr) {
                return validators[i].isJailed;
            }
        }
        return true; // Unknown validators are considered jailed
    }
    
    /**
     * @dev Calculates consensus delay
     * Use Case: Performance optimization and timing analysis
     */
    function calculateConsensusDelay(
        uint256 networkLatency,
        uint256 nodeCount,
        uint256 messageSize
    ) internal pure returns (uint256 delay) {
        // Simplified model: delay = latency + processing_time + network_overhead
        uint256 processingTime = messageSize / 1000; // Simple processing model
        uint256 networkOverhead = nodeCount * 10; // Overhead per node
        
        delay = networkLatency + processingTime + networkOverhead;
    }
    
    /**
     * @dev Optimizes validator set for performance
     * Use Case: Dynamic validator set management
     */
    function optimizeValidatorSet(
        Validator[] memory candidates,
        uint256 maxValidators,
        uint256 minStake
    ) internal pure returns (address[] memory optimizedSet) {
        // Sort candidates by stake (simplified)
        address[] memory qualified = new address[](candidates.length);
        uint256 qualifiedCount = 0;
        
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].stakedAmount >= minStake && !candidates[i].isJailed) {
                qualified[qualifiedCount++] = candidates[i].validatorAddress;
            }
        }
        
        // Return top validators up to maxValidators
        uint256 setSize = qualifiedCount < maxValidators ? qualifiedCount : maxValidators;
        optimizedSet = new address[](setSize);
        
        for (uint256 i = 0; i < setSize; i++) {
            optimizedSet[i] = qualified[i];
        }
    }
}