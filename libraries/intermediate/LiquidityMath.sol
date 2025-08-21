// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../basic/MathUtils.sol";

/**
 * @title LiquidityMath - Advanced AMM and Liquidity Pool Mathematics
 * @dev Sophisticated mathematical library for automated market makers
 * 
 * FEATURES:
 * - Constant product and sum formulas with precision handling
 * - Impermanent loss calculations and hedging strategies
 * - Multi-asset pool mathematics and optimization
 * - Dynamic fee calculation based on volatility and volume
 * - Advanced slippage protection and MEV resistance
 * 
 * USE CASES:
 * 1. Automated Market Maker (AMM) protocol implementation
 * 2. Liquidity pool optimization and rebalancing
 * 3. Impermanent loss protection mechanisms
 * 4. Dynamic fee adjustment algorithms
 * 5. Multi-asset portfolio rebalancing
 * 6. Cross-chain liquidity bridge calculations
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library LiquidityMath {
    using MathUtils for uint256;
    
    // Precision constants
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MAX_FEE = 1000; // 10% max fee (in basis points)
    uint256 private constant MIN_LIQUIDITY = 1000; // Minimum liquidity to prevent attacks
    
    // Pool types
    enum PoolType {
        ConstantProduct,    // x * y = k (Uniswap style)
        ConstantSum,        // x + y = k (stable pairs)
        WeightedProduct,    // x^w1 * y^w2 = k (Balancer style)
        Curve,             // Custom curve for stable coins
        Hybrid             // Combination of multiple formulas
    }
    
    struct Pool {
        uint256 reserveX;
        uint256 reserveY;
        uint256 totalSupply;
        uint256 feeRate;          // In basis points (10000 = 100%)
        uint256 weightX;          // Weight for asset X (only for weighted pools)
        uint256 weightY;          // Weight for asset Y (only for weighted pools)
        PoolType poolType;
        uint256 amplificationFactor; // For curve pools
        uint256 lastUpdateTime;
        uint256 cumulativePriceX;
        uint256 cumulativePriceY;
    }
    
    /**
     * @dev Calculates output amount for constant product formula (x * y = k)
     * Use Case: Uniswap-style AMM swap calculations
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeRate
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "LiquidityMath: insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "LiquidityMath: insufficient liquidity");
        
        uint256 amountInWithFee = amountIn * (10000 - feeRate);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 10000) + amountInWithFee;
        
        amountOut = numerator / denominator;
    }
    
    /**
     * @dev Calculates input amount needed for desired output (constant product)
     * Use Case: Reverse swap calculations, exact output swaps
     */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeRate
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "LiquidityMath: insufficient output amount");
        require(reserveIn > 0 && reserveOut > amountOut, "LiquidityMath: insufficient liquidity");
        
        uint256 numerator = reserveIn * amountOut * 10000;
        uint256 denominator = (reserveOut - amountOut) * (10000 - feeRate);
        
        amountIn = (numerator / denominator) + 1; // Add 1 for rounding up
    }
    
    /**
     * @dev Calculates liquidity tokens to mint for adding liquidity
     * Use Case: Liquidity provision, pool participation
     */
    function getLiquidityMinted(
        Pool memory pool,
        uint256 amountX,
        uint256 amountY
    ) internal pure returns (uint256 liquidity) {
        if (pool.totalSupply == 0) {
            // First liquidity provision
            liquidity = MathUtils.sqrt(amountX * amountY);
            require(liquidity > MIN_LIQUIDITY, "LiquidityMath: minimum liquidity not met");
            liquidity -= MIN_LIQUIDITY; // Permanently lock minimum liquidity
        } else {
            // Subsequent liquidity provision
            uint256 liquidityX = (amountX * pool.totalSupply) / pool.reserveX;
            uint256 liquidityY = (amountY * pool.totalSupply) / pool.reserveY;
            liquidity = liquidityX < liquidityY ? liquidityX : liquidityY;
        }
    }
    
    /**
     * @dev Calculates assets returned when burning liquidity tokens
     * Use Case: Liquidity withdrawal, pool exit
     */
    function getLiquidityValue(
        Pool memory pool,
        uint256 liquidityAmount
    ) internal pure returns (uint256 amountX, uint256 amountY) {
        require(liquidityAmount > 0, "LiquidityMath: zero liquidity");
        require(liquidityAmount <= pool.totalSupply, "LiquidityMath: insufficient liquidity");
        
        amountX = (liquidityAmount * pool.reserveX) / pool.totalSupply;
        amountY = (liquidityAmount * pool.reserveY) / pool.totalSupply;
    }
    
    /**
     * @dev Calculates current spot price of asset X in terms of asset Y
     * Use Case: Price discovery, portfolio valuation
     */
    function getSpotPrice(Pool memory pool) internal pure returns (uint256) {
        require(pool.reserveX > 0 && pool.reserveY > 0, "LiquidityMath: no reserves");
        
        if (pool.poolType == PoolType.ConstantProduct) {
            return (pool.reserveY * PRECISION) / pool.reserveX;
        } else if (pool.poolType == PoolType.WeightedProduct) {
            // Price = (reserveY / weightY) / (reserveX / weightX)
            return (pool.reserveY * pool.weightX * PRECISION) / (pool.reserveX * pool.weightY);
        } else {
            // Default to constant product
            return (pool.reserveY * PRECISION) / pool.reserveX;
        }
    }
    
    /**
     * @dev Calculates impermanent loss for liquidity providers
     * Use Case: Risk assessment, LP compensation calculations
     */
    function calculateImpermanentLoss(
        uint256 initialPriceRatio,
        uint256 currentPriceRatio
    ) internal pure returns (uint256 impermanentLoss) {
        require(initialPriceRatio > 0 && currentPriceRatio > 0, "LiquidityMath: invalid price ratio");
        
        // IL = 2 * sqrt(r) / (1 + r) - 1, where r = currentPrice / initialPrice
        uint256 ratio = (currentPriceRatio * PRECISION) / initialPriceRatio;
        uint256 sqrtRatio = MathUtils.sqrt(ratio);
        
        uint256 numerator = 2 * sqrtRatio;
        uint256 denominator = PRECISION + ratio;
        
        uint256 holdValue = (numerator * PRECISION) / denominator;
        
        if (holdValue < PRECISION) {
            impermanentLoss = PRECISION - holdValue;
        } else {
            impermanentLoss = 0; // No impermanent loss (actually a gain)
        }
    }
    
    /**
     * @dev Calculates optimal arbitrage amount to restore price equilibrium
     * Use Case: MEV strategies, arbitrage optimization
     */
    function calculateArbitrageAmount(
        uint256 reserveX,
        uint256 reserveY,
        uint256 externalPrice,
        uint256 feeRate
    ) internal pure returns (uint256 arbitrageAmount, bool isXToY) {
        uint256 currentPrice = (reserveY * PRECISION) / reserveX;
        
        if (currentPrice == externalPrice) {
            return (0, true); // No arbitrage opportunity
        }
        
        isXToY = currentPrice > externalPrice;
        
        if (isXToY) {
            // Calculate optimal amount of X to sell
            uint256 k = reserveX * reserveY;
            uint256 feeMultiplier = 10000 - feeRate;
            
            uint256 numerator = MathUtils.sqrt(k * externalPrice * 10000) - (reserveX * feeMultiplier);
            arbitrageAmount = numerator / feeMultiplier;
        } else {
            // Calculate optimal amount of Y to sell
            uint256 k = reserveX * reserveY;
            uint256 feeMultiplier = 10000 - feeRate;
            
            uint256 numerator = MathUtils.sqrt(k * 10000 * PRECISION / externalPrice) - (reserveY * feeMultiplier);
            arbitrageAmount = numerator / feeMultiplier;
        }
    }
    
    /**
     * @dev Calculates dynamic fee based on volatility and volume
     * Use Case: Adaptive fee structures, risk-based pricing
     */
    function calculateDynamicFee(
        uint256 baseFeeBps,
        uint256 volatility,
        uint256 volume,
        uint256 utilizationRate
    ) internal pure returns (uint256 dynamicFee) {
        // Base fee with volatility adjustment
        uint256 volatilityAdjustment = (volatility * 100) / PRECISION; // Convert to basis points
        
        // Volume adjustment (higher volume = lower fees)
        uint256 volumeDiscount = volume > PRECISION ? 50 : 0; // 0.5% discount for high volume
        
        // Utilization adjustment (higher utilization = higher fees)
        uint256 utilizationAdjustment = (utilizationRate * 200) / PRECISION; // Up to 2% additional
        
        dynamicFee = baseFeeBps + volatilityAdjustment + utilizationAdjustment;
        
        if (dynamicFee > volumeDiscount) {
            dynamicFee -= volumeDiscount;
        }
        
        // Cap at maximum fee
        if (dynamicFee > MAX_FEE) {
            dynamicFee = MAX_FEE;
        }
    }
    
    /**
     * @dev Calculates slippage for a given trade size
     * Use Case: Slippage protection, trade impact assessment
     */
    function calculateSlippage(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeRate
    ) internal pure returns (uint256 slippagePercentage) {
        uint256 spotPrice = (reserveOut * PRECISION) / reserveIn;
        uint256 amountOut = getAmountOut(amountIn, reserveIn, reserveOut, feeRate);
        uint256 effectivePrice = (amountOut * PRECISION) / amountIn;
        
        if (spotPrice > effectivePrice) {
            slippagePercentage = ((spotPrice - effectivePrice) * 10000) / spotPrice;
        } else {
            slippagePercentage = 0;
        }
    }
    
    /**
     * @dev Calculates optimal rebalancing amounts for multi-asset pools
     * Use Case: Portfolio rebalancing, asset allocation optimization
     */
    function calculateRebalancing(
        uint256[] memory currentAmounts,
        uint256[] memory targetWeights,
        uint256 totalValue
    ) internal pure returns (uint256[] memory adjustments, bool[] memory isIncrease) {
        require(currentAmounts.length == targetWeights.length, "LiquidityMath: array length mismatch");
        
        adjustments = new uint256[](currentAmounts.length);
        isIncrease = new bool[](currentAmounts.length);
        
        for (uint256 i = 0; i < currentAmounts.length; i++) {
            uint256 targetAmount = (totalValue * targetWeights[i]) / PRECISION;
            
            if (targetAmount > currentAmounts[i]) {
                adjustments[i] = targetAmount - currentAmounts[i];
                isIncrease[i] = true;
            } else {
                adjustments[i] = currentAmounts[i] - targetAmount;
                isIncrease[i] = false;
            }
        }
    }
    
    /**
     * @dev Calculates time-weighted average price (TWAP)
     * Use Case: Price oracles, manipulation resistance
     */
    function calculateTWAP(
        uint256[] memory prices,
        uint256[] memory timestamps,
        uint256 windowSize
    ) internal view returns (uint256 twap) {
        require(prices.length == timestamps.length, "LiquidityMath: array length mismatch");
        require(prices.length >= 2, "LiquidityMath: insufficient data points");
        
        uint256 currentTime = block.timestamp;
        uint256 startTime = currentTime > windowSize ? currentTime - windowSize : 0;
        
        uint256 weightedSum = 0;
        uint256 totalWeight = 0;
        
        for (uint256 i = 0; i < prices.length - 1; i++) {
            if (timestamps[i] >= startTime) {
                uint256 weight = timestamps[i + 1] - timestamps[i];
                weightedSum += prices[i] * weight;
                totalWeight += weight;
            }
        }
        
        require(totalWeight > 0, "LiquidityMath: no data in time window");
        twap = weightedSum / totalWeight;
    }
    
    /**
     * @dev Calculates optimal pool allocation for yield farming
     * Use Case: Yield optimization, capital efficiency
     */
    function calculateOptimalAllocation(
        uint256[] memory poolRewards,
        uint256[] memory poolRisks,
        uint256[] memory poolLiquidity,
        uint256 totalCapital,
        uint256 riskTolerance
    ) internal pure returns (uint256[] memory allocations) {
        require(
            poolRewards.length == poolRisks.length && 
            poolRisks.length == poolLiquidity.length,
            "LiquidityMath: array length mismatch"
        );
        
        allocations = new uint256[](poolRewards.length);
        uint256 totalScore = 0;
        uint256[] memory scores = new uint256[](poolRewards.length);
        
        // Calculate risk-adjusted scores for each pool
        for (uint256 i = 0; i < poolRewards.length; i++) {
            if (poolRisks[i] <= riskTolerance && poolLiquidity[i] > 0) {
                // Score = (reward / risk) * liquidity_factor
                uint256 rewardRiskRatio = (poolRewards[i] * PRECISION) / poolRisks[i];
                uint256 liquidityFactor = MathUtils.sqrt(poolLiquidity[i]);
                scores[i] = (rewardRiskRatio * liquidityFactor) / PRECISION;
                totalScore += scores[i];
            }
        }
        
        // Allocate capital proportionally to scores
        for (uint256 i = 0; i < poolRewards.length; i++) {
            if (totalScore > 0) {
                allocations[i] = (totalCapital * scores[i]) / totalScore;
            }
        }
    }
    
    /**
     * @dev Calculates maximum extractable value (MEV) for sandwich attacks
     * Use Case: MEV detection, protection mechanisms
     */
    function calculateMEVOpportunity(
        uint256 frontrunAmount,
        uint256 victimAmount,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 feeRate
    ) internal pure returns (uint256 mevProfit) {
        // Calculate state after frontrun
        uint256 amountOut1 = getAmountOut(frontrunAmount, reserveIn, reserveOut, feeRate);
        uint256 newReserveIn = reserveIn + frontrunAmount;
        uint256 newReserveOut = reserveOut - amountOut1;
        
        // Calculate victim's trade in new state
        uint256 victimOut = getAmountOut(victimAmount, newReserveIn, newReserveOut, feeRate);
        uint256 finalReserveIn = newReserveIn + victimAmount;
        uint256 finalReserveOut = newReserveOut - victimOut;
        
        // Calculate backrun profit
        uint256 backrunOut = getAmountOut(amountOut1, finalReserveOut, finalReserveIn, feeRate);
        
        if (backrunOut > frontrunAmount) {
            mevProfit = backrunOut - frontrunAmount;
        } else {
            mevProfit = 0;
        }
    }
}