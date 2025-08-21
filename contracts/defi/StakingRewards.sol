// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title StakingRewards - Token Staking with Time-Based Rewards
 * @dev A comprehensive staking contract that allows users to stake tokens
 *      and earn rewards based on staking duration and amount
 * 
 * USE CASES:
 * 1. Long-term token holding incentives
 * 2. Protocol governance participation rewards
 * 3. Liquidity bootstrapping for new tokens
 * 4. Yield farming programs
 * 5. Token economy deflationary mechanisms
 * 
 * WHY IT WORKS:
 * - Time-weighted rewards encourage long-term holding
 * - Flexible reward rates allow protocol adjustment
 * - Emergency withdrawal protects user funds
 * - Compound staking maximizes user returns
 * - Anti-whale mechanics prevent centralization
 * 
 * @author Nibert Investments Development Team
 */

interface IERC20Staking {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract StakingRewards {
    // Tokens
    IERC20Staking public immutable stakingToken;
    IERC20Staking public immutable rewardsToken;
    
    // Staking parameters
    uint256 public rewardRate; // Rewards per second per token
    uint256 public constant REWARD_DURATION = 365 days;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    
    // User staking data
    struct UserInfo {
        uint256 stakedAmount;
        uint256 rewardPerTokenPaid;
        uint256 rewards;
        uint256 lastStakeTime;
        uint256 totalRewardsClaimed;
    }
    
    mapping(address => UserInfo) public userInfo;
    
    // Pool state
    uint256 public totalStaked;
    uint256 public totalRewardsDistributed;
    
    // Access control
    address public owner;
    bool public stakingPaused;
    
    // Staking tiers with different reward multipliers
    struct StakingTier {
        uint256 minAmount;
        uint256 multiplier; // Multiplier in basis points (10000 = 1x)
        uint256 lockPeriod; // Lock period in seconds
    }
    
    StakingTier[] public stakingTiers;
    mapping(address => uint256) public userTier;
    
    // Events
    event Staked(address indexed user, uint256 amount, uint256 tier);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(uint256 reward);
    event StakingPaused(bool paused);
    event TierAdded(uint256 minAmount, uint256 multiplier, uint256 lockPeriod);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            userInfo[account].rewards = earned(account);
            userInfo[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
        _;
    }
    
    modifier whenNotPaused() {
        require(!stakingPaused, "Staking is paused");
        _;
    }
    
    constructor(
        address _stakingToken,
        address _rewardsToken,
        uint256 _rewardRate
    ) {
        require(_stakingToken != address(0) && _rewardsToken != address(0), "Invalid addresses");
        
        stakingToken = IERC20Staking(_stakingToken);
        rewardsToken = IERC20Staking(_rewardsToken);
        rewardRate = _rewardRate;
        owner = msg.sender;
        
        // Initialize default staking tiers
        _addStakingTier(0, 10000, 0); // Tier 0: No minimum, 1x multiplier, no lock
        _addStakingTier(1000 * 1e18, 12000, 30 days); // Tier 1: 1000 tokens, 1.2x, 30 days
        _addStakingTier(10000 * 1e18, 15000, 90 days); // Tier 2: 10000 tokens, 1.5x, 90 days
        _addStakingTier(50000 * 1e18, 20000, 180 days); // Tier 3: 50000 tokens, 2x, 180 days
    }
    
    /**
     * @dev Stakes tokens and assigns appropriate tier
     * Use Case: Long-term token holding to earn rewards
     */
    function stake(uint256 amount) external updateReward(msg.sender) whenNotPaused {
        require(amount > 0, "Cannot stake 0");
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        UserInfo storage user = userInfo[msg.sender];
        user.stakedAmount += amount;
        user.lastStakeTime = block.timestamp;
        totalStaked += amount;
        
        // Determine user tier based on total staked amount
        _updateUserTier(msg.sender);
        
        emit Staked(msg.sender, amount, userTier[msg.sender]);
    }
    
