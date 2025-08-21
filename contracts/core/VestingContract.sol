// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title VestingContract - Token Vesting with Advanced Features
 * @dev Comprehensive token vesting system for team, investors, and community
 * 
 * USE CASES:
 * 1. Team token vesting with cliff periods
 * 2. Investor token distribution schedules
 * 3. Community reward vesting programs
 * 4. Advisor compensation vesting
 * 5. Partnership token arrangements
 * 6. Ecosystem development fund distribution
 * 
 * WHY IT WORKS:
 * - Linear and cliff vesting prevents token dumps
 * - Revocable vesting protects against bad actors
 * - Multiple beneficiary support scales with growth
 * - Emergency mechanisms handle edge cases
 * - Transparent vesting builds community trust
 * 
 * @author Nibert Investments Development Team
 */

interface IERC20Vesting {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract VestingContract {
    // Vesting schedule structure
    struct VestingSchedule {
        uint256 id;
        address beneficiary;
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        bool isRevocable;
        bool isRevoked;
        VestingType vestingType;
        string description;
    }
    
    enum VestingType {
        LINEAR,
        CLIFF_THEN_LINEAR,
        MILESTONE_BASED,
        PERFORMANCE_BASED
    }
    
    // Milestone structure for milestone-based vesting
    struct Milestone {
        uint256 scheduleId;
        string description;
        uint256 tokenAmount;
        bool isCompleted;
        uint256 completionTime;
        address verifier;
    }
    
    // Performance metrics for performance-based vesting
    struct PerformanceMetric {
        uint256 scheduleId;
        string metricName;
        uint256 targetValue;
        uint256 currentValue;
        uint256 tokenReward;
        bool isAchieved;
    }
    
    // Beneficiary information
    struct Beneficiary {
        address addr;
        string role;
        uint256 totalAllocated;
        uint256 totalClaimed;
        uint256[] scheduleIds;
        bool isActive;
    }
    
    // State variables
    IERC20Vesting public immutable token;
    address public owner;
    
    mapping(uint256 => VestingSchedule) public vestingSchedules;
    mapping(address => Beneficiary) public beneficiaries;
    mapping(uint256 => Milestone[]) public scheduleMilestones;
    mapping(uint256 => PerformanceMetric[]) public scheduleMetrics;
    mapping(address => bool) public authorizedVerifiers;
    
    uint256 public scheduleCounter;
    uint256 public totalTokensVesting;
    uint256 public totalTokensClaimed;
    
    // Events
    event VestingScheduleCreated(
        uint256 indexed scheduleId,
        address indexed beneficiary,
        uint256 totalAmount,
        VestingType vestingType
    );
    event TokensClaimed(
        uint256 indexed scheduleId,
        address indexed beneficiary,
        uint256 amount
    );
    event VestingRevoked(uint256 indexed scheduleId, uint256 revokedAmount);
    event MilestoneCompleted(uint256 indexed scheduleId, uint256 milestoneIndex);
    event PerformanceAchieved(uint256 indexed scheduleId, uint256 metricIndex);
    event BeneficiaryAdded(address indexed beneficiary, string role);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    modifier onlyAuthorizedVerifier() {
        require(authorizedVerifiers[msg.sender] || msg.sender == owner, "Not authorized verifier");
        _;
    }
    
    modifier validSchedule(uint256 scheduleId) {
        require(scheduleId > 0 && scheduleId <= scheduleCounter, "Invalid schedule ID");
        _;
    }
    
    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        token = IERC20Vesting(_token);
        owner = msg.sender;
        authorizedVerifiers[msg.sender] = true;
    }
    
