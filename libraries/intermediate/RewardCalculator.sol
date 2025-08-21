// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../basic/MathUtils.sol";

/**
 * @title RewardCalculator - Advanced Staking and Yield Distribution Engine
 * @dev Sophisticated reward calculation system for DeFi protocols
 * 
 * FEATURES:
 * - Multi-tier staking reward calculations
 * - Time-weighted and amount-weighted distributions
 * - Compound interest and boost mechanisms
 * - Dynamic APY calculations based on utilization
 * - Anti-gaming mechanisms and fair distribution
 * 
 * USE CASES:
 * 1. DeFi staking protocol reward distribution
 * 2. Liquidity mining program management
 * 3. Yield farming optimization algorithms
 * 4. Governance token distribution systems
 * 5. Performance-based incentive programs
 * 6. Multi-asset portfolio yield calculations
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library RewardCalculator {
    using MathUtils for uint256;
    
    // Precision constants
    uint256 private constant PRECISION = 1e18;
    uint256 private constant SECONDS_PER_YEAR = 31557600;
    uint256 private constant MAX_BOOST_MULTIPLIER = 5e18; // 5x max boost
    
    // Staking tier structure
    struct StakingTier {
        uint256 minAmount;
        uint256 baseAPY;
        uint256 boostMultiplier;
        uint256 lockupPeriod;
        bool active;
    }
    
    // Staker information
    struct Staker {
        uint256 stakedAmount;
        uint256 stakingStartTime;
        uint256 lastClaimTime;
        uint256 accumulatedRewards;
        uint256 boostLevel;
        uint256 tierIndex;
    }
    
    // Reward pool configuration
    struct RewardPool {
        uint256 totalRewards;
        uint256 rewardRate;
        uint256 totalStaked;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 utilizationTarget;
        mapping(address => Staker) stakers;
        mapping(address => uint256) userRewardPerTokenPaid;
    }
    
    /**
     * @dev Calculates current APY based on pool utilization
     * Use Case: Dynamic interest rate adjustment
     */
    function calculateDynamicAPY(
        uint256 baseAPY,
        uint256 totalStaked,
        uint256 targetUtilization,
        uint256 maxUtilization
    ) internal pure returns (uint256 currentAPY) {
        if (totalStaked == 0) return baseAPY;
        
        uint256 utilizationRate = (totalStaked * PRECISION) / maxUtilization;
        
        if (utilizationRate <= targetUtilization) {
            // Below target: linear increase
            currentAPY = baseAPY + (baseAPY * utilizationRate) / (2 * targetUtilization);
        } else {
            // Above target: exponential increase
            uint256 excessUtilization = utilizationRate - targetUtilization;
            uint256 maxExcess = PRECISION - targetUtilization;
            uint256 multiplier = PRECISION + (excessUtilization * PRECISION) / maxExcess;
            currentAPY = (baseAPY * multiplier) / PRECISION;
        }
    }
    
    /**
     * @dev Calculates time-based boost multiplier
     * Use Case: Long-term staking incentives
     */
    function calculateTimeBoost(
        uint256 stakingDuration,
        uint256 maxBoostTime
    ) internal pure returns (uint256 boostMultiplier) {
        if (stakingDuration >= maxBoostTime) {
            return MAX_BOOST_MULTIPLIER;
        }
        
        // Linear boost up to maximum
        boostMultiplier = PRECISION + (stakingDuration * (MAX_BOOST_MULTIPLIER - PRECISION)) / maxBoostTime;
    }
    
    /**
     * @dev Calculates amount-based boost multiplier
     * Use Case: Large staker incentives
     */
    function calculateAmountBoost(
        uint256 stakedAmount,
        uint256 totalStaked,
        uint256 maxBoostPercentage
    ) internal pure returns (uint256 boostMultiplier) {
        if (totalStaked == 0) return PRECISION;
        
        uint256 stakePercentage = (stakedAmount * PRECISION) / totalStaked;
        uint256 maxBoost = (maxBoostPercentage * PRECISION) / 100;
        
        // Quadratic boost based on stake percentage
        uint256 boost = (stakePercentage * stakePercentage * maxBoost) / (PRECISION * PRECISION);
        boostMultiplier = PRECISION + boost;
        
        if (boostMultiplier > MAX_BOOST_MULTIPLIER) {
            boostMultiplier = MAX_BOOST_MULTIPLIER;
        }
    }
    
    /**
     * @dev Calculates rewards for a specific staker
     * Use Case: Individual reward distribution
     */
    function calculateStakerRewards(
        Staker memory staker,
        RewardPool storage pool,
        StakingTier[] memory tiers
    ) internal view returns (uint256 rewards) {
        if (staker.stakedAmount == 0) return 0;
        
        uint256 stakingDuration = block.timestamp - staker.stakingStartTime;
        uint256 timeSinceLastClaim = block.timestamp - staker.lastClaimTime;
        
        // Get tier configuration
        StakingTier memory tier = tiers[staker.tierIndex];
        
        // Calculate base rewards
        uint256 baseRewards = (staker.stakedAmount * tier.baseAPY * timeSinceLastClaim) / 
                             (PRECISION * SECONDS_PER_YEAR);
        
        // Apply time boost
        uint256 timeBoost = calculateTimeBoost(stakingDuration, tier.lockupPeriod);
        
        // Apply amount boost
        uint256 amountBoost = calculateAmountBoost(
            staker.stakedAmount,
            pool.totalStaked,
            10 // 10% max amount boost
        );
        
        // Calculate total boost
        uint256 totalBoost = (timeBoost * amountBoost) / PRECISION;
        
        rewards = (baseRewards * totalBoost) / PRECISION;
    }
    
    /**
     * @dev Updates reward per token stored
     * Use Case: Pool-wide reward distribution tracking
     */
    function updateRewardPerToken(RewardPool storage pool) internal {
        if (pool.totalStaked == 0) {
            pool.lastUpdateTime = block.timestamp;
            return;
        }
        
        uint256 timeElapsed = block.timestamp - pool.lastUpdateTime;
        uint256 additionalRewardPerToken = (pool.rewardRate * timeElapsed * PRECISION) / pool.totalStaked;
        
        pool.rewardPerTokenStored += additionalRewardPerToken;
        pool.lastUpdateTime = block.timestamp;
    }
    
    /**
     * @dev Calculates compound interest for long-term staking
     * Use Case: Compound reward calculations
     */
    function calculateCompoundRewards(
        uint256 principal,
        uint256 annualRate,
        uint256 stakingPeriod,
        uint256 compoundFrequency
    ) internal pure returns (uint256 totalAmount) {
        if (compoundFrequency == 0) {
            // Simple interest
            return principal + (principal * annualRate * stakingPeriod) / (PRECISION * SECONDS_PER_YEAR);
        }
        
        uint256 periodsPerYear = SECONDS_PER_YEAR / compoundFrequency;
        uint256 totalPeriods = stakingPeriod / compoundFrequency;
        uint256 ratePerPeriod = annualRate / periodsPerYear;
        
        // Compound interest formula: A = P(1 + r/n)^(nt)
        totalAmount = principal.compoundInterest(ratePerPeriod, totalPeriods);
    }
    
    /**
     * @dev Calculates optimal staking tier for amount
     * Use Case: Tier selection optimization
     */
    function getOptimalTier(
        uint256 stakingAmount,
        StakingTier[] memory tiers
    ) internal pure returns (uint256 optimalTierIndex, uint256 projectedAPY) {
        uint256 maxEffectiveAPY = 0;
        optimalTierIndex = 0;
        
        for (uint256 i = 0; i < tiers.length; i++) {
            if (!tiers[i].active || stakingAmount < tiers[i].minAmount) {
                continue;
            }
            
            uint256 effectiveAPY = (tiers[i].baseAPY * tiers[i].boostMultiplier) / PRECISION;
            
            if (effectiveAPY > maxEffectiveAPY) {
                maxEffectiveAPY = effectiveAPY;
                optimalTierIndex = i;
            }
        }
        
        projectedAPY = maxEffectiveAPY;
    }
    
    /**
     * @dev Calculates penalty for early withdrawal
     * Use Case: Early exit penalty calculation
     */
    function calculateEarlyWithdrawalPenalty(
        uint256 stakedAmount,
        uint256 stakingDuration,
        uint256 requiredLockup,
        uint256 penaltyRate
    ) internal pure returns (uint256 penalty) {
        if (stakingDuration >= requiredLockup) {
            return 0; // No penalty for completed lockup
        }
        
        uint256 remainingTime = requiredLockup - stakingDuration;
        uint256 penaltyMultiplier = (remainingTime * penaltyRate) / requiredLockup;
        
        penalty = (stakedAmount * penaltyMultiplier) / PRECISION;
    }
    
    /**
     * @dev Distributes rewards proportionally among stakers
     * Use Case: Fair reward distribution across multiple stakers
     */
    function distributeProportionalRewards(
        uint256 totalRewards,
        uint256[] memory stakedAmounts,
        uint256[] memory stakingDurations,
        uint256[] memory boostMultipliers
    ) internal pure returns (uint256[] memory distributions) {
        require(
            stakedAmounts.length == stakingDurations.length &&
            stakingDurations.length == boostMultipliers.length,
            "RewardCalculator: array length mismatch"
        );
        
        distributions = new uint256[](stakedAmounts.length);
        uint256 totalWeightedStake = 0;
        
        // Calculate total weighted stake
        for (uint256 i = 0; i < stakedAmounts.length; i++) {
            uint256 weightedStake = (stakedAmounts[i] * boostMultipliers[i]) / PRECISION;
            totalWeightedStake += weightedStake;
        }
        
        if (totalWeightedStake == 0) return distributions;
        
        // Distribute rewards proportionally
        for (uint256 i = 0; i < stakedAmounts.length; i++) {
            uint256 weightedStake = (stakedAmounts[i] * boostMultipliers[i]) / PRECISION;
            distributions[i] = (totalRewards * weightedStake) / totalWeightedStake;
        }
    }
    
    /**
     * @dev Calculates impermanent loss compensation
     * Use Case: LP reward calculations with IL protection
     */
    function calculateImpermanentLossCompensation(
        uint256 initialValue,
        uint256 currentValue,
        uint256 rewardRate,
        uint256 compensationMultiplier
    ) internal pure returns (uint256 compensation) {
        if (currentValue >= initialValue) {
            return 0; // No impermanent loss
        }
        
        uint256 loss = initialValue - currentValue;
        compensation = (loss * compensationMultiplier * rewardRate) / (PRECISION * PRECISION);
    }
    
    /**
     * @dev Calculates voting power based on staking amount and duration
     * Use Case: Governance token distribution and voting weight
     */
    function calculateVotingPower(
        uint256 stakedAmount,
        uint256 stakingDuration,
        uint256 maxStakingTime,
        uint256 baseVotingPower
    ) internal pure returns (uint256 votingPower) {
        if (stakedAmount == 0) return 0;
        
        // Base voting power from staked amount
        votingPower = (stakedAmount * baseVotingPower) / PRECISION;
        
        // Time-based multiplier (up to 2x for maximum staking time)
        uint256 timeMultiplier = PRECISION;
        if (stakingDuration >= maxStakingTime) {
            timeMultiplier = 2 * PRECISION;
        } else {
            timeMultiplier = PRECISION + (stakingDuration * PRECISION) / maxStakingTime;
        }
        
        votingPower = (votingPower * timeMultiplier) / PRECISION;
    }
    
    /**
     * @dev Anti-gaming mechanism for reward farming
     * Use Case: Preventing reward manipulation and farming attacks
     */
    function validateRewardClaim(
        address staker,
        uint256 claimAmount,
        uint256 maxClaimPerPeriod,
        uint256 lastClaimTime,
        uint256 claimCooldown
    ) internal view returns (bool isValid, string memory reason) {
        // Check cooldown period
        if (block.timestamp < lastClaimTime + claimCooldown) {
            return (false, "Claim cooldown not met");
        }
        
        // Check maximum claim amount
        if (claimAmount > maxClaimPerPeriod) {
            return (false, "Claim amount exceeds maximum");
        }
        
        // Check for suspicious claiming patterns
        // (This is a simplified check - more sophisticated anti-gaming logic would be implemented)
        if (claimAmount > 0 && lastClaimTime > 0) {
            uint256 timeSinceLastClaim = block.timestamp - lastClaimTime;
            if (timeSinceLastClaim < 3600) { // Less than 1 hour
                return (false, "Claim frequency too high");
            }
        }
        
        return (true, "");
    }
}