// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title YieldFarm - Advanced Yield Farming Protocol
 * @dev Sophisticated yield farming with multiple pools and reward tokens
 * 
 * USE CASES:
 * 1. Liquidity mining programs for new token launches
 * 2. Multi-token reward distribution systems
 * 3. Time-weighted farming incentives
 * 4. LP token staking with boosted rewards
 * 5. Ecosystem governance token distribution
 * 6. Cross-protocol yield aggregation
 * 
 * WHY IT WORKS:
 * - Multiple pools allow diverse farming strategies
 * - Boost mechanisms reward long-term participants
 * - Emergency controls protect user funds
 * - Scalable reward distribution handles multiple tokens
 * - Time-locked rewards encourage ecosystem growth
 * 
 * @author Nibert Investments Development Team
 */

interface IERC20Farm {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract YieldFarm {
    // Pool information
    struct PoolInfo {
        IERC20Farm stakingToken;     // Address of staking token contract
        uint256 allocPoint;          // Allocation points for this pool
        uint256 lastRewardBlock;     // Last block number that reward distribution occurred
        uint256 accRewardPerShare;   // Accumulated rewards per share
        uint256 totalStaked;         // Total amount staked in this pool
        uint256 minStakeTime;        // Minimum staking time for rewards
        bool emergencyWithdrawEnabled; // Emergency withdrawal flag
        string poolName;             // Human readable pool name
    }
    
    // User information
    struct UserInfo {
        uint256 amount;          // How many tokens the user has staked
        uint256 rewardDebt;      // Reward debt for primary reward calculation
        uint256 lastStakeTime;   // When user last staked
        uint256 totalRewarded;   // Total rewards claimed by user
        mapping(address => uint256) additionalRewardDebt; // For multiple reward tokens
    }
    
    // Boost information for enhanced rewards
    struct BoostInfo {
        uint256 boostMultiplier;     // Multiplier in basis points (10000 = 1x)
        uint256 requiredStakeTime;   // Time required to get this boost
        uint256 maxBoostAmount;      // Maximum tokens that can get boost
    }
    
    // Reward token information
    struct RewardToken {
        IERC20Farm token;
        uint256 rewardPerBlock;
        uint256 accRewardPerShare;
        uint256 totalDistributed;
        bool active;
    }
    
    // State variables
    IERC20Farm public primaryRewardToken;
    address public owner;
    uint256 public rewardPerBlock;
    uint256 public startBlock;
    uint256 public totalAllocPoint;
    
    // Pool and user data
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => BoostInfo[]) public poolBoosts;
    mapping(address => RewardToken) public additionalRewards;
    address[] public rewardTokenList;
    
    // Security
    bool public paused;
    uint256 public constant MAX_POOLS = 50;
    
    // Events
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardClaimed(address indexed user, uint256 indexed pid, uint256 amount);
    event PoolAdded(uint256 indexed pid, address stakingToken, uint256 allocPoint);
    event PoolUpdated(uint256 indexed pid, uint256 allocPoint);
    event BoostAdded(uint256 indexed pid, uint256 multiplier, uint256 stakeTime);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    modifier validPool(uint256 _pid) {
        require(_pid < poolInfo.length, "Invalid pool ID");
        _;
    }
    
    constructor(
        IERC20Farm _primaryRewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) {
        primaryRewardToken = _primaryRewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        owner = msg.sender;
    }
    
    /**
     * @dev Adds a new farming pool
     * Use Case: Launching new liquidity mining programs
     */
    function addPool(
        uint256 _allocPoint,
        IERC20Farm _stakingToken,
        uint256 _minStakeTime,
        string memory _poolName
    ) external onlyOwner {
        require(poolInfo.length < MAX_POOLS, "Maximum pools reached");
        
        massUpdatePools();
        
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint += _allocPoint;
        
        poolInfo.push(PoolInfo({
            stakingToken: _stakingToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRewardPerShare: 0,
            totalStaked: 0,
            minStakeTime: _minStakeTime,
            emergencyWithdrawEnabled: false,
            poolName: _poolName
        }));
        
        emit PoolAdded(poolInfo.length - 1, address(_stakingToken), _allocPoint);
    }
    
    /**
     * @dev Adds boost tier to a pool
     * Use Case: Incentivizing long-term staking
     */
    function addPoolBoost(
        uint256 _pid,
        uint256 _boostMultiplier,
        uint256 _requiredStakeTime,
        uint256 _maxBoostAmount
    ) external onlyOwner validPool(_pid) {
        poolBoosts[_pid].push(BoostInfo({
            boostMultiplier: _boostMultiplier,
            requiredStakeTime: _requiredStakeTime,
            maxBoostAmount: _maxBoostAmount
        }));
        
        emit BoostAdded(_pid, _boostMultiplier, _requiredStakeTime);
    }
    
