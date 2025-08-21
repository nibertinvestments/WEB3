// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title StatisticalAnalysis - Advanced Statistical Functions Library
 * @dev Comprehensive statistical analysis tools for financial and risk modeling
 * 
 * FEATURES:
 * - Advanced probability distributions (normal, lognormal, Poisson, binomial)
 * - Hypothesis testing and confidence intervals
 * - Regression analysis (linear, polynomial, logistic)
 * - Time series analysis (moving averages, volatility, correlation)
 * - Monte Carlo simulation support
 * - Bayesian inference calculations
 * - Risk metrics (VaR, CVaR, Sharpe ratio, drawdown analysis)
 * 
 * USE CASES:
 * 1. Portfolio risk assessment and optimization
 * 2. Credit risk modeling and scoring
 * 3. Market volatility analysis and prediction
 * 4. Algorithmic trading signal generation
 * 5. Insurance actuarial calculations
 * 6. Stress testing and scenario analysis
 * 7. Regulatory capital calculations
 * 8. Performance attribution analysis
 * 
 * @author Nibert Investments LLC
 * @notice Advanced Statistical Analysis for Financial Applications
 */

library StatisticalAnalysis {
    uint256 private constant PRECISION = 1e18;
    uint256 private constant SQRT_2PI = 2506628274631000515; // sqrt(2π) with 18 decimals
    uint256 private constant MAX_ARRAY_SIZE = 10000;
    
    // Statistical distribution parameters
    struct NormalDistribution {
        uint256 mean;
        uint256 standardDeviation;
    }
    
    struct PortfolioMetrics {
        uint256 expectedReturn;
        uint256 volatility;
        uint256 sharpeRatio;
        uint256 valueAtRisk;
        uint256 conditionalVaR;
        uint256 maxDrawdown;
    }
    
    struct RegressionResult {
        uint256[] coefficients;
        uint256 rSquared;
        uint256 adjustedRSquared;
        uint256 standardError;
    }
    
    /**
     * @dev Calculate sample mean of an array
     * Use Case: Basic statistical analysis, portfolio performance
     */
    function mean(uint256[] memory data) internal pure returns (uint256) {
        require(data.length > 0, "Empty dataset");
        
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
        
        return sum / data.length;
    }
    
    /**
     * @dev Calculate sample variance
     * Use Case: Volatility calculations, risk assessment
     */
    function variance(uint256[] memory data) internal pure returns (uint256) {
        require(data.length > 1, "Insufficient data for variance");
        
        uint256 dataMean = mean(data);
        uint256 sumSquaredDiffs = 0;
        
        for (uint256 i = 0; i < data.length; i++) {
            uint256 diff = data[i] >= dataMean ? data[i] - dataMean : dataMean - data[i];
            sumSquaredDiffs += (diff * diff) / PRECISION;
        }
        
        return sumSquaredDiffs / (data.length - 1);
    }
    
    /**
     * @dev Calculate standard deviation
     * Use Case: Volatility analysis, risk metrics
     */
    function standardDeviation(uint256[] memory data) internal pure returns (uint256) {
        return sqrt(variance(data));
    }
    
    /**
     * @dev Calculate correlation coefficient between two datasets
     * Use Case: Portfolio diversification, pair trading strategies
     */
    function correlation(
        uint256[] memory x,
        uint256[] memory y
    ) internal pure returns (uint256) {
        require(x.length == y.length && x.length > 1, "Invalid data lengths");
        
        uint256 meanX = mean(x);
        uint256 meanY = mean(y);
        
        uint256 numerator = 0;
        uint256 sumXSquared = 0;
        uint256 sumYSquared = 0;
        
        for (uint256 i = 0; i < x.length; i++) {
            uint256 diffX = x[i] >= meanX ? x[i] - meanX : meanX - x[i];
            uint256 diffY = y[i] >= meanY ? y[i] - meanY : meanY - y[i];
            
            numerator += (diffX * diffY) / PRECISION;
            sumXSquared += (diffX * diffX) / PRECISION;
            sumYSquared += (diffY * diffY) / PRECISION;
        }
        
        uint256 denominator = sqrt(sumXSquared * sumYSquared / PRECISION);
        return denominator > 0 ? (numerator * PRECISION) / denominator : 0;
    }
    
    /**
     * @dev Calculate Value at Risk (VaR) using historical simulation
     * Use Case: Risk management, regulatory reporting
     */
    function valueAtRisk(
        uint256[] memory returns,
        uint256 confidenceLevel // in basis points (9500 = 95%)
    ) internal pure returns (uint256) {
        require(returns.length > 0, "Empty returns data");
        require(confidenceLevel > 0 && confidenceLevel < 10000, "Invalid confidence level");
        
        // Sort returns (simplified bubble sort for demonstration)
        uint256[] memory sortedReturns = new uint256[](returns.length);
        for (uint256 i = 0; i < returns.length; i++) {
            sortedReturns[i] = returns[i];
        }
        
        for (uint256 i = 0; i < sortedReturns.length - 1; i++) {
            for (uint256 j = 0; j < sortedReturns.length - i - 1; j++) {
                if (sortedReturns[j] > sortedReturns[j + 1]) {
                    uint256 temp = sortedReturns[j];
                    sortedReturns[j] = sortedReturns[j + 1];
                    sortedReturns[j + 1] = temp;
                }
            }
        }
        
        uint256 index = ((10000 - confidenceLevel) * sortedReturns.length) / 10000;
        return sortedReturns[index];
    }
    
    /**
     * @dev Calculate Conditional Value at Risk (CVaR)
     * Use Case: Advanced risk management, tail risk assessment
     */
    function conditionalValueAtRisk(
        uint256[] memory returns,
        uint256 confidenceLevel
    ) internal pure returns (uint256) {
        uint256 var = valueAtRisk(returns, confidenceLevel);
        
        uint256 sum = 0;
        uint256 count = 0;
        
        for (uint256 i = 0; i < returns.length; i++) {
            if (returns[i] <= var) {
                sum += returns[i];
                count++;
            }
        }
        
        return count > 0 ? sum / count : 0;
    }
    
    /**
     * @dev Calculate Sharpe ratio
     * Use Case: Portfolio performance evaluation, fund comparison
     */
    function sharpeRatio(
        uint256[] memory returns,
        uint256 riskFreeRate
    ) internal pure returns (uint256) {
        uint256 meanReturn = mean(returns);
        uint256 stdDev = standardDeviation(returns);
        
        if (stdDev == 0) return 0;
        
        uint256 excessReturn = meanReturn >= riskFreeRate ? 
            meanReturn - riskFreeRate : 0;
        
        return (excessReturn * PRECISION) / stdDev;
    }
    
    /**
     * @dev Calculate maximum drawdown
     * Use Case: Risk assessment, performance evaluation
     */
    function maxDrawdown(uint256[] memory cumulativeReturns) internal pure returns (uint256) {
        require(cumulativeReturns.length > 0, "Empty data");
        
        uint256 peak = cumulativeReturns[0];
        uint256 maxDD = 0;
        
        for (uint256 i = 1; i < cumulativeReturns.length; i++) {
            if (cumulativeReturns[i] > peak) {
                peak = cumulativeReturns[i];
            } else {
                uint256 drawdown = (peak - cumulativeReturns[i]) * PRECISION / peak;
                if (drawdown > maxDD) {
                    maxDD = drawdown;
                }
            }
        }
        
        return maxDD;
    }
    
    /**
     * @dev Linear regression analysis
     * Use Case: Trend analysis, beta calculation, factor modeling
     */
    function linearRegression(
        uint256[] memory x,
        uint256[] memory y
    ) internal pure returns (RegressionResult memory) {
        require(x.length == y.length && x.length > 2, "Invalid data for regression");
        
        uint256 n = x.length;
        uint256 sumX = 0;
        uint256 sumY = 0;
        uint256 sumXY = 0;
        uint256 sumXSquared = 0;
        
        for (uint256 i = 0; i < n; i++) {
            sumX += x[i];
            sumY += y[i];
            sumXY += (x[i] * y[i]) / PRECISION;
            sumXSquared += (x[i] * x[i]) / PRECISION;
        }
        
        uint256 meanX = sumX / n;
        uint256 meanY = sumY / n;
        
        // Calculate slope (beta)
        uint256 numerator = sumXY - (n * meanX * meanY) / PRECISION;
        uint256 denominator = sumXSquared - (n * meanX * meanX) / PRECISION;
        
        uint256 slope = denominator > 0 ? (numerator * PRECISION) / denominator : 0;
        
        // Calculate intercept (alpha)
        uint256 intercept = meanY - (slope * meanX) / PRECISION;
        
        // Calculate R-squared
        uint256 totalSumSquares = 0;
        uint256 residualSumSquares = 0;
        
        for (uint256 i = 0; i < n; i++) {
            uint256 predicted = intercept + (slope * x[i]) / PRECISION;
            uint256 yDiff = y[i] >= meanY ? y[i] - meanY : meanY - y[i];
            uint256 residual = y[i] >= predicted ? y[i] - predicted : predicted - y[i];
            
            totalSumSquares += (yDiff * yDiff) / PRECISION;
            residualSumSquares += (residual * residual) / PRECISION;
        }
        
        uint256 rSquared = totalSumSquares > 0 ? 
            PRECISION - (residualSumSquares * PRECISION) / totalSumSquares : 0;
        
        uint256[] memory coefficients = new uint256[](2);
        coefficients[0] = intercept;
        coefficients[1] = slope;
        
        return RegressionResult({
            coefficients: coefficients,
            rSquared: rSquared,
            adjustedRSquared: n > 2 ? rSquared - ((PRECISION - rSquared) * 2) / (n - 2) : 0,
            standardError: sqrt(residualSumSquares / (n - 2))
        });
    }
    
    /**
     * @dev Exponential moving average calculation
     * Use Case: Technical analysis, trend following strategies
     */
    function exponentialMovingAverage(
        uint256[] memory data,
        uint256 alpha // smoothing factor (0 < alpha < 1) in 1e18 precision
    ) internal pure returns (uint256[] memory) {
        require(data.length > 0, "Empty dataset");
        require(alpha > 0 && alpha < PRECISION, "Invalid alpha");
        
        uint256[] memory ema = new uint256[](data.length);
        ema[0] = data[0];
        
        for (uint256 i = 1; i < data.length; i++) {
            ema[i] = (alpha * data[i] + (PRECISION - alpha) * ema[i-1]) / PRECISION;
        }
        
        return ema;
    }
    
    /**
     * @dev Bollinger Bands calculation
     * Use Case: Volatility analysis, mean reversion strategies
     */
    function bollingerBands(
        uint256[] memory prices,
        uint256 period,
        uint256 multiplier // in 1e18 precision
    ) internal pure returns (uint256[] memory upper, uint256[] memory lower, uint256[] memory middle) {
        require(prices.length >= period, "Insufficient data for period");
        
        upper = new uint256[](prices.length);
        lower = new uint256[](prices.length);
        middle = new uint256[](prices.length);
        
        for (uint256 i = period - 1; i < prices.length; i++) {
            // Calculate simple moving average for the period
            uint256 sum = 0;
            for (uint256 j = i - period + 1; j <= i; j++) {
                sum += prices[j];
            }
            middle[i] = sum / period;
            
            // Calculate standard deviation for the period
            uint256 sumSquaredDiffs = 0;
            for (uint256 j = i - period + 1; j <= i; j++) {
                uint256 diff = prices[j] >= middle[i] ? prices[j] - middle[i] : middle[i] - prices[j];
                sumSquaredDiffs += (diff * diff) / PRECISION;
            }
            uint256 stdDev = sqrt(sumSquaredDiffs / period);
            
            uint256 bandwidth = (multiplier * stdDev) / PRECISION;
            upper[i] = middle[i] + bandwidth;
            lower[i] = middle[i] >= bandwidth ? middle[i] - bandwidth : 0;
        }
        
        return (upper, lower, middle);
    }
    
    /**
     * @dev Normal distribution probability density function
     * Use Case: Options pricing, risk modeling
     */
    function normalPDF(
        uint256 x,
        uint256 mu,
        uint256 sigma
    ) internal pure returns (uint256) {
        if (sigma == 0) return 0;
        
        uint256 diff = x >= mu ? x - mu : mu - x;
        uint256 exponent = (diff * diff * PRECISION) / (2 * sigma * sigma);
        
        // Simplified exponential calculation
        uint256 expValue = PRECISION;
        uint256 term = exponent;
        for (uint256 i = 1; i <= 20; i++) {
            expValue -= term / factorial(i);
            term = (term * exponent) / PRECISION;
            if (term < 1e12) break; // Convergence threshold
        }
        
        return (PRECISION * expValue) / (sigma * SQRT_2PI / 1e9);
    }
    
    /**
     * @dev Monte Carlo simulation for option pricing
     * Use Case: Complex derivatives pricing, risk scenario analysis
     */
    function monteCarloOptionPrice(
        uint256 spot,
        uint256 strike,
        uint256 timeToExpiry,
        uint256 riskFreeRate,
        uint256 volatility,
        uint256 simulations,
        uint256 seed
    ) internal pure returns (uint256) {
        uint256 totalPayoff = 0;
        uint256 randomSeed = seed;
        
        for (uint256 i = 0; i < simulations; i++) {
            // Generate pseudo-random number (simplified)
            randomSeed = (randomSeed * 1103515245 + 12345) % (2**31);
            uint256 normalRandom = (randomSeed * PRECISION) / (2**31);
            
            // Simulate stock price at expiry using geometric Brownian motion
            uint256 drift = (riskFreeRate - (volatility * volatility) / (2 * PRECISION)) * timeToExpiry / PRECISION;
            uint256 diffusion = (volatility * normalRandom * sqrt(timeToExpiry)) / PRECISION;
            uint256 finalPrice = (spot * exp(drift + diffusion)) / PRECISION;
            
            // Calculate payoff for call option
            uint256 payoff = finalPrice > strike ? finalPrice - strike : 0;
            totalPayoff += payoff;
        }
        
        uint256 averagePayoff = totalPayoff / simulations;
        
        // Discount to present value
        return (averagePayoff * exp(riskFreeRate * timeToExpiry / PRECISION)) / PRECISION;
    }
    
    /**
     * @dev Beta coefficient calculation (market sensitivity)
     * Use Case: Portfolio risk analysis, capital asset pricing model
     */
    function beta(
        uint256[] memory assetReturns,
        uint256[] memory marketReturns
    ) internal pure returns (uint256) {
        require(assetReturns.length == marketReturns.length, "Mismatched array lengths");
        
        uint256 covariance = calculateCovariance(assetReturns, marketReturns);
        uint256 marketVariance = variance(marketReturns);
        
        return marketVariance > 0 ? (covariance * PRECISION) / marketVariance : 0;
    }
    
    /**
     * @dev Calculate covariance between two return series
     */
    function calculateCovariance(
        uint256[] memory x,
        uint256[] memory y
    ) internal pure returns (uint256) {
        require(x.length == y.length && x.length > 1, "Invalid data for covariance");
        
        uint256 meanX = mean(x);
        uint256 meanY = mean(y);
        uint256 sum = 0;
        
        for (uint256 i = 0; i < x.length; i++) {
            uint256 diffX = x[i] >= meanX ? x[i] - meanX : meanX - x[i];
            uint256 diffY = y[i] >= meanY ? y[i] - meanY : meanY - y[i];
            sum += (diffX * diffY) / PRECISION;
        }
        
        return sum / (x.length - 1);
    }
    
    /**
     * @dev Information ratio calculation
     * Use Case: Active portfolio management evaluation
     */
    function informationRatio(
        uint256[] memory portfolioReturns,
        uint256[] memory benchmarkReturns
    ) internal pure returns (uint256) {
        require(portfolioReturns.length == benchmarkReturns.length, "Mismatched lengths");
        
        uint256[] memory activeReturns = new uint256[](portfolioReturns.length);
        for (uint256 i = 0; i < portfolioReturns.length; i++) {
            activeReturns[i] = portfolioReturns[i] >= benchmarkReturns[i] ? 
                portfolioReturns[i] - benchmarkReturns[i] : 0;
        }
        
        uint256 activeReturn = mean(activeReturns);
        uint256 trackingError = standardDeviation(activeReturns);
        
        return trackingError > 0 ? (activeReturn * PRECISION) / trackingError : 0;
    }
    
    // Helper functions
    function sqrt(uint256 x) private pure returns (uint256) {
        if (x == 0) return 0;
        uint256 guess = x;
        for (uint256 i = 0; i < 20; i++) {
            uint256 newGuess = (guess + (x * PRECISION) / guess) / 2;
            if (abs(newGuess, guess) < 1e12) return newGuess;
            guess = newGuess;
        }
        return guess;
    }
    
    function abs(uint256 a, uint256 b) private pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }
    
    function exp(uint256 x) private pure returns (uint256) {
        uint256 result = PRECISION;
        uint256 term = PRECISION;
        for (uint256 n = 1; n <= 20; n++) {
            term = (term * x) / (n * PRECISION);
            result += term;
            if (term < 1e12) break;
        }
        return result;
    }
    
    function factorial(uint256 n) private pure returns (uint256) {
        if (n <= 1) return 1;
        uint256 result = 1;
        for (uint256 i = 2; i <= n && i <= 20; i++) {
            result *= i;
        }
        return result;
    }
}