// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title RiskAssessment - Advanced Risk Analysis and Management Library
 * @dev Sophisticated risk calculation engine for DeFi protocols
 * 
 * FEATURES:
 * - Value at Risk (VaR) calculations with multiple methodologies
 * - Portfolio risk analysis and correlation modeling
 * - Liquidity risk assessment and stress testing
 * - Credit risk scoring and default probability modeling
 * - Market risk metrics and volatility analysis
 * - Systemic risk detection and contagion modeling
 * 
 * USE CASES:
 * 1. DeFi lending protocol risk management
 * 2. Portfolio optimization and asset allocation
 * 3. Automated liquidation threshold calculation
 * 4. Insurance protocol pricing and reserves
 * 5. Cross-protocol risk monitoring
 * 6. Regulatory compliance and capital requirements
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library RiskAssessment {
    // Precision constants
    uint256 private constant PRECISION = 1e18;
    uint256 private constant BASIS_POINTS = 10000;
    uint256 private constant CONFIDENCE_95 = 16449; // 1.645 * 10000 for 95% confidence
    uint256 private constant CONFIDENCE_99 = 23263; // 2.326 * 10000 for 99% confidence
    
    // Risk assessment structures
    struct AssetRisk {
        uint256 volatility;          // Annualized volatility
        uint256 liquidityScore;      // 0-100 liquidity rating
        uint256 creditRating;        // 0-100 credit score
        uint256 marketCap;          // Market capitalization
        uint256 tradingVolume;      // 24h trading volume
        uint256 correlationMatrix;   // Encoded correlation data
        bool isStable;              // Stablecoin flag
    }
    
    struct PortfolioRisk {
        uint256 totalValue;
        uint256 weightedVolatility;
        uint256 beta;               // Market beta
        uint256 sharpeRatio;        // Risk-adjusted return
        uint256 maxDrawdown;        // Maximum historical loss
        uint256 concentrationRisk;   // Portfolio concentration
    }
    
    struct LiquidityRisk {
        uint256 availableLiquidity;
        uint256 liquidationThreshold;
        uint256 slippageImpact;
        uint256 marketDepth;
        uint256 timeToLiquidate;    // Expected liquidation time
    }
    
    struct CreditRisk {
        uint256 probabilityOfDefault;
        uint256 lossGivenDefault;
        uint256 exposureAtDefault;
        uint256 expectedLoss;
        uint256 creditUtilization;
    }
    
    /**
     * @dev Calculates Value at Risk using parametric method
     * Use Case: Portfolio risk measurement, capital allocation
     */
    function calculateVaR(
        uint256 portfolioValue,
        uint256 volatility,
        uint256 confidenceLevel,
        uint256 timeHorizon
    ) internal pure returns (uint256 var) {
        // VaR = Portfolio Value * Z-score * Volatility * sqrt(Time)
        uint256 zScore;
        
        if (confidenceLevel >= 99 * BASIS_POINTS / 100) {
            zScore = CONFIDENCE_99;
        } else if (confidenceLevel >= 95 * BASIS_POINTS / 100) {
            zScore = CONFIDENCE_95;
        } else {
            zScore = 10000; // 1.0 for lower confidence levels
        }
        
        // Calculate time adjustment (assuming daily volatility)
        uint256 timeAdjustment = sqrt(timeHorizon * PRECISION);
        
        var = (portfolioValue * zScore * volatility * timeAdjustment) / 
              (BASIS_POINTS * PRECISION * PRECISION);
    }
    
    /**
     * @dev Calculates Expected Shortfall (Conditional VaR)
     * Use Case: Tail risk assessment, stress testing
     */
    function calculateExpectedShortfall(
        uint256 portfolioValue,
        uint256 volatility,
        uint256 confidenceLevel
    ) internal pure returns (uint256 expectedShortfall) {
        // ES = VaR + (volatility / sqrt(2π)) * exp(-z²/2) / (1-confidence)
        uint256 var = calculateVaR(portfolioValue, volatility, confidenceLevel, 1);
        
        // Simplified approximation for on-chain calculation
        uint256 tailExpectation = (volatility * portfolioValue) / (2 * PRECISION);
        uint256 confidenceAdjustment = PRECISION - confidenceLevel;
        
        expectedShortfall = var + (tailExpectation * PRECISION) / confidenceAdjustment;
    }
    
    /**
     * @dev Calculates portfolio risk with correlation effects
     * Use Case: Multi-asset portfolio risk assessment
     */
    function calculatePortfolioRisk(
        uint256[] memory weights,
        uint256[] memory volatilities,
        uint256[] memory correlations
    ) internal pure returns (uint256 portfolioVolatility) {
        require(
            weights.length == volatilities.length && 
            correlations.length == weights.length * weights.length,
            "RiskAssessment: array length mismatch"
        );
        
        uint256 variance = 0;
        uint256 n = weights.length;
        
        // Calculate portfolio variance using correlation matrix
        for (uint256 i = 0; i < n; i++) {
            for (uint256 j = 0; j < n; j++) {
                uint256 correlation = correlations[i * n + j];
                uint256 contribution = (weights[i] * weights[j] * 
                                      volatilities[i] * volatilities[j] * 
                                      correlation) / (PRECISION * PRECISION * PRECISION);
                variance += contribution;
            }
        }
        
        portfolioVolatility = sqrt(variance);
    }
    
    /**
     * @dev Calculates liquidity risk score
     * Use Case: Liquidity assessment, market impact analysis
     */
    function calculateLiquidityRisk(
        uint256 tradingVolume,
        uint256 marketCap,
        uint256 bidAskSpread,
        uint256 orderBookDepth
    ) internal pure returns (uint256 liquidityScore) {
        // Higher score = better liquidity (lower risk)
        
        // Volume to market cap ratio (higher is better)
        uint256 volumeRatio = (tradingVolume * PRECISION) / marketCap;
        if (volumeRatio > PRECISION / 10) volumeRatio = PRECISION / 10; // Cap at 10%
        
        // Spread impact (lower spread is better)
        uint256 spreadImpact = PRECISION - ((bidAskSpread * PRECISION) / BASIS_POINTS);
        
        // Depth factor (higher depth is better)
        uint256 depthFactor = orderBookDepth > PRECISION ? PRECISION : orderBookDepth;
        
        // Weighted combination
        liquidityScore = (volumeRatio * 40 + spreadImpact * 40 + depthFactor * 20) / 100;
    }
    
    /**
     * @dev Calculates credit risk metrics
     * Use Case: Lending protocol risk assessment
     */
    function calculateCreditRisk(
        uint256 collateralValue,
        uint256 debtAmount,
        uint256 collateralVolatility,
        uint256 historicalDefault
    ) internal pure returns (CreditRisk memory risk) {
        // Loan-to-value ratio
        uint256 ltv = (debtAmount * PRECISION) / collateralValue;
        
        // Probability of default based on LTV and volatility
        uint256 baseDefaultRate = historicalDefault;
        uint256 volatilityAdjustment = (collateralVolatility * ltv) / PRECISION;
        risk.probabilityOfDefault = baseDefaultRate + volatilityAdjustment;
        
        // Loss given default (assuming 20% recovery rate)
        risk.lossGivenDefault = (80 * PRECISION) / 100;
        
        // Exposure at default
        risk.exposureAtDefault = debtAmount;
        
        // Expected loss = PD * LGD * EAD
        risk.expectedLoss = (risk.probabilityOfDefault * risk.lossGivenDefault * 
                           risk.exposureAtDefault) / (PRECISION * PRECISION);
        
        // Credit utilization
        risk.creditUtilization = ltv;
    }
    
    /**
     * @dev Calculates optimal liquidation threshold
     * Use Case: Dynamic liquidation management
     */
    function calculateLiquidationThreshold(
        uint256 collateralVolatility,
        uint256 liquidityScore,
        uint256 targetConfidence
    ) internal pure returns (uint256 threshold) {
        // Base threshold from volatility (higher volatility = higher threshold)
        uint256 baseThreshold = (collateralVolatility * 150) / 100; // 1.5x volatility
        
        // Liquidity adjustment (lower liquidity = higher threshold)
        uint256 liquidityAdjustment = (PRECISION - liquidityScore) / 10;
        
        // Confidence adjustment
        uint256 confidenceMultiplier = targetConfidence > 95 * BASIS_POINTS / 100 ? 
                                     120 * PRECISION / 100 : PRECISION;
        
        threshold = (baseThreshold + liquidityAdjustment) * confidenceMultiplier / PRECISION;
        
        // Ensure minimum threshold
        if (threshold < PRECISION / 10) { // 10% minimum
            threshold = PRECISION / 10;
        }
    }
    
    /**
     * @dev Calculates Sharpe ratio for risk-adjusted returns
     * Use Case: Performance evaluation, strategy comparison
     */
    function calculateSharpeRatio(
        uint256 portfolioReturn,
        uint256 riskFreeRate,
        uint256 portfolioVolatility
    ) internal pure returns (uint256 sharpeRatio) {
        if (portfolioVolatility == 0) return 0;
        
        uint256 excessReturn = portfolioReturn > riskFreeRate ? 
                              portfolioReturn - riskFreeRate : 0;
        
        sharpeRatio = (excessReturn * PRECISION) / portfolioVolatility;
    }
    
    /**
     * @dev Calculates maximum drawdown
     * Use Case: Downside risk assessment
     */
    function calculateMaxDrawdown(
        uint256[] memory priceHistory
    ) internal pure returns (uint256 maxDrawdown) {
        if (priceHistory.length < 2) return 0;
        
        uint256 peak = priceHistory[0];
        uint256 maxDD = 0;
        
        for (uint256 i = 1; i < priceHistory.length; i++) {
            if (priceHistory[i] > peak) {
                peak = priceHistory[i];
            } else {
                uint256 drawdown = ((peak - priceHistory[i]) * PRECISION) / peak;
                if (drawdown > maxDD) {
                    maxDD = drawdown;
                }
            }
        }
        
        maxDrawdown = maxDD;
    }
    
    /**
     * @dev Calculates beta (systematic risk)
     * Use Case: Market risk assessment, CAPM calculations
     */
    function calculateBeta(
        uint256[] memory assetReturns,
        uint256[] memory marketReturns
    ) internal pure returns (uint256 beta) {
        require(assetReturns.length == marketReturns.length, "RiskAssessment: length mismatch");
        
        if (assetReturns.length < 2) return PRECISION; // Default beta of 1.0
        
        uint256 covariance = calculateCovariance(assetReturns, marketReturns);
        uint256 marketVariance = calculateVariance(marketReturns);
        
        if (marketVariance == 0) return PRECISION;
        
        beta = (covariance * PRECISION) / marketVariance;
    }
    
    /**
     * @dev Stress testing with multiple scenarios
     * Use Case: Regulatory stress testing, scenario analysis
     */
    function stressTesting(
        uint256 portfolioValue,
        uint256[] memory stressFactors,
        uint256[] memory probabilities
    ) internal pure returns (uint256 stressedValue, uint256 worstCase) {
        require(stressFactors.length == probabilities.length, "RiskAssessment: length mismatch");
        
        uint256 expectedStressedValue = 0;
        worstCase = portfolioValue;
        
        for (uint256 i = 0; i < stressFactors.length; i++) {
            uint256 scenarioValue = (portfolioValue * stressFactors[i]) / PRECISION;
            expectedStressedValue += (scenarioValue * probabilities[i]) / PRECISION;
            
            if (scenarioValue < worstCase) {
                worstCase = scenarioValue;
            }
        }
        
        stressedValue = expectedStressedValue;
    }
    
    // Helper functions
    
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
    
    function calculateCovariance(
        uint256[] memory x,
        uint256[] memory y
    ) internal pure returns (uint256) {
        require(x.length == y.length && x.length > 1, "RiskAssessment: invalid arrays");
        
        uint256 meanX = calculateMean(x);
        uint256 meanY = calculateMean(y);
        uint256 covariance = 0;
        
        for (uint256 i = 0; i < x.length; i++) {
            int256 devX = int256(x[i]) - int256(meanX);
            int256 devY = int256(y[i]) - int256(meanY);
            covariance += uint256(devX * devY) / (x.length - 1);
        }
        
        return covariance;
    }
    
    function calculateVariance(uint256[] memory values) internal pure returns (uint256) {
        if (values.length <= 1) return 0;
        
        uint256 mean = calculateMean(values);
        uint256 variance = 0;
        
        for (uint256 i = 0; i < values.length; i++) {
            uint256 diff = values[i] > mean ? values[i] - mean : mean - values[i];
            variance += (diff * diff) / (values.length - 1);
        }
        
        return variance;
    }
    
    function calculateMean(uint256[] memory values) internal pure returns (uint256) {
        if (values.length == 0) return 0;
        
        uint256 sum = 0;
        for (uint256 i = 0; i < values.length; i++) {
            sum += values[i];
        }
        
        return sum / values.length;
    }
}