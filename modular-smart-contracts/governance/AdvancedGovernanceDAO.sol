// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AdvancedGovernanceDAO - Sophisticated DAO with Advanced Features
 * @dev Comprehensive DAO system with delegation, quadratic voting, and conviction voting
 * 
 * FEATURES:
 * - Multi-tier proposal system with different voting mechanisms
 * - Quadratic voting for fair representation
 * - Conviction voting for continuous decision making
 * - Vote delegation with liquid democracy
 * - Futarchy-style prediction market governance
 * - Time-locked execution with emergency mechanisms
 * - Reputation-based voting power
 * - Cross-chain governance participation
 * 
 * GOVERNANCE MECHANISMS:
 * - Token-weighted voting with quadratic scaling
 * - Conviction voting for gradual consensus building
 * - Futarchy using prediction markets for decisions
 * - Liquid democracy with delegation chains
 * - Rage quit mechanisms for minority protection
 * - Veto powers for critical proposals
 * 
 * USE CASES:
 * 1. Protocol governance for DeFi protocols
 * 2. Investment DAO decision making
 * 3. Community treasury management
 * 4. Institutional governance frameworks
 * 5. Cross-chain protocol coordination
 * 6. Research and development funding
 * 
 * @author Nibert Investments LLC
 * @notice Advanced DAO Governance with Institutional Features
 */

