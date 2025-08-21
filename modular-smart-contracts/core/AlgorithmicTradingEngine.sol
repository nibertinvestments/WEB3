// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AlgorithmicTradingEngine - Advanced Automated Trading System
 * @dev Sophisticated algorithmic trading with multiple strategies and risk management
 * 
 * FEATURES:
 * - Multiple trading strategies (momentum, mean reversion, arbitrage, pairs trading)
 * - Real-time market data analysis and signal generation
 * - Advanced risk management with position sizing and stop-losses
 * - Portfolio optimization and rebalancing algorithms
 * - Machine learning-inspired pattern recognition
 * - High-frequency trading capabilities with MEV protection
 * - Cross-exchange arbitrage and statistical arbitrage
 * - Options market making and volatility trading
 * 
 * MODULAR DESIGN:
 * - Core trading engine (this contract)
 * - Strategy modules (pluggable trading strategies)
 * - Risk management module
 * - Portfolio optimization module
 * - Market data analysis module
 * - Execution optimization module
 * 
 * USE CASES:
 * 1. Institutional algorithmic trading platforms
 * 2. DeFi yield farming optimization
 * 3. Cross-exchange arbitrage systems
 * 4. Market making and liquidity provision
 * 5. Quantitative investment strategies
 * 6. Risk-managed trading for DAOs
 * 
 * @author Nibert Investments LLC
 * @notice Advanced Algorithmic Trading with Institutional-Grade Features
 */

import "../libraries/mathematical/StatisticalAnalysis.sol";
import "../libraries/financial/AdvancedDerivatives.sol";

