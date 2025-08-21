// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title HighFrequencyTrading - Ultra-Fast Algorithmic Trading Library
 * @dev Sophisticated HFT algorithms and market microstructure implementations
 * 
 * FEATURES:
 * - Ultra-low latency order execution algorithms
 * - Market making with optimal bid-ask spread calculation
 * - Arbitrage detection across multiple venues
 * - Statistical arbitrage and mean reversion strategies
 * - Order flow toxicity detection and protection
 * - High-frequency market data processing and analysis
 * 
 * USE CASES:
 * 1. Automated market making protocols with optimal spreads
 * 2. Cross-exchange arbitrage bots with latency optimization
 * 3. High-frequency statistical arbitrage strategies
 * 4. Order flow analysis and market impact modeling
 * 5. Dynamic hedging algorithms for derivatives
 * 6. Real-time risk management for HFT strategies
 * 
 * @author Nibert Investments LLC
 * @notice Master Level - Institutional-grade HFT algorithms
 */

library HighFrequencyTrading {
    // Error definitions
    error LatencyTooHigh();
    error InsufficientLiquidity();
    error MarketImpactTooHigh();
    error OrderFlowToxic();
    error ArbitrageOpportunityExpired();
    error RiskLimitExceeded();
    error InvalidMarketData();
    
    // Events
    event OrderExecuted(bytes32 indexed orderId, uint256 price, uint256 quantity, uint256 latency);
    event ArbitrageDetected(address indexed venue1, address indexed venue2, uint256 profit);
    event MarketMade(uint256 bidPrice, uint256 askPrice, uint256 spread);
    event RiskBreach(string indexed riskType, uint256 currentLevel, uint256 limit);
    event StrategySignal(string indexed strategy, int256 signal, uint256 confidence);
    
    // Constants for HFT operations
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MAX_LATENCY_MS = 1; // 1 millisecond max latency
    uint256 private constant TICK_SIZE = 1e15; // 0.001 price increment
    uint256 private constant MAX_POSITION_SIZE = 1000000 * PRECISION;
    uint256 private constant RISK_FREE_RATE = 5e16; // 5% annual
    
    // Market data structure
    struct MarketData {
        uint256 bidPrice;
        uint256 askPrice;
        uint256 bidSize;
        uint256 askSize;
        uint256 lastPrice;
        uint256 volume;
        uint256 timestamp;
        uint256 vwap;
        uint256 volatility;
    }
    
    // Order book level
    struct BookLevel {
        uint256 price;
        uint256 quantity;
        uint256 orders;
        uint256 timestamp;
    }
    
    // HFT strategy parameters
    struct StrategyParams {
        uint256 maxPositionSize;
        uint256 maxOrderSize;
        uint256 riskLimit;
        uint256 latencyThreshold;
        uint256 minProfitThreshold;
        bool enableArbitrage;
        bool enableMarketMaking;
        bool enableStatArb;
    }
    
    // Trade execution result
    struct ExecutionResult {
        uint256 executedPrice;
        uint256 executedQuantity;
        uint256 marketImpact;
        uint256 slippage;
        uint256 latency;
        bool success;
    }
    
    // Statistical arbitrage signals
    struct StatArbSignal {
        int256 zscore;
        uint256 halfLife;
        uint256 confidence;
        bool isLong;
        uint256 targetPosition;
    }
    
    /**
     * @dev Executes ultra-low latency market order
     * Use Case: Immediate execution with minimal market impact
     */
    function executeMarketOrder(
        MarketData memory marketData,
        uint256 quantity,
        bool isBuy,
        StrategyParams memory params
    ) internal view returns (ExecutionResult memory result) {
        uint256 startTime = block.timestamp;
        
        require(quantity <= params.maxOrderSize, "HighFrequencyTrading: order size exceeded");
        require(marketData.timestamp > block.timestamp - 1, "HighFrequencyTrading: stale market data");
        
        // Calculate expected execution price with market impact
        uint256 availableLiquidity = isBuy ? marketData.askSize : marketData.bidSize;
        uint256 basePrice = isBuy ? marketData.askPrice : marketData.bidPrice;
        
        if (quantity <= availableLiquidity) {
            // Full execution at best price
            result.executedPrice = basePrice;
            result.executedQuantity = quantity;
            result.marketImpact = 0;
        } else {
            // Partial execution with market impact modeling
            (result.executedPrice, result.marketImpact) = calculateMarketImpact(
                basePrice,
                quantity,
                availableLiquidity,
                marketData.volatility
            );
            result.executedQuantity = quantity;
        }
        
        // Calculate slippage
        result.slippage = abs(int256(result.executedPrice) - int256(marketData.lastPrice)) * PRECISION / marketData.lastPrice;
        result.latency = block.timestamp - startTime;
        result.success = result.latency <= params.latencyThreshold && result.marketImpact <= params.riskLimit;
    }
    
    /**
     * @dev Calculates optimal market making spreads
     * Use Case: Dynamic bid-ask spread optimization for market makers
     */
    function calculateOptimalSpreads(
        MarketData memory marketData,
        uint256 inventory,
        uint256 riskAversion,
        uint256 orderArrivalRate
    ) internal pure returns (uint256 bidPrice, uint256 askPrice, uint256 optimalSpread) {
        // Avellaneda-Stoikov market making model
        uint256 midPrice = (marketData.bidPrice + marketData.askPrice) / 2;
        uint256 volatility = marketData.volatility;
        
        // Calculate inventory penalty
        int256 inventoryPenalty = int256(inventory * riskAversion * volatility * volatility / (PRECISION * PRECISION));
        
        // Calculate optimal spread based on order flow and volatility
        uint256 baseSpread = volatility * volatility / (2 * riskAversion * orderArrivalRate);
        optimalSpread = baseSpread + abs(inventoryPenalty) / 2;
        
        // Apply inventory skew
        int256 skew = inventoryPenalty / 2;
        
        bidPrice = midPrice - optimalSpread / 2 - uint256(skew > 0 ? skew : 0);
        askPrice = midPrice + optimalSpread / 2 + uint256(skew < 0 ? -skew : 0);
        
        // Ensure minimum tick size
        bidPrice = (bidPrice / TICK_SIZE) * TICK_SIZE;
        askPrice = ((askPrice + TICK_SIZE - 1) / TICK_SIZE) * TICK_SIZE;
    }
    
    /**
     * @dev Detects arbitrage opportunities across venues
     * Use Case: Cross-exchange arbitrage with latency considerations
     */
    function detectArbitrage(
        MarketData[] memory venues,
        uint256 maxQuantity,
        uint256 minProfitThreshold
    ) internal pure returns (bool hasOpportunity, uint256 venue1, uint256 venue2, uint256 profit) {
        require(venues.length >= 2, "HighFrequencyTrading: insufficient venues");
        
        uint256 maxBid = 0;
        uint256 minAsk = type(uint256).max;
        uint256 maxBidVenue = 0;
        uint256 minAskVenue = 0;
        
        // Find highest bid and lowest ask across venues
        for (uint256 i = 0; i < venues.length; i++) {
            if (venues[i].bidPrice > maxBid && venues[i].bidSize >= maxQuantity) {
                maxBid = venues[i].bidPrice;
                maxBidVenue = i;
            }
            
            if (venues[i].askPrice < minAsk && venues[i].askSize >= maxQuantity) {
                minAsk = venues[i].askPrice;
                minAskVenue = i;
            }
        }
        
        // Check for profitable arbitrage
        if (maxBid > minAsk && maxBidVenue != minAskVenue) {
            profit = (maxBid - minAsk) * maxQuantity / PRECISION;
            
            // Account for transaction costs and latency
            uint256 tradingCosts = estimateTradingCosts(maxQuantity, venues[maxBidVenue], venues[minAskVenue]);
            
            if (profit > tradingCosts + minProfitThreshold) {
                hasOpportunity = true;
                venue1 = minAskVenue; // Buy venue
                venue2 = maxBidVenue; // Sell venue
            }
        }
    }
    
    /**
     * @dev Implements statistical arbitrage strategy
     * Use Case: Mean reversion trading based on statistical models
     */
    function generateStatArbSignal(
        uint256[] memory priceHistory,
        uint256 lookbackPeriod,
        uint256 currentPrice
    ) internal pure returns (StatArbSignal memory signal) {
        require(priceHistory.length >= lookbackPeriod, "HighFrequencyTrading: insufficient history");
        
        // Calculate rolling mean and standard deviation
        uint256 sum = 0;
        uint256 sumSquares = 0;
        
        for (uint256 i = priceHistory.length - lookbackPeriod; i < priceHistory.length; i++) {
            sum += priceHistory[i];
            sumSquares += priceHistory[i] * priceHistory[i] / PRECISION;
        }
        
        uint256 mean = sum / lookbackPeriod;
        uint256 variance = sumSquares / lookbackPeriod - mean * mean / PRECISION;
        uint256 stdDev = sqrt(variance);
        
        // Calculate z-score
        signal.zscore = int256(currentPrice) - int256(mean);
        signal.zscore = signal.zscore * int256(PRECISION) / int256(stdDev);
        
        // Calculate half-life of mean reversion using Ornstein-Uhlenbeck process
        signal.halfLife = calculateHalfLife(priceHistory, lookbackPeriod);
        
        // Generate trading signal
        if (signal.zscore > 2 * int256(PRECISION)) {
            // Price too high, short signal
            signal.isLong = false;
            signal.confidence = min(abs(signal.zscore) * 50 / int256(PRECISION), PRECISION);
            signal.targetPosition = signal.confidence * MAX_POSITION_SIZE / PRECISION;
        } else if (signal.zscore < -2 * int256(PRECISION)) {
            // Price too low, long signal
            signal.isLong = true;
            signal.confidence = min(abs(signal.zscore) * 50 / int256(PRECISION), PRECISION);
            signal.targetPosition = signal.confidence * MAX_POSITION_SIZE / PRECISION;
        } else {
            // No signal
            signal.confidence = 0;
            signal.targetPosition = 0;
        }
    }
    
    /**
     * @dev Calculates market impact for large orders
     * Use Case: Order execution optimization with impact modeling
     */
    function calculateMarketImpact(
        uint256 basePrice,
        uint256 orderSize,
        uint256 availableLiquidity,
        uint256 volatility
    ) internal pure returns (uint256 executionPrice, uint256 impact) {
        // Square-root market impact model
        uint256 participationRate = orderSize * PRECISION / availableLiquidity;
        
        // Temporary impact: proportional to order size and inverse square root of liquidity
        uint256 temporaryImpact = volatility * sqrt(participationRate) / 100;
        
        // Permanent impact: smaller, proportional to participation rate
        uint256 permanentImpact = volatility * participationRate / (200 * PRECISION);
        
        impact = temporaryImpact + permanentImpact;
        
        // Adjust execution price based on impact
        executionPrice = basePrice + impact;
    }
    
    /**
     * @dev Implements order flow toxicity detection
     * Use Case: Protecting market makers from adverse selection
     */
    function detectOrderFlowToxicity(
        MarketData memory currentData,
        MarketData memory previousData,
        uint256 recentVolume,
        uint256 averageVolume
    ) internal pure returns (bool isToxic, uint256 toxicityScore) {
        // Calculate metrics for toxicity detection
        
        // 1. Price impact per unit volume
        uint256 priceChange = abs(int256(currentData.lastPrice) - int256(previousData.lastPrice));
        uint256 priceImpactPerVolume = priceChange * PRECISION / recentVolume;
        
        // 2. Volume surge indicator
        uint256 volumeRatio = recentVolume * PRECISION / averageVolume;
        
        // 3. Bid-ask spread compression
        uint256 currentSpread = currentData.askPrice - currentData.bidPrice;
        uint256 previousSpread = previousData.askPrice - previousData.bidPrice;
        uint256 spreadCompression = previousSpread > currentSpread ? 
            (previousSpread - currentSpread) * PRECISION / previousSpread : 0;
        
        // Calculate composite toxicity score
        toxicityScore = (priceImpactPerVolume * 40 + 
                        volumeRatio * 30 + 
                        spreadCompression * 30) / 100;
        
        // Threshold for toxic flow detection
        isToxic = toxicityScore > PRECISION / 2; // 50% threshold
    }
    
    /**
     * @dev Implements TWAP (Time-Weighted Average Price) execution
     * Use Case: Large order execution with minimal market impact
     */
    function executeTWAP(
        uint256 totalQuantity,
        uint256 executionHorizon,
        MarketData memory marketData,
        uint256 currentTime
    ) internal pure returns (uint256 childOrderSize, uint256 nextExecutionTime) {
        uint256 remainingTime = executionHorizon > currentTime ? executionHorizon - currentTime : 0;
        require(remainingTime > 0, "HighFrequencyTrading: execution horizon passed");
        
        // Calculate optimal participation rate based on market conditions
        uint256 volatility = marketData.volatility;
        uint256 averageVolume = marketData.volume;
        
        // Optimal execution rate (Almgren-Chriss model simplified)
        uint256 lambda = sqrt(volatility * volatility / remainingTime); // Market impact parameter
        uint256 participationRate = min(PRECISION / 10, lambda); // Max 10% participation
        
        // Calculate child order size
        childOrderSize = min(
            totalQuantity / (remainingTime / 3600), // Spread over hours
            averageVolume * participationRate / PRECISION
        );
        
        // Dynamic interval based on market conditions
        uint256 baseInterval = 60; // 1 minute
        uint256 volatilityAdjustment = volatility * 100 / PRECISION; // Scale volatility
        nextExecutionTime = currentTime + baseInterval + volatilityAdjustment;
    }
    
    /**
     * @dev Implements pairs trading strategy
     * Use Case: Market-neutral statistical arbitrage
     */
    function generatePairsSignal(
        uint256[] memory asset1Prices,
        uint256[] memory asset2Prices,
        uint256 lookbackPeriod
    ) internal pure returns (int256 signal, uint256 confidence, uint256 hedgeRatio) {
        require(asset1Prices.length == asset2Prices.length, "HighFrequencyTrading: price array mismatch");
        require(asset1Prices.length >= lookbackPeriod, "HighFrequencyTrading: insufficient data");
        
        // Calculate hedge ratio using linear regression
        hedgeRatio = calculateHedgeRatio(asset1Prices, asset2Prices, lookbackPeriod);
        
        // Calculate spread
        uint256 currentSpread = calculateSpread(
            asset1Prices[asset1Prices.length - 1],
            asset2Prices[asset2Prices.length - 1],
            hedgeRatio
        );
        
        // Calculate historical spread statistics
        uint256[] memory spreads = new uint256[](lookbackPeriod);
        uint256 spreadSum = 0;
        
        for (uint256 i = 0; i < lookbackPeriod; i++) {
            uint256 idx = asset1Prices.length - lookbackPeriod + i;
            spreads[i] = calculateSpread(asset1Prices[idx], asset2Prices[idx], hedgeRatio);
            spreadSum += spreads[i];
        }
        
        uint256 spreadMean = spreadSum / lookbackPeriod;
        uint256 spreadStdDev = calculateStandardDeviation(spreads, spreadMean);
        
        // Generate signal based on spread z-score
        int256 zscore = (int256(currentSpread) - int256(spreadMean)) * int256(PRECISION) / int256(spreadStdDev);
        
        if (zscore > 2 * int256(PRECISION)) {
            signal = -1 * int256(PRECISION); // Short spread (short asset1, long asset2)
            confidence = min(abs(zscore) * PRECISION / (3 * int256(PRECISION)), PRECISION);
        } else if (zscore < -2 * int256(PRECISION)) {
            signal = int256(PRECISION); // Long spread (long asset1, short asset2)
            confidence = min(abs(zscore) * PRECISION / (3 * int256(PRECISION)), PRECISION);
        } else {
            signal = 0;
            confidence = 0;
        }
    }
    
    /**
     * @dev Calculates optimal execution schedule for large orders
     * Use Case: Institutional order execution with minimal market impact
     */
    function optimizeExecutionSchedule(
        uint256 totalQuantity,
        uint256 totalTime,
        uint256[] memory historicalVolumes,
        uint256[] memory volatilityProfile
    ) internal pure returns (uint256[] memory schedule) {
        require(totalTime > 0, "HighFrequencyTrading: invalid time horizon");
        require(historicalVolumes.length == volatilityProfile.length, "HighFrequencyTrading: data length mismatch");
        
        uint256 periods = historicalVolumes.length;
        schedule = new uint256[](periods);
        
        // Calculate volume-weighted execution rates
        uint256 totalVolume = 0;
        for (uint256 i = 0; i < periods; i++) {
            totalVolume += historicalVolumes[i];
        }
        
        uint256 allocatedQuantity = 0;
        
        for (uint256 i = 0; i < periods - 1; i++) {
            // Adjust for volatility - trade more in low volatility periods
            uint256 volatilityAdjustment = PRECISION * PRECISION / (volatilityProfile[i] + PRECISION);
            uint256 adjustedVolume = historicalVolumes[i] * volatilityAdjustment / PRECISION;
            
            schedule[i] = totalQuantity * adjustedVolume / totalVolume;
            allocatedQuantity += schedule[i];
        }
        
        // Assign remaining quantity to last period
        schedule[periods - 1] = totalQuantity - allocatedQuantity;
    }
    
    /**
     * @dev Real-time risk monitoring for HFT strategies
     * Use Case: Continuous risk assessment and position limits
     */
    function monitorRisk(
        int256 currentPosition,
        uint256 currentPnL,
        uint256 maxDrawdown,
        StrategyParams memory params
    ) internal pure returns (bool riskBreach, string memory riskType) {
        // Position size risk
        if (abs(currentPosition) > int256(params.maxPositionSize)) {
            return (true, "POSITION_LIMIT");
        }
        
        // Drawdown risk
        if (maxDrawdown > params.riskLimit) {
            return (true, "DRAWDOWN_LIMIT");
        }
        
        // Concentration risk (simplified)
        if (abs(currentPosition) > int256(params.maxPositionSize * 80 / 100)) {
            return (true, "CONCENTRATION_RISK");
        }
        
        return (false, "");
    }
    
    // Helper functions
    function calculateHedgeRatio(
        uint256[] memory x,
        uint256[] memory y,
        uint256 period
    ) internal pure returns (uint256) {
        // Simplified linear regression for hedge ratio
        uint256 sumX = 0;
        uint256 sumY = 0;
        uint256 sumXY = 0;
        uint256 sumXX = 0;
        
        for (uint256 i = x.length - period; i < x.length; i++) {
            sumX += x[i];
            sumY += y[i];
            sumXY += x[i] * y[i] / PRECISION;
            sumXX += x[i] * x[i] / PRECISION;
        }
        
        uint256 n = period;
        uint256 numerator = n * sumXY - sumX * sumY / PRECISION;
        uint256 denominator = n * sumXX - sumX * sumX / PRECISION;
        
        return denominator > 0 ? numerator * PRECISION / denominator : PRECISION;
    }
    
    function calculateSpread(
        uint256 price1,
        uint256 price2,
        uint256 hedgeRatio
    ) internal pure returns (uint256) {
        return price1 - price2 * hedgeRatio / PRECISION;
    }
    
    function calculateStandardDeviation(
        uint256[] memory values,
        uint256 mean
    ) internal pure returns (uint256) {
        uint256 sumSquaredDiffs = 0;
        
        for (uint256 i = 0; i < values.length; i++) {
            uint256 diff = values[i] > mean ? values[i] - mean : mean - values[i];
            sumSquaredDiffs += diff * diff / PRECISION;
        }
        
        return sqrt(sumSquaredDiffs / values.length);
    }
    
    function calculateHalfLife(
        uint256[] memory prices,
        uint256 period
    ) internal pure returns (uint256) {
        // Simplified half-life calculation for mean reversion
        // Returns periods for half-life
        
        uint256 changes = 0;
        uint256 reversionCount = 0;
        
        for (uint256 i = period; i < prices.length - 1; i++) {
            uint256 priceDiff = prices[i] > prices[i-1] ? prices[i] - prices[i-1] : prices[i-1] - prices[i];
            uint256 nextDiff = prices[i+1] > prices[i] ? prices[i+1] - prices[i] : prices[i] - prices[i+1];
            
            changes++;
            
            // Check for mean reversion (price change reverses direction)
            if ((prices[i] > prices[i-1] && prices[i+1] < prices[i]) ||
                (prices[i] < prices[i-1] && prices[i+1] > prices[i])) {
                reversionCount++;
            }
        }
        
        uint256 reversionRate = reversionCount * PRECISION / changes;
        
        // Convert to half-life periods (simplified)
        return reversionRate > 0 ? PRECISION * 693 / (reversionRate * 1000) : 100; // ln(2) ≈ 0.693
    }
    
    function estimateTradingCosts(
        uint256 quantity,
        MarketData memory venue1,
        MarketData memory venue2
    ) internal pure returns (uint256) {
        // Simplified trading cost estimation
        uint256 spread1 = venue1.askPrice - venue1.bidPrice;
        uint256 spread2 = venue2.askPrice - venue2.bidPrice;
        
        uint256 impactCost1 = quantity * spread1 / (2 * venue1.askSize);
        uint256 impactCost2 = quantity * spread2 / (2 * venue2.bidSize);
        
        return impactCost1 + impactCost2;
    }
    
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 result = x;
        uint256 previous;
        
        do {
            previous = result;
            result = (result + x * PRECISION / result) / 2;
        } while (abs(int256(result) - int256(previous)) > 1);
        
        return result;
    }
    
    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}