    /**
     * @dev Creates a new vesting schedule
     * Use Case: Setting up token vesting for team members, investors, advisors
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration,
        bool isRevocable,
        VestingType vestingType,
        string memory description
    ) external onlyOwner returns (uint256) {
        require(beneficiary != address(0), "Invalid beneficiary");
        require(totalAmount > 0, "Amount must be greater than 0");
        require(vestingDuration > 0, "Vesting duration must be greater than 0");
        require(startTime >= block.timestamp, "Start time cannot be in the past");
        require(token.balanceOf(address(this)) >= totalTokensVesting + totalAmount, "Insufficient contract balance");
        
        scheduleCounter++;
        
        vestingSchedules[scheduleCounter] = VestingSchedule({
            id: scheduleCounter,
            beneficiary: beneficiary,
            totalAmount: totalAmount,
            claimedAmount: 0,
            startTime: startTime,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            isRevocable: isRevocable,
            isRevoked: false,
            vestingType: vestingType,
            description: description
        });
        
        // Update beneficiary information
        Beneficiary storage beneficiaryInfo = beneficiaries[beneficiary];
        if (!beneficiaryInfo.isActive) {
            beneficiaryInfo.addr = beneficiary;
            beneficiaryInfo.isActive = true;
        }
        beneficiaryInfo.totalAllocated += totalAmount;
        beneficiaryInfo.scheduleIds.push(scheduleCounter);
        
        totalTokensVesting += totalAmount;
        
        emit VestingScheduleCreated(scheduleCounter, beneficiary, totalAmount, vestingType);
        
        return scheduleCounter;
    }
    
    /**
     * @dev Adds milestones to a milestone-based vesting schedule
     * Use Case: Setting specific goals for token release
     */
    function addMilestones(
        uint256 scheduleId,
        string[] memory descriptions,
        uint256[] memory tokenAmounts
    ) external onlyOwner validSchedule(scheduleId) {
        require(descriptions.length == tokenAmounts.length, "Array length mismatch");
        require(vestingSchedules[scheduleId].vestingType == VestingType.MILESTONE_BASED, "Not milestone-based vesting");
        
        uint256 totalMilestoneTokens = 0;
        for (uint256 i = 0; i < descriptions.length; i++) {
            scheduleMilestones[scheduleId].push(Milestone({
                scheduleId: scheduleId,
                description: descriptions[i],
                tokenAmount: tokenAmounts[i],
                isCompleted: false,
                completionTime: 0,
                verifier: address(0)
            }));
            totalMilestoneTokens += tokenAmounts[i];
        }
        
        require(totalMilestoneTokens <= vestingSchedules[scheduleId].totalAmount, "Milestone tokens exceed total");
    }
    
    /**
     * @dev Adds performance metrics to a performance-based vesting schedule
     * Use Case: Linking token vesting to KPI achievement
     */
    function addPerformanceMetrics(
        uint256 scheduleId,
        string[] memory metricNames,
        uint256[] memory targetValues,
        uint256[] memory tokenRewards
    ) external onlyOwner validSchedule(scheduleId) {
        require(metricNames.length == targetValues.length && targetValues.length == tokenRewards.length, "Array length mismatch");
        require(vestingSchedules[scheduleId].vestingType == VestingType.PERFORMANCE_BASED, "Not performance-based vesting");
        
        uint256 totalRewardTokens = 0;
        for (uint256 i = 0; i < metricNames.length; i++) {
            scheduleMetrics[scheduleId].push(PerformanceMetric({
                scheduleId: scheduleId,
                metricName: metricNames[i],
                targetValue: targetValues[i],
                currentValue: 0,
                tokenReward: tokenRewards[i],
                isAchieved: false
            }));
            totalRewardTokens += tokenRewards[i];
        }
        
        require(totalRewardTokens <= vestingSchedules[scheduleId].totalAmount, "Reward tokens exceed total");
    }
    
    /**
     * @dev Claims vested tokens for a specific schedule
     * Use Case: Beneficiaries claiming their vested tokens
     */
    function claimTokens(uint256 scheduleId) external validSchedule(scheduleId) {
        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        require(msg.sender == schedule.beneficiary, "Not the beneficiary");
        require(!schedule.isRevoked, "Vesting has been revoked");
        
        uint256 claimableAmount = getClaimableAmount(scheduleId);
        require(claimableAmount > 0, "No tokens to claim");
        
        schedule.claimedAmount += claimableAmount;
        totalTokensClaimed += claimableAmount;
        totalTokensVesting -= claimableAmount;
        
        // Update beneficiary total claimed
        beneficiaries[schedule.beneficiary].totalClaimed += claimableAmount;
        
        require(token.transfer(schedule.beneficiary, claimableAmount), "Token transfer failed");
        
        emit TokensClaimed(scheduleId, schedule.beneficiary, claimableAmount);
    }
    
