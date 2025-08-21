// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CrossChainGovernance - Decentralized Multi-Chain Governance
 * @dev Implements governance across multiple blockchain networks
 */

contract CrossChainGovernance {
    struct Proposal {
        uint256 proposalId;
        string description;
        uint256[] targetChains;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
        address proposer;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public nextProposalId;
    
    event ProposalCreated(uint256 indexed proposalId, address proposer);
    event VoteCast(uint256 indexed proposalId, address voter, bool support);
    
    function createProposal(
        string calldata description,
        uint256[] calldata targetChains,
        uint256 votingPeriod
    ) external returns (uint256 proposalId) {
        proposalId = nextProposalId++;
        
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            description: description,
            targetChains: targetChains,
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + votingPeriod,
            executed: false,
            proposer: msg.sender
        });
        
        emit ProposalCreated(proposalId, msg.sender);
        return proposalId;
    }
    
    function vote(uint256 proposalId, bool support) external {
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(block.timestamp < proposals[proposalId].deadline, "Voting ended");
        
        hasVoted[proposalId][msg.sender] = true;
        
        if (support) {
            proposals[proposalId].votesFor++;
        } else {
            proposals[proposalId].votesAgainst++;
        }
        
        emit VoteCast(proposalId, msg.sender, support);
    }
}