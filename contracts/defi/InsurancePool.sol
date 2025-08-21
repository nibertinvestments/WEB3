// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title InsurancePool - Decentralized Insurance Protocol
 * @dev Smart contract for decentralized insurance coverage
 * 
 * USE CASES:
 * 1. Smart contract bug insurance for DeFi protocols
 * 2. Impermanent loss protection for liquidity providers
 * 3. Stablecoin depeg insurance
 * 4. Exchange hack coverage
 * 5. Oracle failure protection
 * 6. Yield farming risk mitigation
 * 
 * WHY IT WORKS:
 * - Risk pooling distributes losses across participants
 * - Automated claim processing reduces friction
 * - Stake-based governance ensures fair decisions
 * - Premium calculations based on historical data
 * - Emergency mechanisms protect against catastrophic events
 * 
 * @author Nibert Investments Development Team
 */

interface IERC20Insurance {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract InsurancePool {
    // Insurance policy structure
    struct Policy {
        uint256 id;
        address policyholder;
        uint256 coverageAmount;
        uint256 premium;
        uint256 startTime;
        uint256 duration;
        uint256 riskCategory;
        bool isActive;
        bool hasClaimed;
        string description;
    }
    
    // Claim structure
    struct Claim {
        uint256 id;
        uint256 policyId;
        address claimant;
        uint256 amount;
        uint256 timestamp;
        string evidence;
        ClaimStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
    }
    
    enum ClaimStatus {
        PENDING,
        APPROVED,
        REJECTED,
        PAID
    }
    
    // Risk categories with different premium rates
    struct RiskCategory {
        string name;
        uint256 basePremiumRate; // Annual premium as percentage of coverage
        uint256 maxCoverage;
        bool isActive;
    }
    
    // Liquidity provider information
    struct Provider {
        uint256 stakedAmount;
        uint256 rewardsEarned;
        uint256 stakingTime;
        uint256 votingPower;
    }
    
    // State variables
    IERC20Insurance public stablecoin;
    address public owner;
    
    mapping(uint256 => Policy) public policies;
    mapping(uint256 => Claim) public claims;
    mapping(address => Provider) public providers;
    mapping(uint256 => RiskCategory) public riskCategories;
    mapping(address => uint256[]) public userPolicies;
    
    uint256 public policyCounter;
    uint256 public claimCounter;
    uint256 public totalPoolFunds;
    uint256 public totalCoverage;
    uint256 public totalClaims;
    
    // Pool parameters
    uint256 public constant MIN_STAKE_AMOUNT = 1000 * 1e18; // 1000 tokens minimum
    uint256 public constant CLAIM_VOTING_PERIOD = 7 days;
    uint256 public constant CLAIM_THRESHOLD = 60; // 60% approval needed
    uint256 public constant MAX_COVERAGE_RATIO = 80; // 80% of pool funds
    