    /**
     * @dev Claims tokens from all eligible schedules for the caller
     * Use Case: Convenient batch claiming for beneficiaries with multiple schedules
     */
    function claimAllTokens() external {
        Beneficiary storage beneficiary = beneficiaries[msg.sender];
        require(beneficiary.isActive, "Not a beneficiary");
        
        uint256 totalClaimable = 0;
        
        for (uint256 i = 0; i < beneficiary.scheduleIds.length; i++) {
            uint256 scheduleId = beneficiary.scheduleIds[i];
            VestingSchedule storage schedule = vestingSchedules[scheduleId];
            
            if (!schedule.isRevoked) {
                uint256 claimableAmount = getClaimableAmount(scheduleId);
                
                if (claimableAmount > 0) {
                    schedule.claimedAmount += claimableAmount;
                    totalClaimable += claimableAmount;
                    
                    emit TokensClaimed(scheduleId, msg.sender, claimableAmount);
                }
            }
        }
        
        if (totalClaimable > 0) {
            beneficiary.totalClaimed += totalClaimable;
            totalTokensClaimed += totalClaimable;
            totalTokensVesting -= totalClaimable;
            
            require(token.transfer(msg.sender, totalClaimable), "Token transfer failed");
        }
    }
    
    /**
     * @dev Completes a milestone for milestone-based vesting
     * Use Case: Marking milestones as achieved to unlock tokens
     */
    function completeMilestone(uint256 scheduleId, uint256 milestoneIndex) 
        external 
        onlyAuthorizedVerifier 
        validSchedule(scheduleId) 
    {
        require(milestoneIndex < scheduleMilestones[scheduleId].length, "Invalid milestone index");
        
        Milestone storage milestone = scheduleMilestones[scheduleId][milestoneIndex];
        require(!milestone.isCompleted, "Milestone already completed");
        
        milestone.isCompleted = true;
        milestone.completionTime = block.timestamp;
        milestone.verifier = msg.sender;
        
        emit MilestoneCompleted(scheduleId, milestoneIndex);
    }
    
    /**
     * @dev Updates performance metric value
     * Use Case: Tracking KPI progress for performance-based vesting
     */
    function updatePerformanceMetric(
        uint256 scheduleId,
        uint256 metricIndex,
        uint256 newValue
    ) external onlyAuthorizedVerifier validSchedule(scheduleId) {
        require(metricIndex < scheduleMetrics[scheduleId].length, "Invalid metric index");
        
        PerformanceMetric storage metric = scheduleMetrics[scheduleId][metricIndex];
        metric.currentValue = newValue;
        
        if (newValue >= metric.targetValue && !metric.isAchieved) {
            metric.isAchieved = true;
            emit PerformanceAchieved(scheduleId, metricIndex);
        }
    }
    
    /**
     * @dev Revokes a vesting schedule
     * Use Case: Terminating vesting for departing team members
     */
    function revokeVesting(uint256 scheduleId) external onlyOwner validSchedule(scheduleId) {
        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        require(schedule.isRevocable, "Vesting is not revocable");
        require(!schedule.isRevoked, "Already revoked");
        
        uint256 claimableAmount = getClaimableAmount(scheduleId);
        uint256 revokedAmount = schedule.totalAmount - schedule.claimedAmount - claimableAmount;
        
        schedule.isRevoked = true;
        
        // Allow beneficiary to claim already vested tokens
        if (claimableAmount > 0) {
            schedule.claimedAmount += claimableAmount;
            beneficiaries[schedule.beneficiary].totalClaimed += claimableAmount;
            totalTokensClaimed += claimableAmount;
            
            require(token.transfer(schedule.beneficiary, claimableAmount), "Token transfer failed");
            emit TokensClaimed(scheduleId, schedule.beneficiary, claimableAmount);
        }
        
        // Update totals
        totalTokensVesting -= revokedAmount;
        
        emit VestingRevoked(scheduleId, revokedAmount);
    }
    
