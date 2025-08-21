// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title FeeOptimization - Dynamic Fee Optimization Module
 * @dev Modular component for optimizing trading fees based on market conditions
 * 
 * FEATURES:
 * - Real-time fee adjustment based on volatility and volume
 * - Competitive analysis against other DEXs
 * - Revenue optimization algorithms
 * - Liquidity provider incentive balancing
 * - MEV-aware fee structures
 * - Time-based fee discounts for frequent traders
 * 
 * USE CASES:
 * 1. Maximize DEX revenue while maintaining competitiveness
 * 2. Attract liquidity during low-volume periods
 * 3. Prevent excessive arbitrage during high volatility
 * 4. Reward loyal traders with reduced fees
 * 5. Balance LP rewards with trader costs
 * 
 * @author Nibert Investments LLC
 * @notice Dynamic Fee Optimization for DEX Protocols
 */

contract FeeOptimization {
    uint256 private constant PRECISION = 1e18;
    uint256 private constant BASE_FEE = 3e15; // 0.3% base fee
    uint256 private constant MAX_FEE = 1e16; // 1% maximum fee
    uint256 private constant MIN_FEE = 1e15; // 0.1% minimum fee
    
    struct FeeParameters {
        uint256 baseFee;
        uint256 volatilityMultiplier;
        uint256 volumeDiscountRate;
        uint256 liquidityIncentive;
        uint256 lastUpdate;
        uint256 totalRevenue;
    }
    
    struct TraderProfile {
        uint256 totalVolume;
        uint256 firstTradeTime;
        uint256 lastTradeTime;
        uint256 feesPaid;
        uint256 tradeCount;
        uint256 discountTier;
    }
    
    struct MarketConditions {
        uint256 volatility24h;
        uint256 volume24h;
        uint256 liquidityDepth;
        uint256 competitorFees;
        uint256 lastUpdate;
    }
    
    mapping(bytes32 => FeeParameters) public poolFeeParams;
    mapping(address => TraderProfile) public traderProfiles;
    mapping(bytes32 => MarketConditions) public marketConditions;
    mapping(address => uint256) public volumeDiscounts;
    
    address public governance;
    uint256 public revenueTarget;
    uint256 public competitivenessWeight;
    
    event FeeOptimized(bytes32 indexed poolId, uint256 oldFee, uint256 newFee, string reason);
    event TraderDiscountUpdated(address indexed trader, uint256 oldTier, uint256 newTier);
    event MarketConditionsUpdated(bytes32 indexed poolId, uint256 volatility, uint256 volume);
    
    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance");
        _;
    }
    
    constructor(address _governance, uint256 _revenueTarget) {
        governance = _governance;
        revenueTarget = _revenueTarget;
        competitivenessWeight = 5e17; // 50% weight for competitiveness
    }
    
    /**
     * @dev Calculate optimal fee based on market conditions
     */
    function calculateOptimalFee(
        uint256 volume24h,
        uint256 volatility,
        uint256 totalLiquidity
    ) external view returns (uint256 optimalFee) {
        // Base fee adjustment for volatility
        uint256 volatilityAdjustment = (volatility * 2e15) / PRECISION; // Max 0.2% adjustment
        
        // Volume-based adjustment (higher volume = lower fees)
        uint256 volumeAdjustment = 0;
        if (volume24h > 1e24) { // > $1M daily volume
            volumeAdjustment = 5e14; // -0.05%
        }
        
        // Liquidity depth adjustment
        uint256 liquidityAdjustment = 0;
        if (totalLiquidity < 1e23) { // < $100K liquidity
            liquidityAdjustment = 1e15; // +0.1%
        }
        
        optimalFee = BASE_FEE + volatilityAdjustment + liquidityAdjustment;
        
        if (optimalFee > volumeAdjustment) {
            optimalFee -= volumeAdjustment;
        }
        
        // Ensure fee is within bounds
        if (optimalFee > MAX_FEE) optimalFee = MAX_FEE;
        if (optimalFee < MIN_FEE) optimalFee = MIN_FEE;
        
        return optimalFee;
    }
    
    /**
     * @dev Update trader profile and calculate personalized fee
     */
    function updateTraderProfile(
        address trader,
        uint256 tradeVolume,
        uint256 feesPaid
    ) external returns (uint256 personalizedFee) {
        TraderProfile storage profile = traderProfiles[trader];
        
        if (profile.firstTradeTime == 0) {
            profile.firstTradeTime = block.timestamp;
        }
        
        profile.totalVolume += tradeVolume;
        profile.lastTradeTime = block.timestamp;
        profile.feesPaid += feesPaid;
        profile.tradeCount++;
        
        // Calculate discount tier based on volume and loyalty
        uint256 newTier = calculateDiscountTier(profile);
        
        if (newTier != profile.discountTier) {
            emit TraderDiscountUpdated(trader, profile.discountTier, newTier);
            profile.discountTier = newTier;
        }
        
        // Calculate personalized fee
        personalizedFee = BASE_FEE;
        
        // Apply volume discount
        if (profile.discountTier > 0) {
            uint256 discount = profile.discountTier * 1e14; // 0.01% per tier
            personalizedFee = personalizedFee > discount ? personalizedFee - discount : MIN_FEE;
        }
        
        return personalizedFee;
    }
    
    /**
     * @dev Advanced fee optimization using machine learning-like algorithms
     */
    function optimizeFeeWithML(
        bytes32 poolId,
        uint256[] calldata priceHistory,
        uint256[] calldata volumeHistory,
        uint256[] calldata competitorFees
    ) external returns (uint256 optimizedFee) {
        require(priceHistory.length == volumeHistory.length, "Mismatched data lengths");
        
        FeeParameters storage params = poolFeeParams[poolId];
        
        // Calculate volatility from price history
        uint256 volatility = calculateVolatility(priceHistory);
        
        // Calculate volume trend
        uint256 volumeTrend = calculateTrend(volumeHistory);
        
        // Calculate competitive positioning
        uint256 avgCompetitorFee = calculateAverage(competitorFees);
        
        // ML-inspired optimization
        uint256 volatilityComponent = (volatility * 1e15) / PRECISION; // Volatility factor
        uint256 volumeComponent = volumeTrend > PRECISION ? 0 : 5e14; // Penalty for declining volume
        uint256 competitiveComponent = (avgCompetitorFee * competitivenessWeight) / PRECISION;
        
        optimizedFee = BASE_FEE + volatilityComponent + volumeComponent;
        
        // Adjust based on competitive landscape
        if (optimizedFee > competitiveComponent) {
            uint256 adjustment = (optimizedFee - competitiveComponent) / 2;
            optimizedFee -= adjustment;
        }
        
        // Revenue target adjustment
        if (params.totalRevenue < revenueTarget) {
            optimizedFee += 2e14; // +0.02% to meet revenue targets
        }
        
        // Bounds checking
        if (optimizedFee > MAX_FEE) optimizedFee = MAX_FEE;
        if (optimizedFee < MIN_FEE) optimizedFee = MIN_FEE;
        
        // Update parameters
        params.baseFee = optimizedFee;
        params.lastUpdate = block.timestamp;
        
        emit FeeOptimized(poolId, params.baseFee, optimizedFee, "ML optimization");
        
        return optimizedFee;
    }
    
    /**
     * @dev Dynamic fee adjustment for MEV protection
     */
    function adjustFeeForMEV(
        bytes32 poolId,
        uint256 frontrunningRisk,
        uint256 sandwichAttackRisk
    ) external returns (uint256 adjustedFee) {
        FeeParameters storage params = poolFeeParams[poolId];
        
        // Base fee from current parameters
        adjustedFee = params.baseFee;
        
        // MEV protection surcharge
        uint256 mevSurcharge = 0;
        
        if (frontrunningRisk > 7e17) { // > 70% risk
            mevSurcharge += 3e14; // +0.03%
        } else if (frontrunningRisk > 5e17) { // > 50% risk
            mevSurcharge += 1e14; // +0.01%
        }
        
        if (sandwichAttackRisk > 6e17) { // > 60% risk
            mevSurcharge += 5e14; // +0.05%
        } else if (sandwichAttackRisk > 4e17) { // > 40% risk
            mevSurcharge += 2e14; // +0.02%
        }
        
        adjustedFee += mevSurcharge;
        
        // Ensure bounds
        if (adjustedFee > MAX_FEE) adjustedFee = MAX_FEE;
        
        emit FeeOptimized(poolId, params.baseFee, adjustedFee, "MEV protection");
        
        return adjustedFee;
    }
    
    /**
     * @dev Time-based fee adjustment (lower fees during off-peak hours)
     */
    function getTimeBasedFee(
        bytes32 poolId,
        uint256 baseFee
    ) external view returns (uint256 adjustedFee) {
        uint256 hourOfDay = (block.timestamp / 3600) % 24;
        
        // Lower fees during off-peak hours (2 AM - 6 AM UTC)
        if (hourOfDay >= 2 && hourOfDay <= 6) {
            uint256 discount = baseFee / 10; // 10% discount
            adjustedFee = baseFee - discount;
        } else if (hourOfDay >= 14 && hourOfDay <= 18) {
            // Higher fees during peak trading hours
            uint256 premium = baseFee / 20; // 5% premium
            adjustedFee = baseFee + premium;
        } else {
            adjustedFee = baseFee;
        }
        
        return adjustedFee;
    }
    
    /**
     * @dev Calculate revenue-optimal fee structure
     */
    function calculateRevenueOptimalFee(
        uint256 elasticity,
        uint256 currentVolume,
        uint256 currentFee
    ) external pure returns (uint256 optimalFee) {
        // Price elasticity of demand optimization
        // Optimal fee = current_fee * (1 + 1/elasticity)
        
        if (elasticity == 0) return currentFee;
        
        uint256 elasticityFactor = PRECISION + (PRECISION * PRECISION) / elasticity;
        optimalFee = (currentFee * elasticityFactor) / PRECISION;
        
        // Ensure reasonable bounds
        if (optimalFee > MAX_FEE) optimalFee = MAX_FEE;
        if (optimalFee < MIN_FEE) optimalFee = MIN_FEE;
        
        return optimalFee;
    }
    
    /**
     * @dev Multi-objective optimization (revenue, competitiveness, user satisfaction)
     */
    function multiObjectiveOptimization(
        bytes32 poolId,
        uint256 revenueWeight,
        uint256 competitivenessWeight_,
        uint256 satisfactionWeight
    ) external view returns (uint256 optimalFee) {
        require(revenueWeight + competitivenessWeight_ + satisfactionWeight == PRECISION, "Weights must sum to 1");
        
        FeeParameters storage params = poolFeeParams[poolId];
        MarketConditions storage market = marketConditions[poolId];
        
        // Revenue optimization component
        uint256 revenueOptimal = params.baseFee * 110 / 100; // 10% increase for revenue
        
        // Competitiveness component
        uint256 competitiveOptimal = market.competitorFees * 95 / 100; // 5% below competitors
        
        // User satisfaction component (lower fees = higher satisfaction)
        uint256 satisfactionOptimal = params.baseFee * 90 / 100; // 10% decrease for satisfaction
        
        // Weighted combination
        optimalFee = (revenueOptimal * revenueWeight +
                     competitiveOptimal * competitivenessWeight_ +
                     satisfactionOptimal * satisfactionWeight) / PRECISION;
        
        // Ensure bounds
        if (optimalFee > MAX_FEE) optimalFee = MAX_FEE;
        if (optimalFee < MIN_FEE) optimalFee = MIN_FEE;
        
        return optimalFee;
    }
    
    // Internal helper functions
    function calculateDiscountTier(TraderProfile memory profile) internal pure returns (uint256) {
        uint256 tier = 0;
        
        // Volume-based tiers
        if (profile.totalVolume >= 1e26) tier += 5; // $100M+
        else if (profile.totalVolume >= 1e25) tier += 4; // $10M+
        else if (profile.totalVolume >= 1e24) tier += 3; // $1M+
        else if (profile.totalVolume >= 1e23) tier += 2; // $100K+
        else if (profile.totalVolume >= 1e22) tier += 1; // $10K+
        
        // Loyalty bonus (trading for > 90 days)
        if (block.timestamp > profile.firstTradeTime + 90 days) {
            tier += 1;
        }
        
        // Frequency bonus (> 100 trades)
        if (profile.tradeCount > 100) {
            tier += 1;
        }
        
        return tier > 10 ? 10 : tier; // Max tier 10
    }
    
    function calculateVolatility(uint256[] calldata prices) internal pure returns (uint256) {
        if (prices.length < 2) return 0;
        
        uint256 sum = 0;
        for (uint256 i = 0; i < prices.length; i++) {
            sum += prices[i];
        }
        uint256 mean = sum / prices.length;
        
        uint256 variance = 0;
        for (uint256 i = 0; i < prices.length; i++) {
            uint256 diff = prices[i] > mean ? prices[i] - mean : mean - prices[i];
            variance += (diff * diff) / PRECISION;
        }
        variance = variance / prices.length;
        
        return sqrt(variance);
    }
    
    function calculateTrend(uint256[] calldata data) internal pure returns (uint256) {
        if (data.length < 2) return PRECISION;
        
        uint256 firstHalf = 0;
        uint256 secondHalf = 0;
        uint256 midPoint = data.length / 2;
        
        for (uint256 i = 0; i < midPoint; i++) {
            firstHalf += data[i];
        }
        
        for (uint256 i = midPoint; i < data.length; i++) {
            secondHalf += data[i];
        }
        
        firstHalf = firstHalf / midPoint;
        secondHalf = secondHalf / (data.length - midPoint);
        
        return secondHalf == 0 ? PRECISION : (secondHalf * PRECISION) / firstHalf;
    }
    
    function calculateAverage(uint256[] calldata data) internal pure returns (uint256) {
        if (data.length == 0) return 0;
        
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
        
        return sum / data.length;
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
    
    // Governance functions
    function setRevenueTarget(uint256 _revenueTarget) external onlyGovernance {
        revenueTarget = _revenueTarget;
    }
    
    function setCompetitivenessWeight(uint256 _weight) external onlyGovernance {
        require(_weight <= PRECISION, "Weight too high");
        competitivenessWeight = _weight;
    }
}