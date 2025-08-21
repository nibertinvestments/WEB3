// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title NibertDAO - Decentralized Governance for Nibert Investments
 * @dev A comprehensive DAO implementation with the following features:
 *      - Proposal creation and voting mechanisms
 *      - Token-weighted voting power
 *      - Execution delays for security
 *      - Multiple proposal types (parameter changes, funding, etc.)
 * 
 * USE CASES:
 * 1. Protocol parameter adjustments (fees, rates, limits)
 * 2. Treasury fund allocation and management
 * 3. Smart contract upgrades and deployments
 * 4. Strategic partnership decisions
 * 5. Token emission and burning policies
 * 6. Community-driven feature development
 * 
 * WHY IT WORKS:
 * - Token-weighted voting ensures stake-based governance
 * - Time delays prevent hasty decisions and allow review
 * - Quorum requirements ensure sufficient participation
 * - Multiple voting options provide nuanced decision-making
 * - Emergency mechanisms protect against malicious proposals
 * 
 * @author Nibert Investments Development Team
 */

interface IGovernanceToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract NibertDAO {
    // Governance token
    IGovernanceToken public immutable governanceToken;
    
    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        address target;
        bytes callData;
        uint256 value; // ETH value for the call
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool executed;
        bool canceled;
        ProposalType proposalType;
    }
    
    enum ProposalType {
        PARAMETER_CHANGE,
        TREASURY_ALLOCATION,
        CONTRACT_UPGRADE,
        EMERGENCY_ACTION,
        GENERAL
    }
    
    enum VoteType {
        AGAINST,
        FOR,
        ABSTAIN
    }
    
    // Governance parameters
    uint256 public constant VOTING_DELAY = 1 days; // Delay before voting starts
    uint256 public constant VOTING_PERIOD = 7 days; // How long voting lasts
    uint256 public constant EXECUTION_DELAY = 2 days; // Delay before execution
    uint256 public constant PROPOSAL_THRESHOLD = 10000 * 1e18; // Min tokens to propose
    uint256 public constant QUORUM_PERCENTAGE = 10; // 10% of total supply needed
    
    // State variables
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => VoteType)) public votes;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => uint256) public delegatedVotes;
    mapping(address => address) public delegates;
    
    uint256 public proposalCount;
    uint256 public totalTokenSupply;
    address public admin;
    
    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        uint256 startTime,
        uint256 endTime
    );
    event VoteCast(address indexed voter, uint256 indexed proposalId, VoteType vote, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event DelegateChanged(address indexed delegator, address indexed delegate);
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }
    
    modifier proposalExists(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= proposalCount, "Proposal does not exist");
        _;
    }
    
    constructor(address _governanceToken, uint256 _totalTokenSupply) {
        require(_governanceToken != address(0), "Invalid token address");
        governanceToken = IGovernanceToken(_governanceToken);
        totalTokenSupply = _totalTokenSupply;
        admin = msg.sender;
    }
    
    /**
     * @dev Creates a new governance proposal
     * Use Case: Community-driven protocol improvements and decisions
     */
    function propose(
        string memory title,
        string memory description,
        address target,
        bytes memory callData,
        uint256 value,
        ProposalType proposalType
    ) external returns (uint256) {
        require(
            getVotingPower(msg.sender) >= PROPOSAL_THRESHOLD,
            "Insufficient tokens to propose"
        );
        require(bytes(title).length > 0, "Title cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        
        proposalCount++;
        uint256 proposalId = proposalCount;
        
        uint256 startTime = block.timestamp + VOTING_DELAY;
        uint256 endTime = startTime + VOTING_PERIOD;
        
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            title: title,
            description: description,
            target: target,
            callData: callData,
            value: value,
            startTime: startTime,
            endTime: endTime,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            executed: false,
            canceled: false,
            proposalType: proposalType
        });
        
        emit ProposalCreated(proposalId, msg.sender, title, startTime, endTime);
        return proposalId;
    }
    
    /**
     * @dev Casts a vote on a proposal
     * Use Case: Participating in governance decisions
     */
    function vote(uint256 proposalId, VoteType voteType) 
        external 
        proposalExists(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp <= proposal.endTime, "Voting has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        
        uint256 weight = getVotingPower(msg.sender);
        require(weight > 0, "No voting power");
        
        hasVoted[proposalId][msg.sender] = true;
        votes[proposalId][msg.sender] = voteType;
        
        if (voteType == VoteType.FOR) {
            proposal.forVotes += weight;
        } else if (voteType == VoteType.AGAINST) {
            proposal.againstVotes += weight;
        } else {
            proposal.abstainVotes += weight;
        }
        
        emit VoteCast(msg.sender, proposalId, voteType, weight);
    }
    
    /**
     * @dev Executes a successful proposal
     * Use Case: Implementing approved governance decisions
     */
    function execute(uint256 proposalId) external proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting still active");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Proposal canceled");
        require(
            block.timestamp >= proposal.endTime + EXECUTION_DELAY,
            "Execution delay not met"
        );
        
        // Check if proposal passed
        require(_proposalPassed(proposalId), "Proposal did not pass");
        
        proposal.executed = true;
        
        // Execute the proposal
        if (proposal.target != address(0)) {
            (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
            require(success, "Proposal execution failed");
        }
        
        emit ProposalExecuted(proposalId);
    }
    
    /**
     * @dev Cancels a proposal (only admin or proposer)
     * Use Case: Removing malicious or outdated proposals
     */
    function cancel(uint256 proposalId) external proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == admin || msg.sender == proposal.proposer,
            "Not authorized to cancel"
        );
        require(!proposal.executed, "Cannot cancel executed proposal");
        require(block.timestamp < proposal.endTime, "Voting has ended");
        
        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }
    
    /**
     * @dev Delegates voting power to another address
     * Use Case: Allowing trusted parties to vote on your behalf
     */
    function delegate(address delegatee) external {
        require(delegatee != msg.sender, "Cannot delegate to self");
        
        address oldDelegate = delegates[msg.sender];
        delegates[msg.sender] = delegatee;
        
        uint256 voterBalance = governanceToken.balanceOf(msg.sender);
        
        // Remove votes from old delegate
        if (oldDelegate != address(0)) {
            delegatedVotes[oldDelegate] -= voterBalance;
        }
        
        // Add votes to new delegate
        if (delegatee != address(0)) {
            delegatedVotes[delegatee] += voterBalance;
        }
        
        emit DelegateChanged(msg.sender, delegatee);
    }
    
    /**
     * @dev Gets the voting power of an address (including delegated votes)
     * Use Case: Determining influence in governance decisions
     */
    function getVotingPower(address account) public view returns (uint256) {
        return governanceToken.balanceOf(account) + delegatedVotes[account];
    }
    
    /**
     * @dev Checks if a proposal has passed
     */
    function _proposalPassed(uint256 proposalId) internal view returns (bool) {
        Proposal memory proposal = proposals[proposalId];
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        uint256 quorum = (totalTokenSupply * QUORUM_PERCENTAGE) / 100;
        
        // Must meet quorum and have more FOR votes than AGAINST
        return totalVotes >= quorum && proposal.forVotes > proposal.againstVotes;
    }
    
    /**
     * @dev Gets proposal details
     * Use Case: UI display, analytics, monitoring
     */
    function getProposal(uint256 proposalId) 
        external 
        view 
        proposalExists(proposalId) 
        returns (
            address proposer,
            string memory title,
            string memory description,
            uint256 startTime,
            uint256 endTime,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 abstainVotes,
            bool executed,
            bool canceled,
            ProposalType proposalType
        ) 
    {
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.startTime,
            proposal.endTime,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.abstainVotes,
            proposal.executed,
            proposal.canceled,
            proposal.proposalType
        );
    }
    
    /**
     * @dev Gets proposal voting status
     * Use Case: Real-time voting progress tracking
     */
    function getProposalStatus(uint256 proposalId) 
        external 
        view 
        proposalExists(proposalId) 
        returns (
            bool isActive,
            bool canExecute,
            bool hasPassed,
            uint256 totalVotes,
            uint256 quorumReached
        ) 
    {
        Proposal memory proposal = proposals[proposalId];
        
        isActive = block.timestamp >= proposal.startTime && 
                   block.timestamp <= proposal.endTime && 
                   !proposal.canceled;
        
        canExecute = block.timestamp > proposal.endTime + EXECUTION_DELAY && 
                     !proposal.executed && 
                     !proposal.canceled && 
                     _proposalPassed(proposalId);
        
        hasPassed = _proposalPassed(proposalId);
        totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        quorumReached = (totalTokenSupply * QUORUM_PERCENTAGE) / 100;
    }
    
    /**
     * @dev Emergency function to update admin
     */
    function updateAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
    }
    
    /**
     * @dev Allows contract to receive ETH for proposal execution
     */
    receive() external payable {}
    
    /**
     * @dev Emergency fund recovery (only admin)
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyAdmin {
        if (token == address(0)) {
            payable(admin).transfer(amount);
        } else {
            IGovernanceToken(token).transfer(admin, amount);
        }
    }
}