    /**
     * @dev Calculates claimable amount for a vesting schedule
     * Use Case: Determining how many tokens can be claimed
     */
    function getClaimableAmount(uint256 scheduleId) public view validSchedule(scheduleId) returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[scheduleId];
        
        if (schedule.isRevoked || block.timestamp < schedule.startTime) {
            return 0;
        }
        
        uint256 vestedAmount = getVestedAmount(scheduleId);
        return vestedAmount - schedule.claimedAmount;
    }
    
    /**
     * @dev Calculates total vested amount for a schedule
     */
    function getVestedAmount(uint256 scheduleId) public view validSchedule(scheduleId) returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[scheduleId];
        
        if (block.timestamp < schedule.startTime || schedule.isRevoked) {
            return 0;
        }
        
        if (schedule.vestingType == VestingType.LINEAR) {
            return _calculateLinearVesting(schedule);
        } else if (schedule.vestingType == VestingType.CLIFF_THEN_LINEAR) {
            return _calculateCliffThenLinearVesting(schedule);
        } else if (schedule.vestingType == VestingType.MILESTONE_BASED) {
            return _calculateMilestoneVesting(scheduleId);
        } else if (schedule.vestingType == VestingType.PERFORMANCE_BASED) {
            return _calculatePerformanceVesting(scheduleId);
        }
        
        return 0;
    }
    
    /**
     * @dev Calculates linear vesting amount
     */
    function _calculateLinearVesting(VestingSchedule memory schedule) internal view returns (uint256) {
        uint256 elapsed = block.timestamp - schedule.startTime;
        
        if (elapsed >= schedule.vestingDuration) {
            return schedule.totalAmount;
        }
        
        return (schedule.totalAmount * elapsed) / schedule.vestingDuration;
    }
    
    /**
     * @dev Calculates cliff then linear vesting amount
     */
    function _calculateCliffThenLinearVesting(VestingSchedule memory schedule) internal view returns (uint256) {
        uint256 elapsed = block.timestamp - schedule.startTime;
        
        if (elapsed < schedule.cliffDuration) {
            return 0;
        }
        
        if (elapsed >= schedule.vestingDuration) {
            return schedule.totalAmount;
        }
        
        uint256 vestingElapsed = elapsed - schedule.cliffDuration;
        uint256 linearDuration = schedule.vestingDuration - schedule.cliffDuration;
        
        return (schedule.totalAmount * vestingElapsed) / linearDuration;
    }
    
    /**
     * @dev Calculates milestone-based vesting amount
     */
    function _calculateMilestoneVesting(uint256 scheduleId) internal view returns (uint256) {
        Milestone[] memory milestones = scheduleMilestones[scheduleId];
        uint256 vestedAmount = 0;
        
        for (uint256 i = 0; i < milestones.length; i++) {
            if (milestones[i].isCompleted) {
                vestedAmount += milestones[i].tokenAmount;
            }
        }
        
        return vestedAmount;
    }
    
    /**
     * @dev Calculates performance-based vesting amount
     */
    function _calculatePerformanceVesting(uint256 scheduleId) internal view returns (uint256) {
        PerformanceMetric[] memory metrics = scheduleMetrics[scheduleId];
        uint256 vestedAmount = 0;
        
        for (uint256 i = 0; i < metrics.length; i++) {
            if (metrics[i].isAchieved) {
                vestedAmount += metrics[i].tokenReward;
            }
        }
        
        return vestedAmount;
    }
    
    /**
     * @dev Gets beneficiary information
     * Use Case: Dashboard display, analytics
     */
    function getBeneficiaryInfo(address beneficiary) 
        external 
        view 
        returns (
            string memory role,
            uint256 totalAllocated,
            uint256 totalClaimed,
            uint256 totalClaimable,
            uint256[] memory scheduleIds
        ) 
    {
        Beneficiary memory beneficiaryInfo = beneficiaries[beneficiary];
        
        uint256 claimableAmount = 0;
        for (uint256 i = 0; i < beneficiaryInfo.scheduleIds.length; i++) {
            claimableAmount += getClaimableAmount(beneficiaryInfo.scheduleIds[i]);
        }
        
        return (
            beneficiaryInfo.role,
            beneficiaryInfo.totalAllocated,
            beneficiaryInfo.totalClaimed,
            claimableAmount,
            beneficiaryInfo.scheduleIds
        );
    }
    
    /**
     * @dev Gets schedule milestones
     */
    function getScheduleMilestones(uint256 scheduleId) 
        external 
        view 
        validSchedule(scheduleId) 
        returns (
            string[] memory descriptions,
            uint256[] memory tokenAmounts,
            bool[] memory completionStatus
        ) 
    {
        Milestone[] memory milestones = scheduleMilestones[scheduleId];
        
        descriptions = new string[](milestones.length);
        tokenAmounts = new uint256[](milestones.length);
        completionStatus = new bool[](milestones.length);
        
        for (uint256 i = 0; i < milestones.length; i++) {
            descriptions[i] = milestones[i].description;
            tokenAmounts[i] = milestones[i].tokenAmount;
            completionStatus[i] = milestones[i].isCompleted;
        }
    }
    
    /**
     * @dev Gets schedule performance metrics
     */
    function getScheduleMetrics(uint256 scheduleId) 
        external 
        view 
        validSchedule(scheduleId) 
        returns (
            string[] memory metricNames,
            uint256[] memory targetValues,
            uint256[] memory currentValues,
            uint256[] memory tokenRewards,
            bool[] memory achievementStatus
        ) 
    {
        PerformanceMetric[] memory metrics = scheduleMetrics[scheduleId];
        
        metricNames = new string[](metrics.length);
        targetValues = new uint256[](metrics.length);
        currentValues = new uint256[](metrics.length);
        tokenRewards = new uint256[](metrics.length);
        achievementStatus = new bool[](metrics.length);
        
        for (uint256 i = 0; i < metrics.length; i++) {
            metricNames[i] = metrics[i].metricName;
            targetValues[i] = metrics[i].targetValue;
            currentValues[i] = metrics[i].currentValue;
            tokenRewards[i] = metrics[i].tokenReward;
            achievementStatus[i] = metrics[i].isAchieved;
        }
    }
    
    // Owner functions
    
    /**
     * @dev Adds authorized verifier
     */
    function addVerifier(address verifier) external onlyOwner {
        authorizedVerifiers[verifier] = true;
    }
    
    /**
     * @dev Removes authorized verifier
     */
    function removeVerifier(address verifier) external onlyOwner {
        authorizedVerifiers[verifier] = false;
    }
    
    /**
     * @dev Sets beneficiary role
     */
    function setBeneficiaryRole(address beneficiary, string memory role) external onlyOwner {
        beneficiaries[beneficiary].role = role;
    }
    
    /**
     * @dev Emergency withdrawal of unvested tokens
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        uint256 availableBalance = token.balanceOf(address(this)) - totalTokensVesting;
        require(amount <= availableBalance, "Amount exceeds available balance");
        
        require(token.transfer(owner, amount), "Transfer failed");
    }
    
    /**
     * @dev Gets contract statistics
     */
    function getContractStats() 
        external 
        view 
        returns (
            uint256 totalSchedules,
            uint256 tokensVesting,
            uint256 tokensClaimed,
            uint256 contractBalance
        ) 
    {
        return (
            scheduleCounter,
            totalTokensVesting,
            totalTokensClaimed,
            token.balanceOf(address(this))
        );
    }
    
    /**
     * @dev Transfers ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }
}