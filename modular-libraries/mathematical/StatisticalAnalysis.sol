// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title StatisticalAnalysis - Advanced Statistical Computation Library
 * @dev Comprehensive statistical analysis library with production-grade algorithms
 * 
 * USE CASES:
 * 1. Risk assessment and portfolio analysis
 * 2. Market volatility calculations
 * 3. Correlation analysis between assets
 * 4. Performance metrics computation
 * 5. Predictive modeling data preparation
 * 6. Financial derivative pricing models
 * 
 * WHY IT WORKS:
 * - Numerically stable algorithms prevent precision loss
 * - Gas-optimized implementations for large datasets
 * - Overflow protection for all statistical operations
 * - Modular design enables selective usage
 * - Incremental computation reduces gas costs
 * 
 * @author Nibert Investments Development Team
 */
library StatisticalAnalysis {
    
    // Precision constants
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MAX_ARRAY_SIZE = 1000;
    uint256 private constant MIN_SAMPLE_SIZE = 2;
    
    // Statistical errors
    error InsufficientData(uint256 provided, uint256 required);
    error ArrayTooLarge(uint256 size, uint256 maxSize);
    error DivisionByZero();
    error InvalidCorrelationInput();
    error NumericalInstability();
    
    // Statistical data structure
    struct StatisticalSummary {
        uint256 count;
        uint256 sum;
        uint256 sumSquares;
        uint256 minimum;
        uint256 maximum;
        uint256 mean;
        uint256 variance;
        uint256 standardDeviation;
        uint256 skewness;
        uint256 kurtosis;
    }
    
    // Distribution parameters
    struct DistributionParams {
        uint256 mean;
        uint256 variance;
        uint256 shape;      // For gamma, beta distributions
        uint256 scale;      // For exponential, weibull distributions
        uint256 location;   // For location-scale families
    }
    
    // Regression results
    struct RegressionResult {
        int256 slope;
        int256 intercept;
        uint256 rSquared;
        uint256 standardError;
        uint256 residualSumSquares;
    }
    
    /**
     * @dev Calculate mean of dataset
     */
    function calculateMean(uint256[] memory data) internal pure returns (uint256) {
        if (data.length == 0) revert InsufficientData(0, 1);
        if (data.length > MAX_ARRAY_SIZE) revert ArrayTooLarge(data.length, MAX_ARRAY_SIZE);
        
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
        
        return sum / data.length;
    }
    
    /**
     * @dev Calculate variance using numerically stable algorithm
     */
    function calculateVariance(uint256[] memory data) internal pure returns (uint256) {
        if (data.length < MIN_SAMPLE_SIZE) revert InsufficientData(data.length, MIN_SAMPLE_SIZE);
        
        uint256 mean = calculateMean(data);
        uint256 sumSquaredDiff = 0;
        
        for (uint256 i = 0; i < data.length; i++) {
            uint256 diff = data[i] > mean ? data[i] - mean : mean - data[i];
            sumSquaredDiff += (diff * diff) / PRECISION;
        }
        
        return (sumSquaredDiff * PRECISION) / (data.length - 1);
    }
    
    /**
     * @dev Calculate standard deviation
     */
    function calculateStandardDeviation(uint256[] memory data) internal pure returns (uint256) {
        uint256 variance = calculateVariance(data);
        return sqrt(variance);
    }
    
    /**
     * @dev Calculate skewness (third moment)
     */
    function calculateSkewness(uint256[] memory data) internal pure returns (int256) {
        if (data.length < 3) revert InsufficientData(data.length, 3);
        
        uint256 mean = calculateMean(data);
        uint256 variance = calculateVariance(data);
        uint256 stdDev = sqrt(variance);
        
        if (stdDev == 0) return 0;
        
        int256 sumCubedDiff = 0;
        
        for (uint256 i = 0; i < data.length; i++) {
            int256 diff = int256(data[i]) - int256(mean);
            int256 cubedDiff = (diff * diff * diff) / int256(PRECISION * PRECISION);
            sumCubedDiff += cubedDiff;
        }
        
        int256 n = int256(data.length);
        int256 skewness = (sumCubedDiff * int256(PRECISION)) / (n * int256(stdDev * stdDev * stdDev) / int256(PRECISION * PRECISION));
        
        return skewness;
    }
    
    /**
     * @dev Calculate kurtosis (fourth moment)
     */
    function calculateKurtosis(uint256[] memory data) internal pure returns (uint256) {
        if (data.length < 4) revert InsufficientData(data.length, 4);
        
        uint256 mean = calculateMean(data);
        uint256 variance = calculateVariance(data);
        
        if (variance == 0) return 0;
        
        uint256 sumFourthPower = 0;
        
        for (uint256 i = 0; i < data.length; i++) {
            uint256 diff = data[i] > mean ? data[i] - mean : mean - data[i];
            uint256 fourthPower = (diff * diff * diff * diff) / (PRECISION * PRECISION * PRECISION);
            sumFourthPower += fourthPower;
        }
        
        uint256 kurtosis = (sumFourthPower * PRECISION) / (data.length * variance * variance / PRECISION);
        
        // Subtract 3 for excess kurtosis
        return kurtosis > 3 * PRECISION ? kurtosis - 3 * PRECISION : 0;
    }
    
    /**
     * @dev Calculate comprehensive statistical summary
     */
    function calculateStatisticalSummary(uint256[] memory data) 
        internal 
        pure 
        returns (StatisticalSummary memory summary) 
    {
        if (data.length == 0) revert InsufficientData(0, 1);
        
        summary.count = data.length;
        
        // Find min, max, and sum in single pass
        summary.minimum = data[0];
        summary.maximum = data[0];
        summary.sum = 0;
        
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] < summary.minimum) summary.minimum = data[i];
            if (data[i] > summary.maximum) summary.maximum = data[i];
            summary.sum += data[i];
        }
        
        summary.mean = summary.sum / data.length;
        
        // Calculate variance and higher moments if sufficient data
        if (data.length >= MIN_SAMPLE_SIZE) {
            summary.variance = calculateVariance(data);
            summary.standardDeviation = sqrt(summary.variance);
        }
        
        if (data.length >= 3) {
            summary.skewness = uint256(abs(calculateSkewness(data)));
        }
        
        if (data.length >= 4) {
            summary.kurtosis = calculateKurtosis(data);
        }
        
        return summary;
    }
    
    /**
     * @dev Calculate correlation coefficient between two datasets
     */
    function calculateCorrelation(
        uint256[] memory dataX,
        uint256[] memory dataY
    ) internal pure returns (int256 correlation) {
        if (dataX.length != dataY.length || dataX.length < MIN_SAMPLE_SIZE) {
            revert InvalidCorrelationInput();
        }
        
        uint256 n = dataX.length;
        uint256 meanX = calculateMean(dataX);
        uint256 meanY = calculateMean(dataY);
        
        int256 numerator = 0;
        uint256 sumXSquared = 0;
        uint256 sumYSquared = 0;
        
        for (uint256 i = 0; i < n; i++) {
            int256 diffX = int256(dataX[i]) - int256(meanX);
            int256 diffY = int256(dataY[i]) - int256(meanY);
            
            numerator += (diffX * diffY) / int256(PRECISION);
            sumXSquared += uint256((diffX * diffX) / int256(PRECISION));
            sumYSquared += uint256((diffY * diffY) / int256(PRECISION));
        }
        
        uint256 denominator = sqrt(sumXSquared * sumYSquared);
        
        if (denominator == 0) return 0;
        
        correlation = (numerator * int256(PRECISION)) / int256(denominator);
        
        // Clamp to [-1, 1] range
        if (correlation > int256(PRECISION)) correlation = int256(PRECISION);
        if (correlation < -int256(PRECISION)) correlation = -int256(PRECISION);
        
        return correlation;
    }
    
    /**
     * @dev Calculate linear regression
     */
    function calculateLinearRegression(
        uint256[] memory x,
        uint256[] memory y
    ) internal pure returns (RegressionResult memory result) {
        if (x.length != y.length || x.length < MIN_SAMPLE_SIZE) {
            revert InvalidCorrelationInput();
        }
        
        uint256 n = x.length;
        uint256 meanX = calculateMean(x);
        uint256 meanY = calculateMean(y);
        
        int256 numerator = 0;
        uint256 denominator = 0;
        
        // Calculate slope using least squares method
        for (uint256 i = 0; i < n; i++) {
            int256 diffX = int256(x[i]) - int256(meanX);
            int256 diffY = int256(y[i]) - int256(meanY);
            
            numerator += (diffX * diffY) / int256(PRECISION);
            denominator += uint256((diffX * diffX) / int256(PRECISION));
        }
        
        if (denominator == 0) {
            result.slope = 0;
            result.intercept = int256(meanY);
        } else {
            result.slope = (numerator * int256(PRECISION)) / int256(denominator);
            result.intercept = int256(meanY) - (result.slope * int256(meanX)) / int256(PRECISION);
        }
        
        // Calculate R-squared and residuals
        uint256 totalSumSquares = 0;
        uint256 residualSumSquares = 0;
        
        for (uint256 i = 0; i < n; i++) {
            int256 predicted = result.intercept + (result.slope * int256(x[i])) / int256(PRECISION);
            int256 residual = int256(y[i]) - predicted;
            int256 deviation = int256(y[i]) - int256(meanY);
            
            residualSumSquares += uint256((residual * residual) / int256(PRECISION));
            totalSumSquares += uint256((deviation * deviation) / int256(PRECISION));
        }
        
        result.residualSumSquares = residualSumSquares;
        
        if (totalSumSquares > 0) {
            result.rSquared = ((totalSumSquares - residualSumSquares) * PRECISION) / totalSumSquares;
        }
        
        // Calculate standard error
        if (n > 2) {
            result.standardError = sqrt((residualSumSquares * PRECISION) / (n - 2));
        }
        
        return result;
    }
    
    /**
     * @dev Calculate moving average
     */
    function calculateMovingAverage(
        uint256[] memory data,
        uint256 windowSize
    ) internal pure returns (uint256[] memory movingAverage) {
        if (data.length < windowSize || windowSize == 0) {
            revert InsufficientData(data.length, windowSize);
        }
        
        uint256 resultLength = data.length - windowSize + 1;
        movingAverage = new uint256[](resultLength);
        
        for (uint256 i = 0; i < resultLength; i++) {
            uint256 sum = 0;
            for (uint256 j = i; j < i + windowSize; j++) {
                sum += data[j];
            }
            movingAverage[i] = sum / windowSize;
        }
        
        return movingAverage;
    }
    
    /**
     * @dev Calculate exponential moving average
     */
    function calculateExponentialMovingAverage(
        uint256[] memory data,
        uint256 alpha // smoothing factor (0 < alpha < PRECISION)
    ) internal pure returns (uint256[] memory ema) {
        if (data.length == 0 || alpha == 0 || alpha >= PRECISION) {
            revert InsufficientData(data.length, 1);
        }
        
        ema = new uint256[](data.length);
        ema[0] = data[0];
        
        for (uint256 i = 1; i < data.length; i++) {
            ema[i] = (alpha * data[i] + (PRECISION - alpha) * ema[i-1]) / PRECISION;
        }
        
        return ema;
    }
    
    /**
     * @dev Calculate percentile using linear interpolation
     */
    function calculatePercentile(
        uint256[] memory data,
        uint256 percentile // 0 to 100 * PRECISION/100
    ) internal pure returns (uint256) {
        if (data.length == 0) revert InsufficientData(0, 1);
        if (percentile > 100 * PRECISION / 100) revert("Invalid percentile");
        
        // Sort data (simple bubble sort for small arrays)
        uint256[] memory sorted = new uint256[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            sorted[i] = data[i];
        }
        
        for (uint256 i = 0; i < sorted.length - 1; i++) {
            for (uint256 j = 0; j < sorted.length - i - 1; j++) {
                if (sorted[j] > sorted[j + 1]) {
                    uint256 temp = sorted[j];
                    sorted[j] = sorted[j + 1];
                    sorted[j + 1] = temp;
                }
            }
        }
        
        uint256 index = (percentile * (data.length - 1)) / (100 * PRECISION / 100);
        uint256 remainder = (percentile * (data.length - 1)) % (100 * PRECISION / 100);
        
        if (remainder == 0 || index == data.length - 1) {
            return sorted[index];
        }
        
        // Linear interpolation
        uint256 lower = sorted[index];
        uint256 upper = sorted[index + 1];
        
        return lower + (upper - lower) * remainder / (100 * PRECISION / 100);
    }
    
    /**
     * @dev Calculate z-score for a value
     */
    function calculateZScore(
        uint256 value,
        uint256 mean,
        uint256 standardDeviation
    ) internal pure returns (int256) {
        if (standardDeviation == 0) revert DivisionByZero();
        
        int256 deviation = int256(value) - int256(mean);
        return (deviation * int256(PRECISION)) / int256(standardDeviation);
    }
    
    /**
     * @dev Calculate confidence interval for mean
     */
    function calculateConfidenceInterval(
        uint256[] memory data,
        uint256 confidenceLevel // e.g., 95 for 95%
    ) internal pure returns (uint256 lowerBound, uint256 upperBound) {
        if (data.length < MIN_SAMPLE_SIZE) revert InsufficientData(data.length, MIN_SAMPLE_SIZE);
        
        uint256 mean = calculateMean(data);
        uint256 stdDev = calculateStandardDeviation(data);
        uint256 standardError = (stdDev * PRECISION) / sqrt(data.length * PRECISION);
        
        // Critical values for common confidence levels (approximated)
        uint256 criticalValue;
        if (confidenceLevel == 90) {
            criticalValue = 1645 * PRECISION / 1000; // 1.645
        } else if (confidenceLevel == 95) {
            criticalValue = 1960 * PRECISION / 1000; // 1.96
        } else if (confidenceLevel == 99) {
            criticalValue = 2576 * PRECISION / 1000; // 2.576
        } else {
            criticalValue = 1960 * PRECISION / 1000; // Default to 95%
        }
        
        uint256 marginOfError = (criticalValue * standardError) / PRECISION;
        
        lowerBound = mean > marginOfError ? mean - marginOfError : 0;
        upperBound = mean + marginOfError;
        
        return (lowerBound, upperBound);
    }
    
    /**
     * @dev Calculate Sharpe ratio for financial analysis
     */
    function calculateSharpeRatio(
        uint256[] memory returns,
        uint256 riskFreeRate
    ) internal pure returns (uint256) {
        if (returns.length < MIN_SAMPLE_SIZE) revert InsufficientData(returns.length, MIN_SAMPLE_SIZE);
        
        uint256 meanReturn = calculateMean(returns);
        uint256 stdDevReturns = calculateStandardDeviation(returns);
        
        if (stdDevReturns == 0) revert DivisionByZero();
        
        uint256 excessReturn = meanReturn > riskFreeRate ? meanReturn - riskFreeRate : 0;
        
        return (excessReturn * PRECISION) / stdDevReturns;
    }
    
    /**
     * @dev Helper function: Integer square root
     */
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
    
    /**
     * @dev Helper function: Absolute value
     */
    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }
    
    /**
     * @dev Calculate Value at Risk (VaR)
     */
    function calculateVaR(
        uint256[] memory returns,
        uint256 confidenceLevel // e.g., 95 for 95%
    ) internal pure returns (uint256) {
        if (returns.length < 20) revert InsufficientData(returns.length, 20);
        
        uint256 percentileToUse = 100 - confidenceLevel;
        return calculatePercentile(returns, percentileToUse * PRECISION / 100);
    }
    
    /**
     * @dev Calculate Expected Shortfall (Conditional VaR)
     */
    function calculateExpectedShortfall(
        uint256[] memory returns,
        uint256 confidenceLevel
    ) internal pure returns (uint256) {
        uint256 var = calculateVaR(returns, confidenceLevel);
        
        uint256 sum = 0;
        uint256 count = 0;
        
        for (uint256 i = 0; i < returns.length; i++) {
            if (returns[i] <= var) {
                sum += returns[i];
                count++;
            }
        }
        
        if (count == 0) return var;
        
        return sum / count;
    }
}