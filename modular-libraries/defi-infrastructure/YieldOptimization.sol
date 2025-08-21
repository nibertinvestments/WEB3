// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title YieldOptimization - Advanced Yield Farming and Optimization Library
 * @dev Comprehensive library for yield farming strategies and optimization algorithms
 * 
 * USE CASES:
 * 1. Multi-protocol yield optimization strategies
 * 2. Auto-compounding mechanisms with reinvestment
 * 3. Risk-adjusted yield calculations
 * 4. Dynamic strategy allocation and rebalancing
 * 5. Impermanent loss mitigation strategies
 * 6. Institutional-grade portfolio optimization
 * 
 * WHY IT WORKS:
 * - Advanced mathematical models for yield prediction
 * - Real-time strategy performance monitoring
 * - Gas-optimized compound calculations
 * - Risk-weighted portfolio construction
 * - Adaptive algorithms for changing market conditions
 * 
 * @author Nibert Investments Development Team
 */
library YieldOptimization {
    
    // Precision and calculation constants
    uint256 private constant PRECISION = 1e18;
    uint256 private constant BPS_DENOMINATOR = 10000;
    uint256 private constant SECONDS_PER_YEAR = 365 days;
    uint256 private constant MAX_STRATEGIES = 20;
    uint256 private constant MIN_ALLOCATION = 100; // 1% minimum
    
    // Strategy types
    enum StrategyType {
        LiquidityMining,      // Basic LP token staking
        YieldFarming,         // Token reward farming
        LendingProtocol,      // Lending/borrowing strategies
        Leveraged,            // Leveraged yield farming
        DeltaNeutral,         // Delta-neutral strategies
        ArbitrageYield,       // Arbitrage-based yield
        OptionsStrategy,      // Options-based yield
        Synthetic            // Synthetic asset strategies
    }
    
    // Risk levels
    enum RiskLevel {
        VeryLow,    // 0-2% volatility
        Low,        // 2-5% volatility
        Medium,     // 5-10% volatility
        High,       // 10-20% volatility
        VeryHigh    // >20% volatility
    }
    
    // Yield strategy data
    struct YieldStrategy {
        StrategyType strategyType;
        address protocol;
        address asset;
        address rewardToken;
        uint256 apy;              // Annual percentage yield
        uint256 tvl;              // Total value locked
        uint256 minimumDeposit;
        uint256 withdrawalFee;
        uint256 performanceFee;
        RiskLevel riskLevel;
        uint256 volatility;       // Historical volatility
        uint256 maxDrawdown;      // Maximum historical drawdown
        uint256 sharpeRatio;      // Risk-adjusted return metric
        uint256 lastUpdate;
        bool isActive;
    }
    
    // Portfolio allocation
    struct PortfolioAllocation {
        uint256 strategyId;
        uint256 allocation;       // Percentage in basis points
        uint256 amount;          // Actual amount allocated
        uint256 expectedYield;   // Expected annual yield
        uint256 riskWeight;      // Risk-weighted allocation
    }
    
    // Compound calculation result
    struct CompoundResult {
        uint256 principal;
        uint256 compoundedAmount;
        uint256 totalRewards;
        uint256 effectiveAPY;
        uint256 compoundingPeriods;
    }
    
    // Risk metrics
    struct RiskMetrics {
        uint256 portfolioVolatility;
        uint256 valueAtRisk;           // VaR at 95% confidence
        uint256 expectedShortfall;     // Conditional VaR
        uint256 maximumDrawdown;
        uint256 beta;                  // Market beta
        uint256 alpha;                 // Risk-adjusted excess return
        uint256 informationRatio;
        uint256 calmarRatio;           // Return/max drawdown ratio
    }
    
    // Optimization constraints
    struct OptimizationConstraints {
        uint256 maxRiskLevel;          // Maximum allowed risk level
        uint256 maxSingleAllocation;   // Maximum allocation to single strategy
        uint256 minDiversification;    // Minimum number of strategies
        uint256 maxLeverage;           // Maximum leverage ratio
        uint256 liquidityRequirement;  // Minimum liquidity buffer
        bool allowHighRisk;            // Allow high-risk strategies
    }
    
    // Events
    event StrategyOptimized(uint256 indexed strategyId, uint256 newAPY, uint256 newAllocation);
    event PortfolioRebalanced(uint256 totalValue, uint256 newExpectedYield);
    event CompoundExecuted(uint256 indexed strategyId, uint256 compoundedAmount);
    event RiskAnalysisUpdated(uint256 portfolioRisk, uint256 expectedReturn);
    
    // Errors
    error StrategyNotFound(uint256 strategyId);
    error InsufficientLiquidity(uint256 required, uint256 available);
    error RiskLimitExceeded(uint256 risk, uint256 maxRisk);
    error InvalidAllocation(uint256 allocation);
    error OptimizationFailed(string reason);
    
    /**
     * @dev Calculate compound yield with multiple compounding periods
     */
    function calculateCompoundYield(
        uint256 principal,
        uint256 annualRate,      // Annual rate in basis points
        uint256 periods,         // Number of compounding periods per year
        uint256 timeInYears      // Time period in years (scaled by PRECISION)
    ) internal pure returns (CompoundResult memory result) {
        require(principal > 0, "Invalid principal");
        require(annualRate <= 50000, "Rate too high"); // Max 500% APY
        
        // Convert annual rate to per-period rate
        uint256 periodRate = (annualRate * PRECISION) / (periods * BPS_DENOMINATOR);
        
        // Calculate total number of compounding events
        uint256 totalPeriods = (periods * timeInYears) / PRECISION;
        
        // Calculate compound amount: A = P(1 + r)^n
        uint256 compoundFactor = PRECISION; // Start with 1.0
        
        for (uint256 i = 0; i < totalPeriods; i++) {
            compoundFactor = (compoundFactor * (PRECISION + periodRate)) / PRECISION;
        }
        
        result.principal = principal;
        result.compoundedAmount = (principal * compoundFactor) / PRECISION;
        result.totalRewards = result.compoundedAmount - principal;
        result.compoundingPeriods = totalPeriods;
        
        // Calculate effective APY
        if (timeInYears > 0) {
            uint256 totalReturn = (result.compoundedAmount * PRECISION) / principal;
            result.effectiveAPY = _calculateEffectiveAPY(totalReturn, timeInYears);
        }
        
        return result;
    }
    
    /**
     * @dev Optimize portfolio allocation using Modern Portfolio Theory
     */
    function optimizePortfolio(
        YieldStrategy[] memory strategies,
        uint256 totalAmount,
        OptimizationConstraints memory constraints
    ) internal pure returns (PortfolioAllocation[] memory allocations) {
        require(strategies.length > 0, "No strategies provided");
        require(totalAmount > 0, "Invalid amount");
        
        uint256 activeStrategies = 0;
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i].isActive) activeStrategies++;
        }
        
        require(activeStrategies >= constraints.minDiversification, "Insufficient diversification");
        
        allocations = new PortfolioAllocation[](activeStrategies);
        
        // Calculate risk-adjusted scores for each strategy
        uint256[] memory scores = new uint256[](strategies.length);
        uint256 totalScore = 0;
        
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i].isActive) {
                scores[i] = _calculateStrategyScore(strategies[i]);
                totalScore += scores[i];
            }
        }
        
        // Allocate based on risk-adjusted scores
        uint256 allocatedAmount = 0;
        uint256 allocationIndex = 0;
        
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i].isActive && scores[i] > 0) {
                uint256 allocation = (scores[i] * BPS_DENOMINATOR) / totalScore;
                
                // Apply constraints
                if (allocation > constraints.maxSingleAllocation) {
                    allocation = constraints.maxSingleAllocation;
                }
                
                if (allocation >= MIN_ALLOCATION) {
                    uint256 amount = (totalAmount * allocation) / BPS_DENOMINATOR;
                    
                    allocations[allocationIndex] = PortfolioAllocation({
                        strategyId: i,
                        allocation: allocation,
                        amount: amount,
                        expectedYield: (strategies[i].apy * amount) / BPS_DENOMINATOR,
                        riskWeight: _calculateRiskWeight(strategies[i])
                    });
                    
                    allocatedAmount += amount;
                    allocationIndex++;
                }
            }
        }
        
        // Redistribute any remaining amount
        if (allocatedAmount < totalAmount && allocationIndex > 0) {
            uint256 remaining = totalAmount - allocatedAmount;
            uint256 perStrategy = remaining / allocationIndex;
            
            for (uint256 i = 0; i < allocationIndex; i++) {
                allocations[i].amount += perStrategy;
                allocations[i].expectedYield += (strategies[allocations[i].strategyId].apy * perStrategy) / BPS_DENOMINATOR;
            }
        }
        
        return allocations;
    }
    
    /**
     * @dev Calculate portfolio risk metrics
     */
    function calculateRiskMetrics(
        YieldStrategy[] memory strategies,
        PortfolioAllocation[] memory allocations
    ) internal pure returns (RiskMetrics memory metrics) {
        require(strategies.length > 0 && allocations.length > 0, "Invalid input");
        
        uint256 totalWeight = 0;
        uint256 weightedVolatility = 0;
        uint256 weightedDrawdown = 0;
        
        // Calculate weighted portfolio metrics
        for (uint256 i = 0; i < allocations.length; i++) {
            uint256 strategyId = allocations[i].strategyId;
            uint256 weight = allocations[i].allocation;
            
            if (strategyId < strategies.length) {
                totalWeight += weight;
                weightedVolatility += (strategies[strategyId].volatility * weight);
                weightedDrawdown += (strategies[strategyId].maxDrawdown * weight);
            }
        }
        
        if (totalWeight > 0) {
            metrics.portfolioVolatility = weightedVolatility / totalWeight;
            metrics.maximumDrawdown = weightedDrawdown / totalWeight;
        }
        
        // Calculate VaR (simplified normal distribution assumption)
        metrics.valueAtRisk = (metrics.portfolioVolatility * 196) / 100; // 1.96 * volatility for 95% confidence
        
        // Calculate Expected Shortfall (approximately 1.3 * VaR for normal distribution)
        metrics.expectedShortfall = (metrics.valueAtRisk * 130) / 100;
        
        // Calculate other risk metrics (simplified calculations)
        metrics.beta = _calculatePortfolioBeta(strategies, allocations);
        metrics.informationRatio = _calculateInformationRatio(strategies, allocations);
        
        if (metrics.maximumDrawdown > 0) {
            metrics.calmarRatio = _calculatePortfolioReturn(strategies, allocations) / metrics.maximumDrawdown;
        }
        
        return metrics;
    }
    
    /**
     * @dev Calculate optimal compound frequency
     */
    function calculateOptimalCompoundFrequency(
        uint256 apy,
        uint256 gasCost,
        uint256 principalAmount
    ) internal pure returns (uint256 optimalFrequency, uint256 netGain) {
        require(apy > 0 && principalAmount > 0, "Invalid parameters");
        
        uint256 bestNetGain = 0;
        uint256 bestFrequency = 1;
        
        // Test different compounding frequencies (daily, weekly, monthly, etc.)
        uint256[] memory frequencies = new uint256[](6);
        frequencies[0] = 1;    // Annual
        frequencies[1] = 12;   // Monthly
        frequencies[2] = 52;   // Weekly
        frequencies[3] = 365;  // Daily
        frequencies[4] = 8760; // Hourly
        frequencies[5] = 525600; // Per minute (theoretical maximum)
        
        for (uint256 i = 0; i < frequencies.length; i++) {
            uint256 frequency = frequencies[i];
            
            // Calculate compound yield for one year
            CompoundResult memory result = calculateCompoundYield(
                principalAmount,
                apy,
                frequency,
                PRECISION // 1 year
            );
            
            // Calculate total gas cost for the year
            uint256 totalGasCost = gasCost * frequency;
            
            // Calculate net gain
            uint256 grossGain = result.totalRewards;
            uint256 netGainForFreq = grossGain > totalGasCost ? grossGain - totalGasCost : 0;
            
            if (netGainForFreq > bestNetGain) {
                bestNetGain = netGainForFreq;
                bestFrequency = frequency;
            }
        }
        
        return (bestFrequency, bestNetGain);
    }
    
    /**
     * @dev Calculate impermanent loss for LP strategies
     */
    function calculateImpermanentLoss(
        uint256 priceRatio,      // Current price ratio (token1/token0)
        uint256 initialRatio     // Initial price ratio
    ) internal pure returns (uint256 impermanentLoss) {
        require(priceRatio > 0 && initialRatio > 0, "Invalid price ratios");
        
        // IL = 2 * sqrt(price_ratio) / (1 + price_ratio) - 1
        // Where price_ratio is current_price / initial_price
        
        uint256 priceChange = (priceRatio * PRECISION) / initialRatio;
        uint256 sqrtPriceChange = _sqrt(priceChange);
        
        uint256 numerator = 2 * sqrtPriceChange;
        uint256 denominator = PRECISION + priceChange;
        
        uint256 holdValue = (numerator * PRECISION) / denominator;
        
        if (holdValue < PRECISION) {
            impermanentLoss = PRECISION - holdValue;
        } else {
            impermanentLoss = 0; // No impermanent loss (actually a gain)
        }
        
        return impermanentLoss;
    }
    
    /**
     * @dev Calculate strategy diversification benefit
     */
    function calculateDiversificationBenefit(
        YieldStrategy[] memory strategies,
        PortfolioAllocation[] memory allocations
    ) internal pure returns (uint256 diversificationRatio) {
        require(strategies.length > 1, "Need multiple strategies");
        
        // Calculate portfolio volatility
        uint256 portfolioVol = 0;
        uint256 totalWeight = 0;
        
        for (uint256 i = 0; i < allocations.length; i++) {
            uint256 strategyId = allocations[i].strategyId;
            uint256 weight = allocations[i].allocation;
            
            if (strategyId < strategies.length) {
                portfolioVol += (strategies[strategyId].volatility * weight * weight) / (BPS_DENOMINATOR * BPS_DENOMINATOR);
                totalWeight += weight;
            }
        }
        
        // Add correlation effects (simplified - assumes 50% correlation)
        for (uint256 i = 0; i < allocations.length; i++) {
            for (uint256 j = i + 1; j < allocations.length; j++) {
                uint256 strategyIdI = allocations[i].strategyId;
                uint256 strategyIdJ = allocations[j].strategyId;
                uint256 weightI = allocations[i].allocation;
                uint256 weightJ = allocations[j].allocation;
                
                if (strategyIdI < strategies.length && strategyIdJ < strategies.length) {
                    uint256 covariance = (strategies[strategyIdI].volatility * strategies[strategyIdJ].volatility * 50) / 100; // 50% correlation
                    portfolioVol += (2 * weightI * weightJ * covariance) / (BPS_DENOMINATOR * BPS_DENOMINATOR);
                }
            }
        }
        
        portfolioVol = _sqrt(portfolioVol);
        
        // Calculate weighted average individual volatility
        uint256 avgVolatility = 0;
        for (uint256 i = 0; i < allocations.length; i++) {
            uint256 strategyId = allocations[i].strategyId;
            uint256 weight = allocations[i].allocation;
            
            if (strategyId < strategies.length && totalWeight > 0) {
                avgVolatility += (strategies[strategyId].volatility * weight) / totalWeight;
            }
        }
        
        // Diversification ratio = individual volatility / portfolio volatility
        if (portfolioVol > 0) {
            diversificationRatio = (avgVolatility * PRECISION) / portfolioVol;
        } else {
            diversificationRatio = PRECISION;
        }
        
        return diversificationRatio;
    }
    
    /**
     * @dev Calculate yield decay over time
     */
    function calculateYieldDecay(
        uint256 initialAPY,
        uint256 decayRate,       // Annual decay rate in basis points
        uint256 timeElapsed      // Time elapsed in seconds
    ) internal pure returns (uint256 currentAPY) {
        require(initialAPY > 0, "Invalid initial APY");
        
        // Apply exponential decay: APY(t) = APY(0) * e^(-decay_rate * t)
        // Simplified to: APY(t) = APY(0) * (1 - decay_rate)^t
        
        uint256 yearsElapsed = (timeElapsed * PRECISION) / SECONDS_PER_YEAR;
        uint256 decayFactor = PRECISION - ((decayRate * PRECISION) / BPS_DENOMINATOR);
        
        currentAPY = initialAPY;
        uint256 remainingTime = yearsElapsed;
        
        while (remainingTime > 0) {
            if (remainingTime >= PRECISION) {
                currentAPY = (currentAPY * decayFactor) / PRECISION;
                remainingTime -= PRECISION;
            } else {
                // Linear interpolation for fractional years
                uint256 partialDecay = (decayFactor * remainingTime) / PRECISION;
                currentAPY = (currentAPY * (PRECISION - partialDecay + remainingTime)) / PRECISION;
                break;
            }
        }
        
        return currentAPY;
    }
    
    /**
     * @dev Calculate auto-compounding optimal schedule
     */
    function calculateAutoCompoundSchedule(
        uint256 principal,
        uint256 apy,
        uint256 gasCostPerCompound,
        uint256 timeHorizon       // In seconds
    ) internal pure returns (
        uint256[] memory compoundTimes,
        uint256 totalCompounds,
        uint256 finalValue,
        uint256 totalGasCost
    ) {
        require(principal > 0 && apy > 0, "Invalid parameters");
        
        // Calculate optimal compound frequency
        (uint256 optimalFrequency, ) = calculateOptimalCompoundFrequency(apy, gasCostPerCompound, principal);
        
        // Calculate compound interval
        uint256 compoundInterval = timeHorizon / optimalFrequency;
        
        compoundTimes = new uint256[](optimalFrequency);
        
        for (uint256 i = 0; i < optimalFrequency; i++) {
            compoundTimes[i] = (i + 1) * compoundInterval;
        }
        
        // Calculate final value with optimal compounding
        CompoundResult memory result = calculateCompoundYield(
            principal,
            apy,
            optimalFrequency,
            (timeHorizon * PRECISION) / SECONDS_PER_YEAR
        );
        
        totalCompounds = optimalFrequency;
        finalValue = result.compoundedAmount;
        totalGasCost = gasCostPerCompound * optimalFrequency;
        
        return (compoundTimes, totalCompounds, finalValue, totalGasCost);
    }
    
    // Internal helper functions
    
    function _calculateStrategyScore(YieldStrategy memory strategy) internal pure returns (uint256) {
        // Risk-adjusted return score using Sharpe ratio and other factors
        uint256 baseScore = strategy.apy;
        
        // Adjust for risk
        if (strategy.volatility > 0) {
            baseScore = (baseScore * PRECISION) / strategy.volatility;
        }
        
        // Adjust for TVL (higher TVL = more established)
        uint256 tvlBonus = strategy.tvl > 1000000e18 ? 110 : (strategy.tvl > 100000e18 ? 105 : 100);
        baseScore = (baseScore * tvlBonus) / 100;
        
        // Adjust for fees
        uint256 netScore = baseScore > strategy.performanceFee ? baseScore - strategy.performanceFee : 0;
        
        return netScore;
    }
    
    function _calculateRiskWeight(YieldStrategy memory strategy) internal pure returns (uint256) {
        // Higher volatility = higher risk weight
        uint256 riskMultiplier = 100 + strategy.volatility; // Base 100 + volatility
        return (strategy.apy * riskMultiplier) / 100;
    }
    
    function _calculateEffectiveAPY(uint256 totalReturn, uint256 timeInYears) internal pure returns (uint256) {
        // Effective APY = (totalReturn)^(1/years) - 1
        // Simplified calculation for small time periods
        if (timeInYears >= PRECISION) {
            return ((totalReturn - PRECISION) * PRECISION) / timeInYears;
        } else {
            return ((totalReturn - PRECISION) * SECONDS_PER_YEAR) / (timeInYears * SECONDS_PER_YEAR / PRECISION);
        }
    }
    
    function _calculatePortfolioBeta(
        YieldStrategy[] memory strategies,
        PortfolioAllocation[] memory allocations
    ) internal pure returns (uint256) {
        // Simplified beta calculation (assumes market beta of 1.0 for all strategies)
        uint256 weightedBeta = 0;
        uint256 totalWeight = 0;
        
        for (uint256 i = 0; i < allocations.length; i++) {
            uint256 weight = allocations[i].allocation;
            weightedBeta += weight; // Assuming beta = 1.0
            totalWeight += weight;
        }
        
        return totalWeight > 0 ? (weightedBeta * PRECISION) / totalWeight : PRECISION;
    }
    
    function _calculateInformationRatio(
        YieldStrategy[] memory strategies,
        PortfolioAllocation[] memory allocations
    ) internal pure returns (uint256) {
        // Information Ratio = Excess Return / Tracking Error
        uint256 portfolioReturn = _calculatePortfolioReturn(strategies, allocations);
        uint256 benchmarkReturn = 500; // 5% benchmark
        
        uint256 excessReturn = portfolioReturn > benchmarkReturn ? portfolioReturn - benchmarkReturn : 0;
        uint256 trackingError = 200; // Simplified 2% tracking error
        
        return trackingError > 0 ? (excessReturn * PRECISION) / trackingError : 0;
    }
    
    function _calculatePortfolioReturn(
        YieldStrategy[] memory strategies,
        PortfolioAllocation[] memory allocations
    ) internal pure returns (uint256) {
        uint256 weightedReturn = 0;
        uint256 totalWeight = 0;
        
        for (uint256 i = 0; i < allocations.length; i++) {
            uint256 strategyId = allocations[i].strategyId;
            uint256 weight = allocations[i].allocation;
            
            if (strategyId < strategies.length) {
                weightedReturn += (strategies[strategyId].apy * weight);
                totalWeight += weight;
            }
        }
        
        return totalWeight > 0 ? weightedReturn / totalWeight : 0;
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