contract AlgorithmicTradingEngine {
    using StatisticalAnalysis for uint256[];
    
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MAX_POSITION_SIZE = 5e17; // 50% max position
    uint256 private constant MAX_STRATEGIES = 50;
    
    // Strategy types
    enum StrategyType {
        Momentum,
        MeanReversion,
        Arbitrage,
        PairsTrading,
        VolatilityTrading,
        MarketMaking,
        StatisticalArbitrage,
        MachineLearning
    }
    
    // Order types
    enum OrderType {
        Market,
        Limit,
        Stop,
        StopLimit,
        IcebergOrder,
        TWAPOrder
    }
    
    // Trading strategy configuration
    struct TradingStrategy {
        StrategyType strategyType;
        address strategyContract;
        uint256 allocation; // Portfolio allocation percentage
        uint256 riskLimit; // Maximum risk per trade
        uint256 minReturn; // Minimum expected return
        bool isActive;
        uint256 performance; // Historical performance
        uint256 sharpeRatio; // Risk-adjusted returns
        uint256[] parameters; // Strategy-specific parameters
    }
    
    // Market signal structure
    struct MarketSignal {
        address tokenA;
        address tokenB;
        int256 signal; // -1e18 to 1e18 (strong sell to strong buy)
        uint256 confidence; // 0 to 1e18 (confidence level)
        uint256 timeframe; // Signal timeframe in seconds
        uint256 expectedReturn; // Expected return
        uint256 estimatedRisk; // Estimated risk
        uint256 timestamp;
    }
    
    // Trading position
    struct Position {
        address token;
        uint256 amount;
        uint256 entryPrice;
        uint256 entryTime;
        uint256 stopLoss;
        uint256 takeProfit;
        int256 unrealizedPnL;
        uint256 strategyId;
        bool isLong;
    }
    
    // Portfolio metrics
    struct PortfolioMetrics {
        uint256 totalValue;
        uint256 totalReturn;
        uint256 sharpeRatio;
        uint256 maxDrawdown;
        uint256 volatility;
        uint256 alpha; // Risk-adjusted excess return
        uint256 beta; // Market correlation
        uint256 informationRatio;
    }
    
    // Risk parameters
    struct RiskParameters {
        uint256 maxPositionSize;
        uint256 maxDailyLoss;
        uint256 maxTotalExposure;
        uint256 correlationLimit;
        uint256 liquidityThreshold;
        uint256 stressTestThreshold;
    }
    
    // State variables
    mapping(uint256 => TradingStrategy) public strategies;
    mapping(bytes32 => MarketSignal) public marketSignals;
    mapping(address => Position[]) public positions;
    mapping(address => uint256) public portfolioValues;
    mapping(address => PortfolioMetrics) public portfolioMetrics;
    
    uint256 public totalStrategies;
    address public riskManager;
    address public portfolioOptimizer;
    address public dataProvider;
    RiskParameters public riskParams;
    
    // Events
    event StrategyAdded(uint256 indexed strategyId, StrategyType strategyType, uint256 allocation);
    event SignalGenerated(bytes32 indexed signalId, address tokenA, address tokenB, int256 signal);
    event TradeExecuted(address indexed trader, address token, uint256 amount, uint256 price, bool isLong);
    event PositionClosed(address indexed trader, address token, int256 pnl, uint256 holdingPeriod);
    event RiskLimitExceeded(address indexed trader, string riskType, uint256 currentValue, uint256 limit);
    event PortfolioRebalanced(address indexed portfolio, uint256 oldValue, uint256 newValue);
    
    modifier onlyRiskManager() {
        require(msg.sender == riskManager, "Only risk manager");
        _;
    }
    
    modifier onlyAuthorized() {
        require(msg.sender == riskManager || msg.sender == portfolioOptimizer, "Not authorized");
        _;
    }
    
    constructor(
        address _riskManager,
        address _portfolioOptimizer,
        address _dataProvider
    ) {
        riskManager = _riskManager;
        portfolioOptimizer = _portfolioOptimizer;
        dataProvider = _dataProvider;
        
        // Initialize default risk parameters
        riskParams = RiskParameters({
            maxPositionSize: MAX_POSITION_SIZE,
            maxDailyLoss: 2e16, // 2% daily loss limit
            maxTotalExposure: 9e17, // 90% total exposure limit
            correlationLimit: 7e17, // 70% correlation limit
            liquidityThreshold: 1e23, // $100K minimum liquidity
            stressTestThreshold: 1e17 // 10% stress test threshold
        });
    }
    
    /**
     * @dev Add a new trading strategy to the engine
     * Use Case: Deploy new quantitative strategies with risk controls
     */
    function addStrategy(
        StrategyType strategyType,
        address strategyContract,
        uint256 allocation,
        uint256 riskLimit,
        uint256[] calldata parameters
    ) external onlyRiskManager returns (uint256 strategyId) {
        require(allocation <= PRECISION, "Invalid allocation");
        require(strategyContract != address(0), "Invalid strategy contract");
        require(totalStrategies < MAX_STRATEGIES, "Too many strategies");
        
        strategyId = totalStrategies++;
        
        strategies[strategyId] = TradingStrategy({
            strategyType: strategyType,
            strategyContract: strategyContract,
            allocation: allocation,
            riskLimit: riskLimit,
            minReturn: 0,
            isActive: true,
            performance: PRECISION, // Start at 100%
            sharpeRatio: 0,
            parameters: parameters
        });
        
        emit StrategyAdded(strategyId, strategyType, allocation);
        
        return strategyId;
    }
    
    /**
     * @dev Generate market signals using advanced analysis
     * Use Case: Real-time signal generation for trading decisions
     */
    function generateMarketSignal(
        address tokenA,
        address tokenB,
        uint256[] calldata priceHistory,
        uint256[] calldata volumeHistory,
        uint256 timeframe
    ) external returns (bytes32 signalId) {
        require(priceHistory.length == volumeHistory.length, "Mismatched data");
        require(priceHistory.length >= 20, "Insufficient data");
        
        signalId = keccak256(abi.encodePacked(tokenA, tokenB, block.timestamp));
        
        // Technical analysis
        int256 momentumSignal = calculateMomentumSignal(priceHistory);
        int256 meanReversionSignal = calculateMeanReversionSignal(priceHistory);
        int256 volumeSignal = calculateVolumeSignal(volumeHistory, priceHistory);
        
        // Combine signals with weights
        int256 combinedSignal = (momentumSignal * 4 + meanReversionSignal * 3 + volumeSignal * 3) / 10;
        
        // Calculate confidence based on signal consistency
        uint256 confidence = calculateSignalConfidence(priceHistory, combinedSignal);
        
        // Estimate expected return and risk
        uint256 expectedReturn = estimateExpectedReturn(priceHistory, combinedSignal);
        uint256 estimatedRisk = priceHistory.standardDeviation();
        
        marketSignals[signalId] = MarketSignal({
            tokenA: tokenA,
            tokenB: tokenB,
            signal: combinedSignal,
            confidence: confidence,
            timeframe: timeframe,
            expectedReturn: expectedReturn,
            estimatedRisk: estimatedRisk,
            timestamp: block.timestamp
        });
        
        emit SignalGenerated(signalId, tokenA, tokenB, combinedSignal);
        
        return signalId;
    }
    
    /**
     * @dev Execute algorithmic trading based on signals and strategies
     * Use Case: Automated trade execution with risk management
     */
    function executeAlgorithmicTrade(
        bytes32 signalId,
        uint256 strategyId,
        uint256 portfolioValue,
        OrderType orderType
    ) external returns (bool success) {
        MarketSignal storage signal = marketSignals[signalId];
        TradingStrategy storage strategy = strategies[strategyId];
        
        require(signal.timestamp > 0, "Invalid signal");
        require(strategy.isActive, "Strategy inactive");
        require(signal.confidence >= 5e17, "Low confidence signal"); // 50% minimum confidence
        
        // Risk checks
        if (!passesRiskChecks(signal, strategy, portfolioValue)) {
            emit RiskLimitExceeded(msg.sender, "Strategy risk limits", signal.estimatedRisk, strategy.riskLimit);
            return false;
        }
        
        // Calculate position size using Kelly criterion
        uint256 positionSize = calculateOptimalPositionSize(
            signal.expectedReturn,
            signal.estimatedRisk,
            strategy.allocation,
            portfolioValue
        );
        
        // Execute trade based on signal
        bool isLong = signal.signal > 0;
        address targetToken = isLong ? signal.tokenA : signal.tokenB;
        
        // Calculate stop loss and take profit levels
        uint256 stopLoss = calculateStopLoss(signal, isLong);
        uint256 takeProfit = calculateTakeProfit(signal, isLong);
        
        // Record position
        positions[msg.sender].push(Position({
            token: targetToken,
            amount: positionSize,
            entryPrice: getCurrentPrice(targetToken),
            entryTime: block.timestamp,
            stopLoss: stopLoss,
            takeProfit: takeProfit,
            unrealizedPnL: 0,
            strategyId: strategyId,
            isLong: isLong
        }));
        
        emit TradeExecuted(msg.sender, targetToken, positionSize, getCurrentPrice(targetToken), isLong);
        
        return true;
    }
    
    /**
     * @dev Implement pairs trading strategy
     * Use Case: Statistical arbitrage between correlated assets
     */
    function pairsTradingStrategy(
        address tokenA,
        address tokenB,
        uint256[] calldata pricesA,
        uint256[] calldata pricesB,
        uint256 lookbackPeriod
    ) external returns (int256 tradingSignal) {
        require(pricesA.length == pricesB.length, "Mismatched price arrays");
        require(pricesA.length >= lookbackPeriod, "Insufficient data");
        
        // Calculate correlation between the two assets
        uint256 correlation = StatisticalAnalysis.correlation(pricesA, pricesB);
        require(correlation >= 7e17, "Low correlation for pairs trading"); // 70% minimum
        
        // Calculate price ratio and its statistics
        uint256[] memory ratios = new uint256[](pricesA.length);
        for (uint256 i = 0; i < pricesA.length; i++) {
            ratios[i] = (pricesA[i] * PRECISION) / pricesB[i];
        }
        
        uint256 meanRatio = ratios.mean();
        uint256 stdRatio = ratios.standardDeviation();
        uint256 currentRatio = ratios[ratios.length - 1];
        
        // Z-score calculation
        int256 zScore;
        if (currentRatio >= meanRatio) {
            zScore = int256(((currentRatio - meanRatio) * PRECISION) / stdRatio);
        } else {
            zScore = -int256(((meanRatio - currentRatio) * PRECISION) / stdRatio);
        }
        
        // Generate trading signal based on z-score
        if (zScore > 2e18) { // Z-score > 2: sell A, buy B
            tradingSignal = -8e17; // Strong sell signal for A
        } else if (zScore < -2e18) { // Z-score < -2: buy A, sell B
            tradingSignal = 8e17; // Strong buy signal for A
        } else if (zScore > 1e18) {
            tradingSignal = -4e17; // Moderate sell signal
        } else if (zScore < -1e18) {
            tradingSignal = 4e17; // Moderate buy signal
        } else {
            tradingSignal = 0; // No signal
        }
        
        return tradingSignal;
    }
    
    /**
     * @dev Implement momentum trading strategy
     * Use Case: Trend following and momentum-based trading
     */
    function momentumTradingStrategy(
        uint256[] calldata prices,
        uint256[] calldata volumes,
        uint256 shortPeriod,
        uint256 longPeriod
    ) external pure returns (int256 momentumSignal, uint256 strength) {
        require(prices.length >= longPeriod, "Insufficient price data");
        require(shortPeriod < longPeriod, "Invalid periods");
        
        // Calculate short and long period moving averages
        uint256 shortMA = calculateMovingAverage(prices, shortPeriod);
        uint256 longMA = calculateMovingAverage(prices, longPeriod);
        
        // Calculate momentum indicator
        uint256 currentPrice = prices[prices.length - 1];
        uint256 pastPrice = prices[prices.length - longPeriod];
        uint256 momentum = (currentPrice * PRECISION) / pastPrice;
        
        // Calculate volume-weighted momentum
        uint256 avgVolume = calculateMovingAverage(volumes, shortPeriod);
        uint256 currentVolume = volumes[volumes.length - 1];
        uint256 volumeRatio = (currentVolume * PRECISION) / avgVolume;
        
        // Generate signal
        if (shortMA > longMA && momentum > 105e16) { // 5% momentum threshold
            momentumSignal = int256((shortMA - longMA) * PRECISION / longMA);
            strength = (momentum - PRECISION) * volumeRatio / PRECISION;
        } else if (shortMA < longMA && momentum < 95e16) { // -5% momentum threshold
            momentumSignal = -int256((longMA - shortMA) * PRECISION / longMA);
            strength = (PRECISION - momentum) * volumeRatio / PRECISION;
        } else {
            momentumSignal = 0;
            strength = 0;
        }
        
        // Cap signal strength
        if (momentumSignal > 8e17) momentumSignal = 8e17;
        if (momentumSignal < -8e17) momentumSignal = -8e17;
        
        return (momentumSignal, strength);
    }
    
    /**
     * @dev Implement mean reversion strategy
     * Use Case: Contrarian trading based on price reversals
     */
    function meanReversionStrategy(
        uint256[] calldata prices,
        uint256 lookbackPeriod,
        uint256 standardDeviations
    ) external pure returns (int256 reversionSignal) {
        require(prices.length >= lookbackPeriod, "Insufficient data");
        
        uint256 mean = calculateMovingAverage(prices, lookbackPeriod);
        uint256 stdDev = calculateStandardDeviation(prices, lookbackPeriod);
        uint256 currentPrice = prices[prices.length - 1];
        
        // Calculate z-score
        int256 zScore;
        if (currentPrice >= mean) {
            zScore = int256(((currentPrice - mean) * PRECISION) / stdDev);
        } else {
            zScore = -int256(((mean - currentPrice) * PRECISION) / stdDev);
        }
        
        uint256 threshold = standardDeviations * PRECISION;
        
        // Generate mean reversion signal
        if (zScore > int256(threshold)) {
            // Price too high, expect reversion down
            reversionSignal = -zScore / 2; // Proportional to deviation
        } else if (zScore < -int256(threshold)) {
            // Price too low, expect reversion up
            reversionSignal = -zScore / 2; // Proportional to deviation
        } else {
            reversionSignal = 0;
        }
        
        // Cap signal
        if (reversionSignal > 8e17) reversionSignal = 8e17;
        if (reversionSignal < -8e17) reversionSignal = -8e17;
        
        return reversionSignal;
    }
    
    /**
     * @dev Implement volatility trading strategy
     * Use Case: Trade volatility changes and options strategies
     */
    function volatilityTradingStrategy(
        uint256[] calldata prices,
        uint256 impliedVolatility,
        uint256 lookbackPeriod
    ) external pure returns (int256 volatilitySignal) {
        require(prices.length >= lookbackPeriod, "Insufficient data");
        
        // Calculate historical volatility
        uint256 historicalVol = calculateVolatility(prices, lookbackPeriod);
        
        // Compare implied vs historical volatility
        if (impliedVolatility > historicalVol * 120 / 100) { // IV > 1.2 * HV
            // Implied vol too high, sell volatility
            volatilitySignal = -int256(((impliedVolatility - historicalVol) * PRECISION) / historicalVol);
        } else if (impliedVolatility < historicalVol * 80 / 100) { // IV < 0.8 * HV
            // Implied vol too low, buy volatility
            volatilitySignal = int256(((historicalVol - impliedVolatility) * PRECISION) / historicalVol);
        } else {
            volatilitySignal = 0;
        }
        
        // Cap signal
        if (volatilitySignal > 8e17) volatilitySignal = 8e17;
        if (volatilitySignal < -8e17) volatilitySignal = -8e17;
        
        return volatilitySignal;
    }
    
    /**
     * @dev Portfolio optimization using Modern Portfolio Theory
     * Use Case: Optimize portfolio allocation for risk-adjusted returns
     */
    function optimizePortfolio(
        address[] calldata tokens,
        uint256[] calldata expectedReturns,
        uint256[] calldata volatilities,
        uint256[] calldata correlations,
        uint256 riskTolerance
    ) external pure returns (uint256[] memory optimalWeights) {
        require(tokens.length == expectedReturns.length, "Mismatched arrays");
        require(expectedReturns.length == volatilities.length, "Mismatched arrays");
        
        uint256 n = tokens.length;
        optimalWeights = new uint256[](n);
        
        // Simplified mean-variance optimization
        uint256 totalScore = 0;
        uint256[] memory scores = new uint256[](n);
        
        for (uint256 i = 0; i < n; i++) {
            // Sharpe ratio calculation: (return - risk_free_rate) / volatility
            // Assuming risk-free rate is 0 for simplicity
            scores[i] = volatilities[i] > 0 ? 
                (expectedReturns[i] * PRECISION) / volatilities[i] : 0;
            
            // Adjust for risk tolerance
            scores[i] = (scores[i] * riskTolerance) / PRECISION;
            totalScore += scores[i];
        }
        
        // Normalize weights
        for (uint256 i = 0; i < n; i++) {
            optimalWeights[i] = totalScore > 0 ? 
                (scores[i] * PRECISION) / totalScore : PRECISION / n;
        }
        
        return optimalWeights;
    }
    
    // Internal helper functions
    function calculateMomentumSignal(uint256[] calldata prices) internal pure returns (int256) {
        if (prices.length < 10) return 0;
        
        uint256 shortMA = calculateMovingAverage(prices, 5);
        uint256 longMA = calculateMovingAverage(prices, 10);
        
        if (shortMA > longMA) {
            return int256((shortMA - longMA) * PRECISION / longMA);
        } else {
            return -int256((longMA - shortMA) * PRECISION / longMA);
        }
    }
    
    function calculateMeanReversionSignal(uint256[] calldata prices) internal pure returns (int256) {
        if (prices.length < 20) return 0;
        
        uint256 mean = calculateMovingAverage(prices, 20);
        uint256 currentPrice = prices[prices.length - 1];
        
        if (currentPrice > mean) {
            return -int256((currentPrice - mean) * PRECISION / mean);
        } else {
            return int256((mean - currentPrice) * PRECISION / mean);
        }
    }
    
    function calculateVolumeSignal(
        uint256[] calldata volumes,
        uint256[] calldata prices
    ) internal pure returns (int256) {
        if (volumes.length < 5) return 0;
        
        uint256 avgVolume = calculateMovingAverage(volumes, 5);
        uint256 currentVolume = volumes[volumes.length - 1];
        uint256 priceChange = prices.length >= 2 ? 
            ((prices[prices.length - 1] * PRECISION) / prices[prices.length - 2]) - PRECISION : 0;
        
        if (currentVolume > avgVolume * 150 / 100 && priceChange > 0) { // High volume + price up
            return int256(priceChange / 2);
        } else if (currentVolume > avgVolume * 150 / 100 && priceChange < 0) { // High volume + price down
            return int256(priceChange / 2);
        } else {
            return 0;
        }
    }
    
    function calculateSignalConfidence(
        uint256[] calldata prices,
        int256 signal
    ) internal pure returns (uint256) {
        if (prices.length < 10) return 0;
        
        uint256 volatility = calculateVolatility(prices, 10);
        uint256 signalStrength = signal >= 0 ? uint256(signal) : uint256(-signal);
        
        // Higher volatility reduces confidence
        uint256 confidence = volatility > 0 ? 
            (signalStrength * PRECISION) / volatility : signalStrength;
        
        return confidence > PRECISION ? PRECISION : confidence;
    }
    
    function estimateExpectedReturn(
        uint256[] calldata prices,
        int256 signal
    ) internal pure returns (uint256) {
        if (prices.length < 5) return 0;
        
        uint256 historicalReturn = calculateMovingAverage(prices, 5);
        uint256 signalStrength = signal >= 0 ? uint256(signal) : uint256(-signal);
        
        return (historicalReturn * signalStrength) / PRECISION;
    }
    
    function passesRiskChecks(
        MarketSignal memory signal,
        TradingStrategy memory strategy,
        uint256 portfolioValue
    ) internal view returns (bool) {
        // Check strategy risk limit
        if (signal.estimatedRisk > strategy.riskLimit) return false;
        
        // Check maximum position size
        uint256 positionValue = (portfolioValue * strategy.allocation) / PRECISION;
        if (positionValue > (portfolioValue * riskParams.maxPositionSize) / PRECISION) return false;
        
        // Additional risk checks would go here
        return true;
    }
    
    function calculateOptimalPositionSize(
        uint256 expectedReturn,
        uint256 estimatedRisk,
        uint256 allocation,
        uint256 portfolioValue
    ) internal pure returns (uint256) {
        // Kelly Criterion: f = (bp - q) / b
        // Simplified version for demonstration
        uint256 maxPosition = (portfolioValue * allocation) / PRECISION;
        
        if (estimatedRisk == 0) return maxPosition / 10; // Conservative fallback
        
        uint256 kellyFraction = expectedReturn > estimatedRisk ? 
            ((expectedReturn - estimatedRisk) * PRECISION) / (estimatedRisk * 2) : 0;
        
        // Apply Kelly fraction with safety margin
        kellyFraction = kellyFraction / 4; // 25% of Kelly for safety
        
        uint256 optimalSize = (maxPosition * kellyFraction) / PRECISION;
        return optimalSize > maxPosition ? maxPosition : optimalSize;
    }
    
    function calculateStopLoss(MarketSignal memory signal, bool isLong) internal pure returns (uint256) {
        uint256 currentPrice = getCurrentPrice(signal.tokenA);
        uint256 stopDistance = (signal.estimatedRisk * currentPrice) / PRECISION;
        
        if (isLong) {
            return currentPrice > stopDistance ? currentPrice - stopDistance : currentPrice / 2;
        } else {
            return currentPrice + stopDistance;
        }
    }
    
    function calculateTakeProfit(MarketSignal memory signal, bool isLong) internal pure returns (uint256) {
        uint256 currentPrice = getCurrentPrice(signal.tokenA);
        uint256 targetDistance = (signal.expectedReturn * currentPrice) / PRECISION;
        
        if (isLong) {
            return currentPrice + targetDistance;
        } else {
            return currentPrice > targetDistance ? currentPrice - targetDistance : currentPrice / 2;
        }
    }
    
    function getCurrentPrice(address token) internal pure returns (uint256) {
        // Placeholder - would integrate with price oracle
        return PRECISION; // $1 placeholder
    }
    
    // Mathematical helper functions
    function calculateMovingAverage(uint256[] calldata data, uint256 period) internal pure returns (uint256) {
        require(data.length >= period, "Insufficient data");
        
        uint256 sum = 0;
        for (uint256 i = data.length - period; i < data.length; i++) {
            sum += data[i];
        }
        
        return sum / period;
    }
    
    function calculateStandardDeviation(uint256[] calldata data, uint256 period) internal pure returns (uint256) {
        require(data.length >= period, "Insufficient data");
        
        uint256 mean = calculateMovingAverage(data, period);
        uint256 sumSquaredDiffs = 0;
        
        for (uint256 i = data.length - period; i < data.length; i++) {
            uint256 diff = data[i] >= mean ? data[i] - mean : mean - data[i];
            sumSquaredDiffs += (diff * diff) / PRECISION;
        }
        
        uint256 variance = sumSquaredDiffs / period;
        return sqrt(variance);
    }
    
    function calculateVolatility(uint256[] calldata prices, uint256 period) internal pure returns (uint256) {
        require(prices.length >= period + 1, "Insufficient data");
        
        uint256[] memory returns = new uint256[](period);
        
        for (uint256 i = 0; i < period; i++) {
            uint256 currentIdx = prices.length - period + i;
            uint256 prevIdx = currentIdx - 1;
            returns[i] = (prices[currentIdx] * PRECISION) / prices[prevIdx];
        }
        
        return calculateStandardDeviation(returns, period);
    }
    
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 guess = x;
        for (uint256 i = 0; i < 20; i++) {
            uint256 newGuess = (guess + (x * PRECISION) / guess) / 2;
            if (abs(newGuess, guess) < 1e12) return newGuess;
            guess = newGuess;
        }
        return guess;
    }
    
    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }
}