    /**
     * @dev Deposits tokens into farming pool
     * Use Case: Staking LP tokens to earn rewards
     */
    function deposit(uint256 _pid, uint256 _amount) 
        external 
        validPool(_pid) 
        whenNotPaused 
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        updatePool(_pid);
        
        // Claim pending rewards before updating stake
        if (user.amount > 0) {
            _claimRewards(_pid, msg.sender);
        }
        
        if (_amount > 0) {
            require(
                pool.stakingToken.transferFrom(msg.sender, address(this), _amount),
                "Transfer failed"
            );
            user.amount += _amount;
            pool.totalStaked += _amount;
            user.lastStakeTime = block.timestamp;
        }
        
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;
        
        // Update additional reward debts
        for (uint256 i = 0; i < rewardTokenList.length; i++) {
            address rewardTokenAddr = rewardTokenList[i];
            RewardToken storage rewardToken = additionalRewards[rewardTokenAddr];
            if (rewardToken.active) {
                user.additionalRewardDebt[rewardTokenAddr] = 
                    (user.amount * rewardToken.accRewardPerShare) / 1e12;
            }
        }
        
        emit Deposit(msg.sender, _pid, _amount);
    }
    
    /**
     * @dev Withdraws staked tokens from pool
     * Use Case: Unstaking after farming period
     */
    function withdraw(uint256 _pid, uint256 _amount) 
        external 
        validPool(_pid) 
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require(user.amount >= _amount, "Insufficient staked amount");
        require(
            block.timestamp >= user.lastStakeTime + pool.minStakeTime,
            "Minimum stake time not met"
        );
        
        updatePool(_pid);
        
        // Claim all pending rewards
        _claimRewards(_pid, msg.sender);
        
        if (_amount > 0) {
            user.amount -= _amount;
            pool.totalStaked -= _amount;
            require(pool.stakingToken.transfer(msg.sender, _amount), "Transfer failed");
        }
        
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;
        
        // Update additional reward debts
        for (uint256 i = 0; i < rewardTokenList.length; i++) {
            address rewardTokenAddr = rewardTokenList[i];
            RewardToken storage rewardToken = additionalRewards[rewardTokenAddr];
            if (rewardToken.active) {
                user.additionalRewardDebt[rewardTokenAddr] = 
                    (user.amount * rewardToken.accRewardPerShare) / 1e12;
            }
        }
        
        emit Withdraw(msg.sender, _pid, _amount);
    }
    
    /**
     * @dev Claims pending rewards without withdrawing stake
     * Use Case: Harvesting rewards while maintaining position
     */
    function claimRewards(uint256 _pid) external validPool(_pid) {
        updatePool(_pid);
        _claimRewards(_pid, msg.sender);
        
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;
        
        for (uint256 i = 0; i < rewardTokenList.length; i++) {
            address rewardTokenAddr = rewardTokenList[i];
            RewardToken storage rewardToken = additionalRewards[rewardTokenAddr];
            if (rewardToken.active) {
                user.additionalRewardDebt[rewardTokenAddr] = 
                    (user.amount * rewardToken.accRewardPerShare) / 1e12;
            }
        }
    }
    
    /**
     * @dev Internal function to handle reward claiming
     */
    function _claimRewards(uint256 _pid, address _user) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        
        if (user.amount == 0) return;
        
        // Calculate primary reward with boost
        uint256 baseReward = (user.amount * pool.accRewardPerShare) / 1e12 - user.rewardDebt;
        uint256 boostedReward = _applyBoost(_pid, _user, baseReward);
        
        if (boostedReward > 0) {
            require(primaryRewardToken.transfer(_user, boostedReward), "Reward transfer failed");
            user.totalRewarded += boostedReward;
            emit RewardClaimed(_user, _pid, boostedReward);
        }
        
        // Handle additional reward tokens
        for (uint256 i = 0; i < rewardTokenList.length; i++) {
            address rewardTokenAddr = rewardTokenList[i];
            RewardToken storage rewardToken = additionalRewards[rewardTokenAddr];
            
            if (rewardToken.active) {
                uint256 additionalReward = (user.amount * rewardToken.accRewardPerShare) / 1e12 - 
                    user.additionalRewardDebt[rewardTokenAddr];
                
                if (additionalReward > 0) {
                    require(
                        rewardToken.token.transfer(_user, additionalReward),
                        "Additional reward transfer failed"
                    );
                    rewardToken.totalDistributed += additionalReward;
                }
            }
        }
    }
    
    /**
     * @dev Applies boost multiplier based on staking time
     */
    function _applyBoost(uint256 _pid, address _user, uint256 _baseReward) 
        internal 
        view 
        returns (uint256) 
    {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 stakeTime = block.timestamp - user.lastStakeTime;
        uint256 boostedReward = _baseReward;
        
        BoostInfo[] storage boosts = poolBoosts[_pid];
        for (uint256 i = 0; i < boosts.length; i++) {
            if (stakeTime >= boosts[i].requiredStakeTime) {
                uint256 applicableAmount = user.amount > boosts[i].maxBoostAmount ? 
                    boosts[i].maxBoostAmount : user.amount;
                
                uint256 boostAmount = (applicableAmount * _baseReward * boosts[i].boostMultiplier) / 
                    (user.amount * 10000);
                
                boostedReward += boostAmount;
            }
        }
        
        return boostedReward;
    }
    
    /**
     * @dev Updates reward variables for specific pool
     */
    function updatePool(uint256 _pid) public validPool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        
        if (pool.totalStaked == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        
        uint256 multiplier = block.number - pool.lastRewardBlock;
        uint256 reward = (multiplier * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
        
        pool.accRewardPerShare += (reward * 1e12) / pool.totalStaked;
        pool.lastRewardBlock = block.number;
        
        // Update additional reward tokens
        for (uint256 i = 0; i < rewardTokenList.length; i++) {
            address rewardTokenAddr = rewardTokenList[i];
            RewardToken storage rewardToken = additionalRewards[rewardTokenAddr];
            
            if (rewardToken.active) {
                uint256 additionalReward = (multiplier * rewardToken.rewardPerBlock * pool.allocPoint) / 
                    totalAllocPoint;
                rewardToken.accRewardPerShare += (additionalReward * 1e12) / pool.totalStaked;
            }
        }
    }
    
    /**
     * @dev Updates all pools
     */
    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            updatePool(pid);
        }
    }
    
    /**
     * @dev Emergency withdraw without rewards
     * Use Case: Emergency situations or protocol issues
     */
    function emergencyWithdraw(uint256 _pid) external validPool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.emergencyWithdrawEnabled, "Emergency withdraw not enabled");
        
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        
        user.amount = 0;
        user.rewardDebt = 0;
        pool.totalStaked -= amount;
        
        require(pool.stakingToken.transfer(msg.sender, amount), "Transfer failed");
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
    
    /**
     * @dev Gets pending rewards for a user
     * Use Case: UI display, analytics
     */
    function pendingRewards(uint256 _pid, address _user) 
        external 
        view 
        validPool(_pid) 
        returns (uint256) 
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        
        uint256 accRewardPerShare = pool.accRewardPerShare;
        
        if (block.number > pool.lastRewardBlock && pool.totalStaked != 0) {
            uint256 multiplier = block.number - pool.lastRewardBlock;
            uint256 reward = (multiplier * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
            accRewardPerShare += (reward * 1e12) / pool.totalStaked;
        }
        
        uint256 baseReward = (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;
        return _applyBoost(_pid, _user, baseReward);
    }
    
    /**
     * @dev Gets pool information
     */
    function getPoolInfo(uint256 _pid) 
        external 
        view 
        validPool(_pid) 
        returns (
            address stakingToken,
            uint256 allocPoint,
            uint256 totalStaked,
            uint256 accRewardPerShare,
            string memory poolName
        ) 
    {
        PoolInfo storage pool = poolInfo[_pid];
        return (
            address(pool.stakingToken),
            pool.allocPoint,
            pool.totalStaked,
            pool.accRewardPerShare,
            pool.poolName
        );
    }
    
    // Owner functions
    
    /**
     * @dev Adds additional reward token
     */
    function addRewardToken(
        address _token,
        uint256 _rewardPerBlock
    ) external onlyOwner {
        require(address(additionalRewards[_token].token) == address(0), "Token already added");
        
        additionalRewards[_token] = RewardToken({
            token: IERC20Farm(_token),
            rewardPerBlock: _rewardPerBlock,
            accRewardPerShare: 0,
            totalDistributed: 0,
            active: true
        });
        
        rewardTokenList.push(_token);
    }
    
    /**
     * @dev Updates pool allocation points
     */
    function updatePool(uint256 _pid, uint256 _allocPoint) external onlyOwner validPool(_pid) {
        massUpdatePools();
        
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        
        emit PoolUpdated(_pid, _allocPoint);
    }
    
    /**
     * @dev Pauses the contract
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }
    
    /**
     * @dev Enables emergency withdraw for a pool
     */
    function setEmergencyWithdraw(uint256 _pid, bool _enabled) 
        external 
        onlyOwner 
        validPool(_pid) 
    {
        poolInfo[_pid].emergencyWithdrawEnabled = _enabled;
    }
    
    /**
     * @dev Returns number of pools
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
}