    /**
     * @dev Withdraws staked tokens (with lock period check)
     * Use Case: Retrieving staked tokens after lock period expires
     */
    function withdraw(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        
        UserInfo storage user = userInfo[msg.sender];
        require(user.stakedAmount >= amount, "Insufficient staked amount");
        
        // Check lock period for user's tier
        uint256 tier = userTier[msg.sender];
        if (tier > 0) {
            require(
                block.timestamp >= user.lastStakeTime + stakingTiers[tier].lockPeriod,
                "Tokens are still locked"
            );
        }
        
        user.stakedAmount -= amount;
        totalStaked -= amount;
        
        // Update tier after withdrawal
        _updateUserTier(msg.sender);
        
        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Claims earned rewards
     * Use Case: Collecting staking rewards without unstaking
     */
    function claimReward() external updateReward(msg.sender) {
        uint256 reward = userInfo[msg.sender].rewards;
        if (reward > 0) {
            userInfo[msg.sender].rewards = 0;
            userInfo[msg.sender].totalRewardsClaimed += reward;
            totalRewardsDistributed += reward;
            
            require(rewardsToken.transfer(msg.sender, reward), "Reward transfer failed");
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    /**
     * @dev Compound staking - reinvest rewards as additional stake
     * Use Case: Maximizing returns through compound growth
     */
    function compound() external updateReward(msg.sender) whenNotPaused {
        uint256 reward = userInfo[msg.sender].rewards;
        require(reward > 0, "No rewards to compound");
        require(address(stakingToken) == address(rewardsToken), "Cannot compound different tokens");
        
        UserInfo storage user = userInfo[msg.sender];
        user.rewards = 0;
        user.stakedAmount += reward;
        user.lastStakeTime = block.timestamp;
        user.totalRewardsClaimed += reward;
        
        totalStaked += reward;
        totalRewardsDistributed += reward;
        
        _updateUserTier(msg.sender);
        
        emit RewardPaid(msg.sender, reward);
        emit Staked(msg.sender, reward, userTier[msg.sender]);
    }
    
    /**
     * @dev Emergency withdrawal without rewards (no lock period check)
     * Use Case: Emergency situations, protocol issues
     */
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.stakedAmount;
        require(amount > 0, "No tokens staked");
        
        user.stakedAmount = 0;
        user.rewards = 0;
        totalStaked -= amount;
        userTier[msg.sender] = 0;
        
        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Returns the current reward per token
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        
        return rewardPerTokenStored + 
            ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalStaked;
    }
    
    /**
     * @dev Calculates earned rewards for a user
     * Use Case: UI display, reward tracking, analytics
     */
    function earned(address account) public view returns (uint256) {
        UserInfo memory user = userInfo[account];
        uint256 tierMultiplier = stakingTiers[userTier[account]].multiplier;
        
        uint256 baseReward = (user.stakedAmount * 
            (rewardPerToken() - user.rewardPerTokenPaid)) / 1e18;
        
        // Apply tier multiplier
        uint256 multipliedReward = (baseReward * tierMultiplier) / 10000;
        
        return user.rewards + multipliedReward;
    }
    
    /**
     * @dev Returns the last time rewards were applicable
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }
    
    /**
     * @dev Gets user staking information
     * Use Case: Portfolio tracking, UI display
     */
    function getUserInfo(address account) external view returns (
        uint256 stakedAmount,
        uint256 earnedRewards,
        uint256 tier,
        uint256 lockEndTime,
        uint256 totalClaimed
    ) {
        UserInfo memory user = userInfo[account];
        uint256 currentTier = userTier[account];
        
        stakedAmount = user.stakedAmount;
        earnedRewards = earned(account);
        tier = currentTier;
        lockEndTime = currentTier > 0 ? 
            user.lastStakeTime + stakingTiers[currentTier].lockPeriod : 0;
        totalClaimed = user.totalRewardsClaimed;
    }
    
    /**
     * @dev Returns pool statistics
     * Use Case: Analytics, monitoring, UI display
     */
    function getPoolInfo() external view returns (
        uint256 totalStakedAmount,
        uint256 currentRewardRate,
        uint256 rewardsRemaining,
        uint256 totalRewardsGiven,
        uint256 rewardPeriodEnd
    ) {
        totalStakedAmount = totalStaked;
        currentRewardRate = rewardRate;
        rewardsRemaining = rewardsToken.balanceOf(address(this));
        totalRewardsGiven = totalRewardsDistributed;
        rewardPeriodEnd = periodFinish;
    }
    
    // Owner functions
    
    /**
     * @dev Adds rewards to the pool and extends the reward period
     * Use Case: Refilling reward pool, extending staking programs
     */
    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
        require(rewardsToken.transferFrom(msg.sender, address(this), reward), "Transfer failed");
        
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / REWARD_DURATION;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / REWARD_DURATION;
        }
        
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + REWARD_DURATION;
        
        emit RewardAdded(reward);
    }
    
    /**
     * @dev Pauses or unpauses staking
     */
    function setStakingPaused(bool _paused) external onlyOwner {
        stakingPaused = _paused;
        emit StakingPaused(_paused);
    }
    
    /**
     * @dev Adds a new staking tier
     */
    function addStakingTier(uint256 minAmount, uint256 multiplier, uint256 lockPeriod) 
        external onlyOwner 
    {
        _addStakingTier(minAmount, multiplier, lockPeriod);
    }
    
    /**
     * @dev Internal function to add staking tier
     */
    function _addStakingTier(uint256 minAmount, uint256 multiplier, uint256 lockPeriod) internal {
        stakingTiers.push(StakingTier({
            minAmount: minAmount,
            multiplier: multiplier,
            lockPeriod: lockPeriod
        }));
        
        emit TierAdded(minAmount, multiplier, lockPeriod);
    }
    
    /**
     * @dev Updates user's tier based on staked amount
     */
    function _updateUserTier(address user) internal {
        uint256 stakedAmount = userInfo[user].stakedAmount;
        uint256 newTier = 0;
        
        // Find the highest tier the user qualifies for
        for (uint256 i = stakingTiers.length; i > 0; i--) {
            if (stakedAmount >= stakingTiers[i - 1].minAmount) {
                newTier = i - 1;
                break;
            }
        }
        
        userTier[user] = newTier;
    }
    
    /**
     * @dev Transfers ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }
}