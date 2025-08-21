// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title LiquidityManagement - Advanced Liquidity Management Module
 * @dev Modular component for optimizing liquidity provision and management
 * 
 * FEATURES:
 * - Concentrated liquidity with tick-based system
 * - Automated liquidity rebalancing
 * - Impermanent loss protection mechanisms
 * - Dynamic range adjustment based on volatility
 * - Liquidity mining optimization
 * - Cross-pool liquidity aggregation
 * 
 * USE CASES:
 * 1. Concentrated liquidity provision for maximum capital efficiency
 * 2. Automated market making with dynamic ranges
 * 3. Liquidity mining optimization strategies
 * 4. Cross-DEX arbitrage liquidity management
 * 5. Institutional liquidity provision services
 * 
 * @author Nibert Investments LLC
 * @notice Modular Liquidity Management for Advanced DEX Systems
 */

contract LiquidityManagement {
    uint256 private constant PRECISION = 1e18;
    uint256 private constant TICK_BASE = 1001; // 0.01% per tick
    
    struct LiquidityPosition {
        address provider;
        int24 tickLower;
        int24 tickUpper;
        uint256 liquidity;
        uint256 feeGrowthInside0Last;
        uint256 feeGrowthInside1Last;
        uint256 tokensOwed0;
        uint256 tokensOwed1;
        uint256 lastUpdate;
    }
    
    struct TickInfo {
        uint256 liquidityGross;
        int256 liquidityNet;
        uint256 feeGrowthOutside0;
        uint256 feeGrowthOutside1;
        bool initialized;
    }
    
    mapping(bytes32 => mapping(int24 => TickInfo)) public ticks;
    mapping(bytes32 => mapping(address => LiquidityPosition[])) public positions;
    mapping(bytes32 => uint256) public feeGrowthGlobal0;
    mapping(bytes32 => uint256) public feeGrowthGlobal1;
    
    event LiquidityPositionCreated(address indexed provider, bytes32 indexed poolId, int24 tickLower, int24 tickUpper);
    event LiquidityRebalanced(bytes32 indexed poolId, int24 oldLower, int24 oldUpper, int24 newLower, int24 newUpper);
    
    /**
     * @dev Calculate optimal liquidity amounts for concentrated liquidity
     */
    function calculateConcentratedLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        int24 tickLower,
        int24 tickUpper,
        uint256 currentPrice
    ) external pure returns (uint256 amountA, uint256 amountB) {
        uint256 priceLower = tickToPrice(tickLower);
        uint256 priceUpper = tickToPrice(tickUpper);
        
        if (currentPrice <= priceLower) {
            // All amount A
            return (amountADesired, 0);
        } else if (currentPrice >= priceUpper) {
            // All amount B
            return (0, amountBDesired);
        } else {
            // Mixed amounts based on current price within range
            uint256 liquidityA = (amountADesired * PRECISION) / sqrt(currentPrice);
            uint256 liquidityB = (amountBDesired * sqrt(currentPrice)) / PRECISION;
            
            uint256 liquidity = liquidityA < liquidityB ? liquidityA : liquidityB;
            
            amountA = (liquidity * sqrt(currentPrice)) / PRECISION;
            amountB = (liquidity * PRECISION) / sqrt(currentPrice);
            
            return (amountA, amountB);
        }
    }
    
    /**
     * @dev Create a new concentrated liquidity position
     */
    function createPosition(
        bytes32 poolId,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external returns (uint256 tokenId) {
        require(tickLower < tickUpper, "Invalid tick range");
        require(tickLower >= -887220 && tickUpper <= 887220, "Tick out of range");
        
        // Calculate liquidity amount
        uint256 liquidity = calculateLiquidityAmount(
            amount0Desired,
            amount1Desired,
            tickLower,
            tickUpper
        );
        
        // Update tick data
        updateTick(poolId, tickLower, int256(liquidity));
        updateTick(poolId, tickUpper, -int256(liquidity));
        
        // Create position
        positions[poolId][msg.sender].push(LiquidityPosition({
            provider: msg.sender,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            feeGrowthInside0Last: 0,
            feeGrowthInside1Last: 0,
            tokensOwed0: 0,
            tokensOwed1: 0,
            lastUpdate: block.timestamp
        }));
        
        emit LiquidityPositionCreated(msg.sender, poolId, tickLower, tickUpper);
        
        return positions[poolId][msg.sender].length - 1;
    }
    
    /**
     * @dev Automatically rebalance liquidity position based on market conditions
     */
    function rebalancePosition(
        bytes32 poolId,
        uint256 positionId,
        uint256 currentPrice,
        uint256 volatility
    ) external returns (int24 newTickLower, int24 newTickUpper) {
        LiquidityPosition storage position = positions[poolId][msg.sender][positionId];
        require(position.provider == msg.sender, "Not position owner");
        
        // Calculate new optimal range based on volatility
        int24 currentTick = priceToTick(currentPrice);
        int24 volatilityTicks = int24(int256(volatility * 1000 / PRECISION)); // Convert volatility to ticks
        
        newTickLower = currentTick - volatilityTicks * 2;
        newTickUpper = currentTick + volatilityTicks * 2;
        
        // Ensure ticks are within bounds and properly spaced
        newTickLower = alignTickToSpacing(newTickLower);
        newTickUpper = alignTickToSpacing(newTickUpper);
        
        // Update position if range changed significantly
        if (abs(newTickLower - position.tickLower) > TICK_SPACING * 10 ||
            abs(newTickUpper - position.tickUpper) > TICK_SPACING * 10) {
            
            // Remove old position
            updateTick(poolId, position.tickLower, -int256(position.liquidity));
            updateTick(poolId, position.tickUpper, int256(position.liquidity));
            
            // Update position range
            position.tickLower = newTickLower;
            position.tickUpper = newTickUpper;
            position.lastUpdate = block.timestamp;
            
            // Add new position
            updateTick(poolId, newTickLower, int256(position.liquidity));
            updateTick(poolId, newTickUpper, -int256(position.liquidity));
            
            emit LiquidityRebalanced(poolId, position.tickLower, position.tickUpper, newTickLower, newTickUpper);
        }
        
        return (newTickLower, newTickUpper);
    }
    
    /**
     * @dev Calculate impermanent loss for a liquidity position
     */
    function calculateImpermanentLoss(
        uint256 initialPrice,
        uint256 currentPrice,
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint256 impermanentLoss) {
        // IL = 2 * sqrt(price_ratio) / (1 + price_ratio) - 1
        uint256 priceRatio = (currentPrice * PRECISION) / initialPrice;
        uint256 sqrtRatio = sqrt(priceRatio);
        
        uint256 poolValue = (2 * sqrtRatio * PRECISION) / (PRECISION + priceRatio);
        uint256 holdValue = PRECISION; // Normalized to 1
        
        if (poolValue < holdValue) {
            impermanentLoss = holdValue - poolValue;
        } else {
            impermanentLoss = 0; // No loss (actually gain)
        }
        
        return impermanentLoss;
    }
    
    /**
     * @dev Calculate accumulated fees for a position
     */
    function calculateAccumulatedFees(
        bytes32 poolId,
        address provider,
        uint256 positionId
    ) external view returns (uint256 fees0, uint256 fees1) {
        LiquidityPosition storage position = positions[poolId][provider][positionId];
        
        (uint256 feeGrowthInside0, uint256 feeGrowthInside1) = getFeeGrowthInside(
            poolId,
            position.tickLower,
            position.tickUpper
        );
        
        fees0 = ((feeGrowthInside0 - position.feeGrowthInside0Last) * position.liquidity) / PRECISION;
        fees1 = ((feeGrowthInside1 - position.feeGrowthInside1Last) * position.liquidity) / PRECISION;
        
        return (fees0 + position.tokensOwed0, fees1 + position.tokensOwed1);
    }
    
    /**
     * @dev Optimize liquidity distribution across multiple pools
     */
    function optimizeLiquidityDistribution(
        bytes32[] calldata poolIds,
        uint256[] calldata poolWeights,
        uint256 totalLiquidity
    ) external pure returns (uint256[] memory allocations) {
        require(poolIds.length == poolWeights.length, "Mismatched arrays");
        
        allocations = new uint256[](poolIds.length);
        uint256 totalWeight = 0;
        
        // Calculate total weight
        for (uint256 i = 0; i < poolWeights.length; i++) {
            totalWeight += poolWeights[i];
        }
        
        // Distribute liquidity proportionally
        for (uint256 i = 0; i < poolIds.length; i++) {
            allocations[i] = (totalLiquidity * poolWeights[i]) / totalWeight;
        }
        
        return allocations;
    }
    
    // Internal functions
    function updateTick(bytes32 poolId, int24 tick, int256 liquidityDelta) internal {
        TickInfo storage tickInfo = ticks[poolId][tick];
        
        if (liquidityDelta < 0) {
            tickInfo.liquidityGross -= uint256(-liquidityDelta);
        } else {
            tickInfo.liquidityGross += uint256(liquidityDelta);
        }
        
        tickInfo.liquidityNet += liquidityDelta;
        tickInfo.initialized = tickInfo.liquidityGross > 0;
    }
    
    function calculateLiquidityAmount(
        uint256 amount0,
        uint256 amount1,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (uint256 liquidity) {
        uint256 priceLower = tickToPrice(tickLower);
        uint256 priceUpper = tickToPrice(tickUpper);
        
        uint256 liquidity0 = (amount0 * PRECISION) / (sqrt(priceUpper) - sqrt(priceLower));
        uint256 liquidity1 = amount1 / (sqrt(priceUpper) - sqrt(priceLower));
        
        return liquidity0 < liquidity1 ? liquidity0 : liquidity1;
    }
    
    function getFeeGrowthInside(
        bytes32 poolId,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (uint256 feeGrowthInside0, uint256 feeGrowthInside1) {
        TickInfo storage lower = ticks[poolId][tickLower];
        TickInfo storage upper = ticks[poolId][tickUpper];
        
        // Simplified fee calculation
        feeGrowthInside0 = feeGrowthGlobal0[poolId] - lower.feeGrowthOutside0 - upper.feeGrowthOutside0;
        feeGrowthInside1 = feeGrowthGlobal1[poolId] - lower.feeGrowthOutside1 - upper.feeGrowthOutside1;
    }
    
    function tickToPrice(int24 tick) internal pure returns (uint256) {
        // Convert tick to price: price = 1.0001^tick
        if (tick == 0) return PRECISION;
        
        uint256 absTick = tick < 0 ? uint256(-tick) : uint256(tick);
        uint256 price = PRECISION;
        
        // Simplified calculation - in production, use more precise math
        for (uint256 i = 0; i < absTick; i++) {
            price = (price * TICK_BASE) / 1000;
        }
        
        return tick < 0 ? (PRECISION * PRECISION) / price : price;
    }
    
    function priceToTick(uint256 price) internal pure returns (int24) {
        // Convert price to tick (simplified)
        if (price == PRECISION) return 0;
        
        // Binary search or approximation would be used here
        // Simplified for demonstration
        return price > PRECISION ? int24(100) : int24(-100);
    }
    
    function alignTickToSpacing(int24 tick) internal pure returns (int24) {
        return (tick / TICK_SPACING) * TICK_SPACING;
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
    
    function abs(int24 a) internal pure returns (int24) {
        return a >= 0 ? a : -a;
    }
}