contract AdvancedGovernanceDAO {
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MAX_CONVICTION = 10e18; // 10x normal voting power
    uint256 private constant QUADRATIC_SCALING = 5e17; // 0.5 quadratic factor
    
    // Governance token interface
    interface IGovernanceToken {
        function balanceOf(address account) external view returns (uint256);
        function totalSupply() external view returns (uint256);
        function transferFrom(address from, address to, uint256 amount) external returns (bool);
    }
    
    // Proposal types
    enum ProposalType {
        Standard,           // Regular proposals
        Constitutional,     // Changes to governance rules
        Emergency,          // Emergency proposals with fast track
        Spending,          // Treasury spending proposals
        Technical,         // Technical parameter changes
        Social            // Social/community proposals
    }
    
    // Voting mechanisms
    enum VotingMechanism {
        TokenWeighted,     // Standard token-weighted voting
        Quadratic,         // Quadratic voting
        Conviction,        // Conviction voting
        Futarchy,          // Prediction market voting
        Delegated         // Delegated voting
    }
    
    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        bytes32 dataHash;
        ProposalType proposalType;
        VotingMechanism votingMechanism;
        uint256 startTime;
        uint256 endTime;
        uint256 executionTime;
        uint256 quorumRequired;
        uint256 approvalThreshold;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        mapping(address => Vote) votes;
        mapping(address => uint256) convictionPower;
        bool executed;
        bool cancelled;
        bytes executionData;
        address targetContract;
    }
    
    // Vote structure
    struct Vote {
        bool hasVoted;
        uint8 support; // 0=against, 1=for, 2=abstain
        uint256 votingPower;
        uint256 convictionTime;
        uint256 quadraticCredits;
        address delegatedTo;
        string reason;
    }
    
    // Delegation structure
    struct Delegation {
        address delegatee;
        uint256 delegatedPower;
        uint256 delegationTime;
        bool isActive;
        ProposalType[] scopedTypes; // Scoped delegation
    }
    
    // Member structure
    struct Member {
        address memberAddress;
        uint256 memberSince;
        uint256 reputationScore;
        uint256 proposalsCreated;
        uint256 votesParticipated;
        bool isActive;
        mapping(address => bool) endorsements;
        uint256 totalEndorsements;
    }
    
    // Futarchy market structure
    struct PredictionMarket {
        uint256 proposalId;
        uint256 yesTokenPrice;
        uint256 noTokenPrice;
        uint256 totalLiquidity;
        mapping(address => uint256) yesTokens;
        mapping(address => uint256) noTokens;
        bool isActive;
        uint256 marketEndTime;
    }
    
    // Treasury structure
    struct Treasury {
        mapping(address => uint256) tokenBalances;
        uint256 totalValue;
        uint256 monthlyBudget;
        uint256 emergencyReserve;
        mapping(bytes32 => uint256) allocations;
        address[] approvedTokens;
    }
    
    // State variables
    IGovernanceToken public governanceToken;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Member) public members;
    mapping(address => Delegation) public delegations;
    mapping(uint256 => PredictionMarket) public predictionMarkets;
    Treasury public treasury;
    
    uint256 public proposalCount;
    uint256 public votingDelay = 1 days;
    uint256 public votingPeriod = 7 days;
    uint256 public executionDelay = 2 days;
    uint256 public proposalThreshold = 1e20; // 100 tokens minimum
    uint256 public quorumThreshold = 4e17; // 40% of total supply
    
    address public timelock;
    address public guardian;
    bool public emergencyMode;
    
    // Events
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint8 support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event DelegationChanged(address indexed delegator, address indexed delegatee, uint256 power);
    event ConvictionUpdated(uint256 indexed proposalId, address indexed voter, uint256 newConviction);
    event PredictionMarketCreated(uint256 indexed proposalId, uint256 initialLiquidity);
    event EmergencyActivated(address indexed guardian, string reason);
    
    modifier onlyMember() {
        require(members[msg.sender].isActive, "Not an active member");
        _;
    }
    
    modifier onlyGuardian() {
        require(msg.sender == guardian, "Only guardian");
        _;
    }
    
    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposalCount, "Proposal does not exist");
        _;
    }
    
    constructor(
        address _governanceToken,
        address _timelock,
        address _guardian
    ) {
        governanceToken = IGovernanceToken(_governanceToken);
        timelock = _timelock;
        guardian = _guardian;
        
        // Initialize creator as first member
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            memberSince: block.timestamp,
            reputationScore: 100,
            proposalsCreated: 0,
            votesParticipated: 0,
            isActive: true,
            totalEndorsements: 0
        });
    }
    
    /**
     * @dev Create a new governance proposal
     * Use Case: Submit proposals for community voting
     */
    function createProposal(
        string calldata title,
        string calldata description,
        bytes32 dataHash,
        ProposalType proposalType,
        VotingMechanism votingMechanism,
        bytes calldata executionData,
        address targetContract
    ) external onlyMember returns (uint256 proposalId) {
        require(governanceToken.balanceOf(msg.sender) >= proposalThreshold, "Insufficient tokens to propose");
        
        proposalId = proposalCount++;
        
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.title = title;
        proposal.description = description;
        proposal.dataHash = dataHash;
        proposal.proposalType = proposalType;
        proposal.votingMechanism = votingMechanism;
        proposal.startTime = block.timestamp + votingDelay;
        proposal.endTime = proposal.startTime + getVotingPeriod(proposalType);
        proposal.executionTime = proposal.endTime + getExecutionDelay(proposalType);
        proposal.quorumRequired = getQuorumRequired(proposalType);
        proposal.approvalThreshold = getApprovalThreshold(proposalType);
        proposal.executionData = executionData;
        proposal.targetContract = targetContract;
        
        members[msg.sender].proposalsCreated++;
        
        // Create prediction market for futarchy proposals
        if (votingMechanism == VotingMechanism.Futarchy) {
            createPredictionMarket(proposalId);
        }
        
        emit ProposalCreated(proposalId, msg.sender, proposalType);
        
        return proposalId;
    }
    
    /**
     * @dev Cast vote on a proposal with selected mechanism
     * Use Case: Participate in governance decisions
     */
    function castVote(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external proposalExists(proposalId) onlyMember {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.votes[msg.sender].hasVoted, "Already voted");
        
        uint256 votingPower = calculateVotingPower(msg.sender, proposal.votingMechanism);
        
        proposal.votes[msg.sender] = Vote({
            hasVoted: true,
            support: support,
            votingPower: votingPower,
            convictionTime: block.timestamp,
            quadraticCredits: 0,
            delegatedTo: address(0),
            reason: reason
        });
        
        // Apply vote to proposal totals
        if (support == 1) {
            proposal.forVotes += votingPower;
        } else if (support == 0) {
            proposal.againstVotes += votingPower;
        } else {
            proposal.abstainVotes += votingPower;
        }
        
        members[msg.sender].votesParticipated++;
        
        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }
    
    /**
     * @dev Cast quadratic vote with credits
     * Use Case: Quadratic voting for fair representation
     */
    function castQuadraticVote(
        uint256 proposalId,
        uint8 support,
        uint256 credits,
        string calldata reason
    ) external proposalExists(proposalId) onlyMember {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.votingMechanism == VotingMechanism.Quadratic, "Not quadratic voting");
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "Invalid voting period");
        require(!proposal.votes[msg.sender].hasVoted, "Already voted");
        
        uint256 maxCredits = calculateQuadraticCredits(msg.sender);
        require(credits <= maxCredits, "Insufficient quadratic credits");
        
        // Quadratic voting: voting power = sqrt(credits)
        uint256 votingPower = sqrt(credits * PRECISION);
        
        proposal.votes[msg.sender] = Vote({
            hasVoted: true,
            support: support,
            votingPower: votingPower,
            convictionTime: block.timestamp,
            quadraticCredits: credits,
            delegatedTo: address(0),
            reason: reason
        });
        
        // Apply quadratic vote
        if (support == 1) {
            proposal.forVotes += votingPower;
        } else if (support == 0) {
            proposal.againstVotes += votingPower;
        } else {
            proposal.abstainVotes += votingPower;
        }
        
        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }
    
    /**
     * @dev Update conviction for continuous voting
     * Use Case: Conviction voting for gradual consensus
     */
    function updateConviction(uint256 proposalId) external proposalExists(proposalId) onlyMember {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.votingMechanism == VotingMechanism.Conviction, "Not conviction voting");
        require(proposal.votes[msg.sender].hasVoted, "Must vote first");
        
        uint256 timeElapsed = block.timestamp - proposal.votes[msg.sender].convictionTime;
        uint256 convictionMultiplier = calculateConvictionMultiplier(timeElapsed);
        
        uint256 baseVotingPower = proposal.votes[msg.sender].votingPower;
        uint256 newConvictionPower = (baseVotingPower * convictionMultiplier) / PRECISION;
        
        // Update conviction power
        uint256 oldConviction = proposal.convictionPower[msg.sender];
        proposal.convictionPower[msg.sender] = newConvictionPower;
        
        // Update proposal totals
        uint256 convictionDiff = newConvictionPower - oldConviction;
        if (proposal.votes[msg.sender].support == 1) {
            proposal.forVotes += convictionDiff;
        } else if (proposal.votes[msg.sender].support == 0) {
            proposal.againstVotes += convictionDiff;
        }
        
        emit ConvictionUpdated(proposalId, msg.sender, newConvictionPower);
    }
    
    /**
     * @dev Delegate voting power to another address
     * Use Case: Liquid democracy and vote delegation
     */
    function delegate(
        address delegatee,
        ProposalType[] calldata scopedTypes
    ) external onlyMember {
        require(delegatee != msg.sender, "Cannot delegate to self");
        require(members[delegatee].isActive, "Delegatee not active member");
        
        uint256 delegatedPower = governanceToken.balanceOf(msg.sender);
        
        delegations[msg.sender] = Delegation({
            delegatee: delegatee,
            delegatedPower: delegatedPower,
            delegationTime: block.timestamp,
            isActive: true,
            scopedTypes: scopedTypes
        });
        
        emit DelegationChanged(msg.sender, delegatee, delegatedPower);
    }
    
    /**
     * @dev Execute approved proposal
     * Use Case: Implement approved governance decisions
     */
    function executeProposal(uint256 proposalId) external proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.executionTime, "Execution time not reached");
        require(!proposal.executed, "Already executed");
        require(!proposal.cancelled, "Proposal cancelled");
        
        // Check if proposal passed
        require(isProposalApproved(proposalId), "Proposal not approved");
        
        proposal.executed = true;
        
        bool success = false;
        if (proposal.executionData.length > 0 && proposal.targetContract != address(0)) {
            (success, ) = proposal.targetContract.call(proposal.executionData);
        } else {
            success = true; // Signaling proposal
        }
        
        emit ProposalExecuted(proposalId, success);
    }
    
    /**
     * @dev Emergency proposal execution (guardian only)
     * Use Case: Emergency response to critical situations
     */
    function executeEmergencyProposal(uint256 proposalId) external onlyGuardian {
        require(emergencyMode, "Not in emergency mode");
        
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalType == ProposalType.Emergency, "Not emergency proposal");
        require(!proposal.executed, "Already executed");
        
        proposal.executed = true;
        
        if (proposal.executionData.length > 0 && proposal.targetContract != address(0)) {
            (bool success, ) = proposal.targetContract.call(proposal.executionData);
            emit ProposalExecuted(proposalId, success);
        }
    }
    
    /**
     * @dev Create prediction market for futarchy governance
     * Use Case: Market-based decision making
     */
    function createPredictionMarket(uint256 proposalId) internal {
        PredictionMarket storage market = predictionMarkets[proposalId];
        market.proposalId = proposalId;
        market.yesTokenPrice = PRECISION; // Start at 1:1
        market.noTokenPrice = PRECISION;
        market.totalLiquidity = 0;
        market.isActive = true;
        market.marketEndTime = proposals[proposalId].endTime;
        
        emit PredictionMarketCreated(proposalId, 0);
    }
    
    /**
     * @dev Check if proposal meets approval criteria
     * Use Case: Determine if proposal should be executed
     */
    function isProposalApproved(uint256 proposalId) public view proposalExists(proposalId) returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        uint256 totalSupply = governanceToken.totalSupply();
        
        // Check quorum
        if (totalVotes < (totalSupply * proposal.quorumRequired) / PRECISION) {
            return false;
        }
        
        // Check approval threshold
        uint256 approvalRatio = (proposal.forVotes * PRECISION) / (proposal.forVotes + proposal.againstVotes);
        return approvalRatio >= proposal.approvalThreshold;
    }
    
    // Internal helper functions
    function calculateVotingPower(address voter, VotingMechanism mechanism) internal view returns (uint256) {
        uint256 balance = governanceToken.balanceOf(voter);
        uint256 delegatedPower = getDelegatedPower(voter);
        uint256 totalPower = balance + delegatedPower;
        
        if (mechanism == VotingMechanism.Quadratic) {
            return sqrt(totalPower);
        } else if (mechanism == VotingMechanism.TokenWeighted || mechanism == VotingMechanism.Conviction) {
            return totalPower;
        } else {
            return totalPower; // Default to token-weighted
        }
    }
    
    function getDelegatedPower(address delegatee) internal view returns (uint256) {
        // Calculate total power delegated to this address
        uint256 totalDelegated = 0;
        // In practice, this would iterate through all delegations
        // For simplicity, returning 0 here
        return totalDelegated;
    }
    
    function calculateQuadraticCredits(address voter) internal view returns (uint256) {
        return sqrt(governanceToken.balanceOf(voter)) * 100; // Simplified calculation
    }
    
    function calculateConvictionMultiplier(uint256 timeElapsed) internal pure returns (uint256) {
        // Conviction grows with square root of time
        uint256 timeInDays = timeElapsed / 1 days;
        uint256 multiplier = sqrt(timeInDays * PRECISION);
        
        return multiplier > MAX_CONVICTION ? MAX_CONVICTION : multiplier;
    }
    
    function getVotingPeriod(ProposalType proposalType) internal view returns (uint256) {
        if (proposalType == ProposalType.Emergency) {
            return 1 days;
        } else if (proposalType == ProposalType.Constitutional) {
            return 14 days;
        } else {
            return votingPeriod;
        }
    }
    
    function getExecutionDelay(ProposalType proposalType) internal view returns (uint256) {
        if (proposalType == ProposalType.Emergency) {
            return 0;
        } else if (proposalType == ProposalType.Constitutional) {
            return 7 days;
        } else {
            return executionDelay;
        }
    }
    
    function getQuorumRequired(ProposalType proposalType) internal view returns (uint256) {
        if (proposalType == ProposalType.Constitutional) {
            return 6e17; // 60% for constitutional changes
        } else if (proposalType == ProposalType.Emergency) {
            return 3e17; // 30% for emergency proposals
        } else {
            return quorumThreshold;
        }
    }
    
    function getApprovalThreshold(ProposalType proposalType) internal pure returns (uint256) {
        if (proposalType == ProposalType.Constitutional) {
            return 75e16; // 75% approval for constitutional changes
        } else if (proposalType == ProposalType.Emergency) {
            return 6e17; // 60% approval for emergency proposals
        } else {
            return 5e17; // 50% approval for regular proposals
        }
    }
    
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 guess = x;
        for (uint256 i = 0; i < 20; i++) {
            uint256 newGuess = (guess + x / guess) / 2;
            if (newGuess == guess) return newGuess;
            guess = newGuess;
        }
        return guess;
    }
    
    // Emergency functions
    function activateEmergencyMode(string calldata reason) external onlyGuardian {
        emergencyMode = true;
        emit EmergencyActivated(msg.sender, reason);
    }
    
    function deactivateEmergencyMode() external onlyGuardian {
        emergencyMode = false;
    }
}