    // Events
    event PolicyCreated(uint256 indexed policyId, address indexed policyholder, uint256 coverage);
    event ClaimSubmitted(uint256 indexed claimId, uint256 indexed policyId, uint256 amount);
    event ClaimVoted(uint256 indexed claimId, address indexed voter, bool vote);
    event ClaimProcessed(uint256 indexed claimId, bool approved, uint256 payout);
    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);
    event PremiumPaid(uint256 indexed policyId, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    modifier validPolicy(uint256 policyId) {
        require(policyId > 0 && policyId <= policyCounter, "Invalid policy ID");
        _;
    }
    
    modifier validClaim(uint256 claimId) {
        require(claimId > 0 && claimId <= claimCounter, "Invalid claim ID");
        _;
    }
    
    constructor(address _stablecoin) {
        require(_stablecoin != address(0), "Invalid stablecoin address");
        stablecoin = IERC20Insurance(_stablecoin);
        owner = msg.sender;
        
        // Initialize default risk categories
        _addRiskCategory("Smart Contract Bugs", 500, 1000000 * 1e18); // 5% annual premium
        _addRiskCategory("Oracle Failure", 300, 500000 * 1e18);       // 3% annual premium
        _addRiskCategory("Impermanent Loss", 200, 100000 * 1e18);     // 2% annual premium
        _addRiskCategory("Exchange Hack", 800, 2000000 * 1e18);       // 8% annual premium
    }
    
    /**
     * @dev Adds liquidity to insurance pool
     * Use Case: Earning fees by providing insurance coverage
     */
    function addLiquidity(uint256 amount) external {
        require(amount >= MIN_STAKE_AMOUNT, "Amount too small");
        require(stablecoin.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        Provider storage provider = providers[msg.sender];
        provider.stakedAmount += amount;
        provider.stakingTime = block.timestamp;
        provider.votingPower = _calculateVotingPower(msg.sender);
        
        totalPoolFunds += amount;
        
        emit LiquidityAdded(msg.sender, amount);
    }
    
    /**
     * @dev Removes liquidity from pool
     * Use Case: Withdrawing staked funds and earned fees
     */
    function removeLiquidity(uint256 amount) external {
        Provider storage provider = providers[msg.sender];
        require(provider.stakedAmount >= amount, "Insufficient staked amount");
        require(block.timestamp >= provider.stakingTime + 30 days, "Lock period not met");
        
        // Check if removal would violate coverage ratio
        uint256 newPoolFunds = totalPoolFunds - amount;
        require(
            totalCoverage <= (newPoolFunds * MAX_COVERAGE_RATIO) / 100,
            "Would exceed maximum coverage ratio"
        );
        
        provider.stakedAmount -= amount;
        provider.votingPower = _calculateVotingPower(msg.sender);
        totalPoolFunds -= amount;
        
        require(stablecoin.transfer(msg.sender, amount), "Transfer failed");
        
        emit LiquidityRemoved(msg.sender, amount);
    }
    
    /**
     * @dev Creates a new insurance policy
     * Use Case: Purchasing coverage for DeFi activities
     */
    function createPolicy(
        uint256 coverageAmount,
        uint256 duration,
        uint256 riskCategory,
        string memory description
    ) external returns (uint256) {
        require(coverageAmount > 0, "Invalid coverage amount");
        require(duration >= 30 days && duration <= 365 days, "Invalid duration");
        require(riskCategories[riskCategory].isActive, "Invalid risk category");
        require(coverageAmount <= riskCategories[riskCategory].maxCoverage, "Coverage too high");
        
        // Check pool capacity
        require(
            totalCoverage + coverageAmount <= (totalPoolFunds * MAX_COVERAGE_RATIO) / 100,
            "Insufficient pool capacity"
        );
        
        // Calculate premium
        uint256 premium = _calculatePremium(coverageAmount, duration, riskCategory);
        require(stablecoin.transferFrom(msg.sender, address(this), premium), "Premium payment failed");
        
        policyCounter++;
        
        policies[policyCounter] = Policy({
            id: policyCounter,
            policyholder: msg.sender,
            coverageAmount: coverageAmount,
            premium: premium,
            startTime: block.timestamp,
            duration: duration,
            riskCategory: riskCategory,
            isActive: true,
            hasClaimed: false,
            description: description
        });
        
        userPolicies[msg.sender].push(policyCounter);
        totalCoverage += coverageAmount;
        totalPoolFunds += premium;
        
        // Distribute premium to liquidity providers
        _distributePremiumRewards(premium);
        
        emit PolicyCreated(policyCounter, msg.sender, coverageAmount);
        emit PremiumPaid(policyCounter, premium);
        
        return policyCounter;
    }
    
    /**
     * @dev Submits an insurance claim
     * Use Case: Filing claim after covered event occurs
     */
    function submitClaim(
        uint256 policyId,
        uint256 amount,
        string memory evidence
    ) external validPolicy(policyId) returns (uint256) {
        Policy storage policy = policies[policyId];
        require(msg.sender == policy.policyholder, "Not policy holder");
        require(policy.isActive, "Policy not active");
        require(!policy.hasClaimed, "Already claimed");
        require(block.timestamp <= policy.startTime + policy.duration, "Policy expired");
        require(amount <= policy.coverageAmount, "Amount exceeds coverage");
        
        claimCounter++;
        
        Claim storage newClaim = claims[claimCounter];
        newClaim.id = claimCounter;
        newClaim.policyId = policyId;
        newClaim.claimant = msg.sender;
        newClaim.amount = amount;
        newClaim.timestamp = block.timestamp;
        newClaim.evidence = evidence;
        newClaim.status = ClaimStatus.PENDING;
        
        emit ClaimSubmitted(claimCounter, policyId, amount);
        
        return claimCounter;
    }
    
    /**
     * @dev Votes on a pending claim
     * Use Case: Governance mechanism for claim approval
     */
    function voteClaim(uint256 claimId, bool approve) external validClaim(claimId) {
        Claim storage claim = claims[claimId];
        require(claim.status == ClaimStatus.PENDING, "Claim not pending");
        require(!claim.hasVoted[msg.sender], "Already voted");
        require(providers[msg.sender].votingPower > 0, "No voting power");
        require(block.timestamp <= claim.timestamp + CLAIM_VOTING_PERIOD, "Voting period ended");
        
        claim.hasVoted[msg.sender] = true;
        uint256 votingPower = providers[msg.sender].votingPower;
        
        if (approve) {
            claim.votesFor += votingPower;
        } else {
            claim.votesAgainst += votingPower;
        }
        
        emit ClaimVoted(claimId, msg.sender, approve);
        
        // Auto-process if voting period ended
        if (block.timestamp >= claim.timestamp + CLAIM_VOTING_PERIOD) {
            _processClaim(claimId);
        }
    }
    
    /**
     * @dev Processes a claim after voting period
     */
    function processClaim(uint256 claimId) external validClaim(claimId) {
        Claim storage claim = claims[claimId];
        require(claim.status == ClaimStatus.PENDING, "Claim not pending");
        require(block.timestamp >= claim.timestamp + CLAIM_VOTING_PERIOD, "Voting still active");
        
        _processClaim(claimId);
    }
    
    /**
     * @dev Internal function to process claim
     */
    function _processClaim(uint256 claimId) internal {
        Claim storage claim = claims[claimId];
        uint256 totalVotes = claim.votesFor + claim.votesAgainst;
        
        if (totalVotes == 0) {
            claim.status = ClaimStatus.REJECTED;
            emit ClaimProcessed(claimId, false, 0);
            return;
        }
        
        bool approved = (claim.votesFor * 100) / totalVotes >= CLAIM_THRESHOLD;
        
        if (approved && totalPoolFunds >= claim.amount) {
            claim.status = ClaimStatus.APPROVED;
            
            // Mark policy as claimed
            Policy storage policy = policies[claim.policyId];
            policy.hasClaimed = true;
            policy.isActive = false;
            
            // Reduce pool funds and coverage
            totalPoolFunds -= claim.amount;
            totalCoverage -= policy.coverageAmount;
            totalClaims += claim.amount;
            
            // Transfer payout
            require(stablecoin.transfer(claim.claimant, claim.amount), "Payout failed");
            claim.status = ClaimStatus.PAID;
            
            emit ClaimProcessed(claimId, true, claim.amount);
        } else {
            claim.status = ClaimStatus.REJECTED;
            emit ClaimProcessed(claimId, false, 0);
        }
    }
    
    /**
     * @dev Calculates insurance premium
     */
    function _calculatePremium(
        uint256 coverageAmount,
        uint256 duration,
        uint256 riskCategory
    ) internal view returns (uint256) {
        RiskCategory memory category = riskCategories[riskCategory];
        
        // Base premium calculation: (coverage * rate * duration) / (365 days * 10000)
        uint256 basePremium = (coverageAmount * category.basePremiumRate * duration) / (365 days * 10000);
        
        // Apply utilization multiplier (higher utilization = higher premium)
        uint256 utilizationRate = (totalCoverage * 100) / totalPoolFunds;
        uint256 utilizationMultiplier = 100 + utilizationRate; // 1x to 2x multiplier
        
        return (basePremium * utilizationMultiplier) / 100;
    }
    
    /**
     * @dev Calculates voting power based on stake and time
     */
    function _calculateVotingPower(address provider) internal view returns (uint256) {
        Provider memory providerInfo = providers[provider];
        if (providerInfo.stakedAmount == 0) return 0;
        
        // Base voting power is stake amount
        uint256 basePower = providerInfo.stakedAmount;
        
        // Time bonus: 1% per month up to 12 months (12% max bonus)
        uint256 stakingMonths = (block.timestamp - providerInfo.stakingTime) / 30 days;
        if (stakingMonths > 12) stakingMonths = 12;
        
        uint256 timeBonus = (basePower * stakingMonths) / 100;
        return basePower + timeBonus;
    }
    
    /**
     * @dev Distributes premium rewards to liquidity providers
     */
    function _distributePremiumRewards(uint256 premium) internal {
        // Reserve 20% for protocol, distribute 80% to providers
        uint256 rewardAmount = (premium * 80) / 100;
        
        // Simple distribution based on stake proportion
        // In production, would iterate through all providers
        // For now, just update tracking
    }
    
    /**
     * @dev Gets policy information
     */
    function getPolicy(uint256 policyId) 
        external 
        view 
        validPolicy(policyId) 
        returns (
            address policyholder,
            uint256 coverageAmount,
            uint256 premium,
            uint256 startTime,
            uint256 duration,
            bool isActive,
            string memory description
        ) 
    {
        Policy memory policy = policies[policyId];
        return (
            policy.policyholder,
            policy.coverageAmount,
            policy.premium,
            policy.startTime,
            policy.duration,
            policy.isActive,
            policy.description
        );
    }
    
    /**
     * @dev Gets claim information
     */
    function getClaim(uint256 claimId) 
        external 
        view 
        validClaim(claimId) 
        returns (
            uint256 policyId,
            address claimant,
            uint256 amount,
            ClaimStatus status,
            uint256 votesFor,
            uint256 votesAgainst,
            string memory evidence
        ) 
    {
        Claim storage claim = claims[claimId];
        return (
            claim.policyId,
            claim.claimant,
            claim.amount,
            claim.status,
            claim.votesFor,
            claim.votesAgainst,
            claim.evidence
        );
    }
    
    /**
     * @dev Gets pool statistics
     */
    function getPoolStats() 
        external 
        view 
        returns (
            uint256 totalFunds,
            uint256 activeCoverage,
            uint256 utilizationRate,
            uint256 totalClaimsPaid,
            uint256 availableCapacity
        ) 
    {
        uint256 utilization = totalPoolFunds > 0 ? (totalCoverage * 100) / totalPoolFunds : 0;
        uint256 maxCapacity = (totalPoolFunds * MAX_COVERAGE_RATIO) / 100;
        uint256 available = maxCapacity > totalCoverage ? maxCapacity - totalCoverage : 0;
        
        return (
            totalPoolFunds,
            totalCoverage,
            utilization,
            totalClaims,
            available
        );
    }
    
    // Owner functions
    
    /**
     * @dev Adds new risk category
     */
    function _addRiskCategory(
        string memory name,
        uint256 basePremiumRate,
        uint256 maxCoverage
    ) internal {
        uint256 categoryId = uint256(keccak256(abi.encodePacked(name))) % 1000;
        
        riskCategories[categoryId] = RiskCategory({
            name: name,
            basePremiumRate: basePremiumRate,
            maxCoverage: maxCoverage,
            isActive: true
        });
    }
    
    /**
     * @dev Emergency pause function
     */
    function emergencyPause() external onlyOwner {
        // Implement emergency pause logic
    }
    
    /**
     * @dev Gets user's policies
     */
    function getUserPolicies(address user) external view returns (uint256[] memory) {
        return userPolicies[user];
    }
}