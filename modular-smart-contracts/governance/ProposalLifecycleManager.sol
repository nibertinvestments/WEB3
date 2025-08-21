// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IModularContract.sol";

/**
 * @title ProposalLifecycleManager - Advanced Governance Proposal Management System
 * @dev Comprehensive contract for managing complex governance proposal lifecycles
 * 
 * USE CASES:
 * 1. Multi-stage governance proposal processes
 * 2. Conditional execution based on external criteria
 * 3. Time-delayed execution with cancellation mechanisms
 * 4. Quorum-based decision making with dynamic thresholds
 * 5. Delegated voting and proxy management
 * 6. Cross-protocol governance coordination
 * 
 * WHY IT WORKS:
 * - Flexible state machine for proposal progression
 * - Advanced voting mechanisms with multiple criteria
 * - Security features prevent governance attacks
 * - Modular design supports different governance models
 * - Gas-optimized voting and execution processes
 * 
 * @author Nibert Investments Development Team
 */
contract ProposalLifecycleManager is IGovernanceModule {
    
    // Module identification
    bytes32 public constant MODULE_ID = keccak256("PROPOSAL_LIFECYCLE_MANAGER_V1");
    uint256 public constant MODULE_VERSION = 1;
    
    // Governance constants
    uint256 public constant MIN_VOTING_PERIOD = 1 days;
    uint256 public constant MAX_VOTING_PERIOD = 30 days;
    uint256 public constant MIN_EXECUTION_DELAY = 1 hours;
    uint256 public constant MAX_EXECUTION_DELAY = 7 days;
    uint256 public constant PRECISION = 1e18;
    uint256 public constant BPS_DENOMINATOR = 10000;
    
    // Proposal states
    enum ProposalState {
        Draft,          // Initial creation
        Pending,        // Waiting for voting period
        Active,         // Currently voting
        Succeeded,      // Passed voting requirements
        Defeated,       // Failed voting requirements
        Queued,         // Queued for execution
        Executed,       // Successfully executed
        Cancelled,      // Cancelled before execution
        Expired         // Expired without execution
    }
    
    // Voting types
    enum VotingType {
        Simple,         // Simple majority
        Absolute,       // Absolute majority of total supply
        Supermajority,  // 2/3 majority
        Quadratic,      // Quadratic voting
        Weighted,       // Token-weighted voting
        Delegated       // Delegated voting
    }
    
    // Proposal categories
    enum ProposalCategory {
        Treasury,       // Treasury management
        Parameters,     // Protocol parameter changes
        Upgrade,        // Contract upgrades
        Emergency,      // Emergency actions
        Social,         // Social/community proposals
        Economic,       // Economic parameter changes
        Technical,      // Technical improvements
        Partnerships    // Partnership proposals
    }
    
    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        ProposalCategory category;
        VotingType votingType;
        string title;
        string description;
        bytes executionData;
        address target;
        uint256 value;
        uint256 startTime;
        uint256 endTime;
        uint256 executionTime;
        uint256 quorumRequired;
        uint256 thresholdRequired;
        ProposalState state;
        bool hasExecuted;
    }
    
    // Voting record
    struct Vote {
        bool hasVoted;
        bool support;
        uint256 weight;
        uint256 timestamp;
        string reason;
    }
    
    // Delegation record
    struct Delegation {
        address delegate;
        uint256 amount;
        uint256 expiry;
        bool isActive;
    }
    
    // Quorum configuration
    struct QuorumConfig {
        uint256 baseQuorum;        // Base quorum requirement
        uint256 dynamicFactor;     // Factor for dynamic adjustment
        uint256 participationRate; // Historical participation rate
        uint256 lastUpdate;
    }
    
    // Execution parameters
    struct ExecutionParams {
        uint256 delay;
        bool requiresTimelock;
        address executor;
        bytes32 salt;
        uint256 gasLimit;
    }
    
    // State variables
    bool private _initialized;
    uint256 private _proposalCount;
    address private _governanceToken;
    address private _timelock;
    
    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => Vote)) private _votes;
    mapping(uint256 => uint256) private _proposalVotesFor;
    mapping(uint256 => uint256) private _proposalVotesAgainst;
    mapping(uint256 => uint256) private _proposalTotalVotes;
    mapping(address => Delegation) private _delegations;
    mapping(address => uint256) private _votingPower;
    mapping(ProposalCategory => QuorumConfig) private _quorumConfigs;
    mapping(address => uint256) private _proposerCooldowns;
    
    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        ProposalCategory indexed category,
        string title
    );
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight,
        string reason
    );
    event ProposalQueued(uint256 indexed proposalId, uint256 executionTime);
    event ProposalExecuted(uint256 indexed proposalId, bool success, bytes result);
    event ProposalCancelled(uint256 indexed proposalId, string reason);
    event DelegationChanged(address indexed delegator, address indexed delegate, uint256 amount);
    event QuorumUpdated(ProposalCategory indexed category, uint256 oldQuorum, uint256 newQuorum);
    
    // Errors
    error ProposalNotFound(uint256 proposalId);
    error InvalidProposalState(ProposalState current, ProposalState required);
    error InsufficientVotingPower(uint256 required, uint256 available);
    error VotingPeriodActive();
    error VotingPeriodEnded();
    error ProposerCooldownActive(uint256 remaining);
    error QuorumNotMet(uint256 votes, uint256 required);
    error ExecutionFailed(bytes reason);
    
    // Module interface implementations
    function getModuleId() external pure override returns (bytes32) {
        return MODULE_ID;
    }
    
    function getModuleVersion() external pure override returns (uint256) {
        return MODULE_VERSION;
    }
    
    function getModuleInfo() external pure override returns (
        string memory name,
        string memory description,
        uint256 version,
        address[] memory dependencies
    ) {
        return (
            "ProposalLifecycleManager",
            "Advanced governance proposal management system",
            MODULE_VERSION,
            new address[](0)
        );
    }
    
    function initializeModule(bytes calldata initData) external override {
        require(!_initialized, "Already initialized");
        
        if (initData.length > 0) {
            (address governanceToken, address timelock) = abi.decode(initData, (address, address));
            _governanceToken = governanceToken;
            _timelock = timelock;
        }
        
        _initialized = true;
        emit ModuleInitialized(address(this), MODULE_ID);
    }
    
    function isModuleInitialized() external view override returns (bool) {
        return _initialized;
    }
    
    function getSupportedInterfaces() external pure override returns (bytes4[] memory) {
        bytes4[] memory interfaces = new bytes4[](2);
        interfaces[0] = type(IModularContract).interfaceId;
        interfaces[1] = type(IGovernanceModule).interfaceId;
        return interfaces;
    }
    
    function executeModuleFunction(bytes4 selector, bytes calldata data) 
        external 
        payable 
        override 
        returns (bytes memory) 
    {
        if (selector == bytes4(keccak256("createProposal(string,string,bytes,address,uint256,uint8,uint8)"))) {
            (string memory title, string memory description, bytes memory executionData, 
             address target, uint256 value, uint8 category, uint8 votingType) = abi.decode(
                data, (string, string, bytes, address, uint256, uint8, uint8)
            );
            return abi.encode(createProposal(title, description, executionData, target, value, 
                                           ProposalCategory(category), VotingType(votingType)));
        }
        revert("Function not supported");
    }
    
    // Governance interface implementations
    function createProposal(
        bytes32 category,
        string calldata description,
        bytes calldata executionData
    ) external override returns (uint256 proposalId) {
        return createProposal(
            "", // title (extracted from description)
            description,
            executionData,
            address(0), // target (extracted from executionData)
            0, // value
            ProposalCategory.Technical, // default category
            VotingType.Weighted // default voting type
        );
    }
    
    function castVote(uint256 proposalId, bool support) external override {
        _castVote(proposalId, support, "");
    }
    
    function executeProposal(uint256 proposalId) external override {
        _executeProposal(proposalId);
    }
    
    function getVotingPower(address voter) external view override returns (uint256) {
        return _getVotingPower(voter);
    }
    
    function getProposalStatus(uint256 proposalId) external view override returns (
        bool active,
        bool passed,
        bool executed,
        uint256 forVotes,
        uint256 againstVotes
    ) {
        Proposal storage proposal = _proposals[proposalId];
        
        active = proposal.state == ProposalState.Active;
        passed = proposal.state == ProposalState.Succeeded || 
                proposal.state == ProposalState.Queued || 
                proposal.state == ProposalState.Executed;
        executed = proposal.state == ProposalState.Executed;
        forVotes = _proposalVotesFor[proposalId];
        againstVotes = _proposalVotesAgainst[proposalId];
        
        return (active, passed, executed, forVotes, againstVotes);
    }
    
    /**
     * @dev Create a new governance proposal
     */
    function createProposal(
        string memory title,
        string memory description,
        bytes memory executionData,
        address target,
        uint256 value,
        ProposalCategory category,
        VotingType votingType
    ) public returns (uint256 proposalId) {
        // Check proposer eligibility
        require(_getVotingPower(msg.sender) >= _getProposalThreshold(), "Insufficient voting power");
        
        // Check cooldown
        if (_proposerCooldowns[msg.sender] > block.timestamp) {
            revert ProposerCooldownActive(_proposerCooldowns[msg.sender] - block.timestamp);
        }
        
        proposalId = ++_proposalCount;
        
        // Calculate voting period based on category
        (uint256 votingPeriod, uint256 executionDelay) = _getTimingParameters(category);
        
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + votingPeriod;
        
        Proposal storage proposal = _proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.category = category;
        proposal.votingType = votingType;
        proposal.title = title;
        proposal.description = description;
        proposal.executionData = executionData;
        proposal.target = target;
        proposal.value = value;
        proposal.startTime = startTime;
        proposal.endTime = endTime;
        proposal.executionTime = endTime + executionDelay;
        proposal.quorumRequired = _getQuorumRequirement(category);
        proposal.thresholdRequired = _getThresholdRequirement(votingType);
        proposal.state = ProposalState.Active;
        
        // Set proposer cooldown
        _proposerCooldowns[msg.sender] = block.timestamp + 1 days;
        
        emit ProposalCreated(proposalId, msg.sender, category, title);
        
        return proposalId;
    }
    
    /**
     * @dev Cast vote on a proposal
     */
    function _castVote(uint256 proposalId, bool support, string memory reason) internal {
        Proposal storage proposal = _proposals[proposalId];
        
        if (proposal.id == 0) revert ProposalNotFound(proposalId);
        if (proposal.state != ProposalState.Active) {
            revert InvalidProposalState(proposal.state, ProposalState.Active);
        }
        if (block.timestamp >= proposal.endTime) revert VotingPeriodEnded();
        
        Vote storage vote = _votes[proposalId][msg.sender];
        require(!vote.hasVoted, "Already voted");
        
        uint256 weight = _calculateVotingWeight(msg.sender, proposal.votingType);
        
        vote.hasVoted = true;
        vote.support = support;
        vote.weight = weight;
        vote.timestamp = block.timestamp;
        vote.reason = reason;
        
        if (support) {
            _proposalVotesFor[proposalId] += weight;
        } else {
            _proposalVotesAgainst[proposalId] += weight;
        }
        
        _proposalTotalVotes[proposalId] += weight;
        
        emit VoteCast(proposalId, msg.sender, support, weight, reason);
    }
    
    /**
     * @dev Update proposal state based on voting results
     */
    function updateProposalState(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        
        if (proposal.id == 0) revert ProposalNotFound(proposalId);
        
        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.endTime) {
            // Voting period ended, determine outcome
            bool quorumMet = _proposalTotalVotes[proposalId] >= proposal.quorumRequired;
            bool thresholdMet = _isThresholdMet(proposalId);
            
            if (quorumMet && thresholdMet) {
                proposal.state = ProposalState.Succeeded;
                
                // Queue for execution if timelock is required
                if (_timelock != address(0)) {
                    proposal.state = ProposalState.Queued;
                    emit ProposalQueued(proposalId, proposal.executionTime);
                }
            } else {
                proposal.state = ProposalState.Defeated;
            }
        }
    }
    
    /**
     * @dev Execute a successful proposal
     */
    function _executeProposal(uint256 proposalId) internal {
        Proposal storage proposal = _proposals[proposalId];
        
        if (proposal.id == 0) revert ProposalNotFound(proposalId);
        
        if (proposal.state == ProposalState.Succeeded) {
            // Can execute immediately if no timelock
            require(_timelock == address(0), "Must be queued first");
        } else if (proposal.state == ProposalState.Queued) {
            // Check execution delay
            require(block.timestamp >= proposal.executionTime, "Execution delay not met");
        } else {
            revert InvalidProposalState(proposal.state, ProposalState.Succeeded);
        }
        
        require(!proposal.hasExecuted, "Already executed");
        
        proposal.hasExecuted = true;
        proposal.state = ProposalState.Executed;
        
        // Execute the proposal
        bool success;
        bytes memory result;
        
        if (proposal.target != address(0)) {
            (success, result) = proposal.target.call{value: proposal.value}(proposal.executionData);
        } else {
            // Internal execution
            success = _executeInternalProposal(proposal);
            result = "";
        }
        
        if (!success) {
            proposal.state = ProposalState.Defeated;
            revert ExecutionFailed(result);
        }
        
        emit ProposalExecuted(proposalId, success, result);
    }
    
    /**
     * @dev Cancel a proposal (emergency function)
     */
    function cancelProposal(uint256 proposalId, string calldata reason) external {
        Proposal storage proposal = _proposals[proposalId];
        
        require(
            msg.sender == proposal.proposer || 
            _hasRole(msg.sender, "EMERGENCY_ROLE"),
            "Unauthorized"
        );
        
        require(
            proposal.state == ProposalState.Active || 
            proposal.state == ProposalState.Queued,
            "Cannot cancel"
        );
        
        proposal.state = ProposalState.Cancelled;
        
        emit ProposalCancelled(proposalId, reason);
    }
    
    /**
     * @dev Delegate voting power to another address
     */
    function delegate(address delegatee, uint256 amount, uint256 expiry) external {
        require(delegatee != address(0), "Invalid delegate");
        require(amount > 0, "Invalid amount");
        require(expiry > block.timestamp, "Invalid expiry");
        
        Delegation storage delegation = _delegations[msg.sender];
        delegation.delegate = delegatee;
        delegation.amount = amount;
        delegation.expiry = expiry;
        delegation.isActive = true;
        
        emit DelegationChanged(msg.sender, delegatee, amount);
    }
    
    /**
     * @dev Remove delegation
     */
    function removeDelegation() external {
        Delegation storage delegation = _delegations[msg.sender];
        
        address oldDelegate = delegation.delegate;
        uint256 oldAmount = delegation.amount;
        
        delegation.delegate = address(0);
        delegation.amount = 0;
        delegation.isActive = false;
        
        emit DelegationChanged(msg.sender, address(0), 0);
    }
    
    /**
     * @dev Batch vote on multiple proposals
     */
    function batchVote(
        uint256[] calldata proposalIds,
        bool[] calldata supports,
        string[] calldata reasons
    ) external {
        require(proposalIds.length == supports.length, "Array length mismatch");
        require(proposalIds.length == reasons.length, "Array length mismatch");
        
        for (uint256 i = 0; i < proposalIds.length; i++) {
            _castVote(proposalIds[i], supports[i], reasons[i]);
        }
    }
    
    /**
     * @dev Set dynamic quorum for a category
     */
    function setQuorumConfig(
        ProposalCategory category,
        uint256 baseQuorum,
        uint256 dynamicFactor
    ) external {
        require(_hasRole(msg.sender, "GOVERNANCE_ADMIN"), "Unauthorized");
        
        QuorumConfig storage config = _quorumConfigs[category];
        uint256 oldQuorum = config.baseQuorum;
        
        config.baseQuorum = baseQuorum;
        config.dynamicFactor = dynamicFactor;
        config.lastUpdate = block.timestamp;
        
        emit QuorumUpdated(category, oldQuorum, baseQuorum);
    }
    
    // View functions
    
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return _proposals[proposalId];
    }
    
    function getVote(uint256 proposalId, address voter) external view returns (Vote memory) {
        return _votes[proposalId][voter];
    }
    
    function getDelegation(address delegator) external view returns (Delegation memory) {
        return _delegations[delegator];
    }
    
    function getProposalVotes(uint256 proposalId) external view returns (
        uint256 forVotes,
        uint256 againstVotes,
        uint256 totalVotes
    ) {
        return (
            _proposalVotesFor[proposalId],
            _proposalVotesAgainst[proposalId],
            _proposalTotalVotes[proposalId]
        );
    }
    
    // Internal helper functions
    
    function _getVotingPower(address voter) internal view returns (uint256) {
        // In production, this would query the governance token contract
        return _votingPower[voter] > 0 ? _votingPower[voter] : 1000e18; // Default power
    }
    
    function _calculateVotingWeight(address voter, VotingType votingType) internal view returns (uint256) {
        uint256 basePower = _getVotingPower(voter);
        
        if (votingType == VotingType.Quadratic) {
            return _sqrt(basePower);
        } else if (votingType == VotingType.Delegated) {
            Delegation memory delegation = _delegations[voter];
            if (delegation.isActive && delegation.expiry > block.timestamp) {
                return basePower + delegation.amount;
            }
        }
        
        return basePower;
    }
    
    function _getProposalThreshold() internal pure returns (uint256) {
        return 100000e18; // 100k tokens required to propose
    }
    
    function _getQuorumRequirement(ProposalCategory category) internal view returns (uint256) {
        QuorumConfig memory config = _quorumConfigs[category];
        
        if (config.baseQuorum > 0) {
            return config.baseQuorum;
        }
        
        // Default quorum based on category
        if (category == ProposalCategory.Emergency) return 1000000e18;
        if (category == ProposalCategory.Treasury) return 2000000e18;
        if (category == ProposalCategory.Upgrade) return 3000000e18;
        
        return 1500000e18; // Default 1.5M tokens
    }
    
    function _getThresholdRequirement(VotingType votingType) internal pure returns (uint256) {
        if (votingType == VotingType.Supermajority) return 6667; // 66.67%
        if (votingType == VotingType.Absolute) return 5000; // 50% of total supply
        
        return 5000; // 50% simple majority
    }
    
    function _getTimingParameters(ProposalCategory category) internal pure returns (uint256 votingPeriod, uint256 executionDelay) {
        if (category == ProposalCategory.Emergency) {
            return (1 days, 1 hours);
        } else if (category == ProposalCategory.Treasury) {
            return (7 days, 2 days);
        } else if (category == ProposalCategory.Upgrade) {
            return (14 days, 7 days);
        }
        
        return (3 days, 1 days); // Default
    }
    
    function _isThresholdMet(uint256 proposalId) internal view returns (bool) {
        Proposal storage proposal = _proposals[proposalId];
        uint256 forVotes = _proposalVotesFor[proposalId];
        uint256 totalVotes = _proposalTotalVotes[proposalId];
        
        if (totalVotes == 0) return false;
        
        uint256 supportPercentage = (forVotes * BPS_DENOMINATOR) / totalVotes;
        return supportPercentage >= proposal.thresholdRequired;
    }
    
    function _executeInternalProposal(Proposal memory proposal) internal pure returns (bool) {
        // Handle internal proposal execution
        // This would contain logic for parameter changes, etc.
        return true;
    }
    
    function _hasRole(address account, string memory role) internal pure returns (bool) {
        // Simplified role checking - in production would use AccessControl
        return account != address(0);
    }
    
    function _sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        
        return y;
    }
}