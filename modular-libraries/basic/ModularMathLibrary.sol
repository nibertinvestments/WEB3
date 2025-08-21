// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ModularMathLibrary
 * @dev Mathematical Operations utility library - Basic tier implementation
 * 
 * FEATURES:
 * - Advanced mathematical operations with high precision
 * - Statistical calculations and financial mathematics
 * - Compound interest and time-value calculations
 * - Safe arithmetic operations with overflow protection
 * - Optimized algorithms for gas efficiency
 * 
 * USE CASES:
 * 1. DeFi protocol calculations (AMM, lending, derivatives)
 * 2. Financial modeling and risk assessment algorithms
 * 3. Yield farming and staking reward calculations
 * 4. Pricing models for complex financial instruments
 * 5. Statistical analysis for governance and decision making
 * 6. Compound interest and investment return calculations
 * 
 * @author Nibert Investments LLC - Enterprise Library #001
 * @notice Confidential and Proprietary Technology - Basic Tier
 */
library ModularMathLibrary {
    // Mathematical constants for high-precision calculations
    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant HALF_PRECISION = 5e17;
    uint256 internal constant MAX_PERCENTAGE = 100 * PRECISION;
    uint256 internal constant SECONDS_PER_DAY = 86400;
    uint256 internal constant DAYS_PER_YEAR = 365;
    uint256 internal constant SECONDS_PER_YEAR = DAYS_PER_YEAR * SECONDS_PER_DAY;
    
    // Mathematical constants for advanced calculations
    uint256 internal constant E_SCALED = 2718281828459045235; // e * 1e18
    uint256 internal constant PI_SCALED = 3141592653589793238; // π * 1e18
    uint256 internal constant LN_2_SCALED = 693147180559945309; // ln(2) * 1e18
    
    struct CalculationResult {
        uint256 value;
        uint256 precision;
        bool isValid;
        uint256 timestamp;
        string description;
    }
    
    struct StatisticalData {
        uint256 mean;
        uint256 median;
        uint256 standardDeviation;
        uint256 variance;
        uint256 min;
        uint256 max;
        uint256 count;
    }
    
    struct CompoundInterestParams {
        uint256 principal;
        uint256 rate;
        uint256 periods;
        uint256 compoundingFrequency;
    }
    
    // Custom errors for better error handling
    error InvalidInput(string parameter, uint256 value);
    error CalculationOverflow(uint256 value);
    error PrecisionLoss(uint256 expected, uint256 actual);
    error ValidationFailed(string reason);
    error DivisionByZero();
    error NegativeResult();
    
    /**
     * @dev Safe addition with overflow checking
     * @param a First number
     * @param b Second number
     * @return Sum of a and b
     */
    function safeAdd(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256) 
    {
        uint256 c = a + b;
        if (c < a) revert CalculationOverflow(c);
        return c;
    }
    
    /**
     * @dev Safe multiplication with overflow checking
     * @param a First number
     * @param b Second number
     * @return Product of a and b
     */
    function safeMul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256) 
    {
        if (a == 0) return 0;
        uint256 c = a * b;
        if (c / a != b) revert CalculationOverflow(c);
        return c;
    }
    
    /**
     * @dev Safe division with zero checking
     * @param a Dividend
     * @param b Divisor
     * @return Quotient of a and b
     */
    function safeDiv(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256) 
    {
        if (b == 0) revert DivisionByZero();
        return a / b;
    }
    
    /**
     * @dev Calculate percentage with high precision
     * @param value Base value
     * @param percent Percentage (scaled by PRECISION)
     * @return Percentage of value
     */
    function percentage(uint256 value, uint256 percent) 
        internal 
        pure 
        returns (uint256) 
    {
        return safeMul(value, percent) / MAX_PERCENTAGE;
    }
    
    /**
     * @dev Calculate square root using Newton's method
     * @param x Input value
     * @return y Square root of x
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    /**
     * @dev Calculate power using binary exponentiation
     * @param base Base value (scaled by PRECISION)
     * @param exponent Exponent
     * @return base^exponent (scaled by PRECISION)
     */
    function power(uint256 base, uint256 exponent) 
        internal 
        pure 
        returns (uint256) 
    {
        if (exponent == 0) return PRECISION;
        if (base == 0) return 0;
        
        uint256 result = PRECISION;
        uint256 currentBase = base;
        
        while (exponent > 0) {
            if (exponent % 2 == 1) {
                result = safeMul(result, currentBase) / PRECISION;
            }
            currentBase = safeMul(currentBase, currentBase) / PRECISION;
            exponent /= 2;
        }
        return result;
    }
    
    /**
     * @dev Calculate natural logarithm using Taylor series approximation
     * @param x Input value (scaled by PRECISION)
     * @return ln(x) (scaled by PRECISION)
     */
    function ln(uint256 x) internal pure returns (uint256) {
        if (x == 0) revert InvalidInput("ln input", x);
        if (x == PRECISION) return 0;
        
        // For x near 1, use Taylor series: ln(1+u) = u - u²/2 + u³/3 - ...
        if (x < 2 * PRECISION && x > PRECISION / 2) {
            uint256 u = x - PRECISION;
            uint256 result = u;
            uint256 term = u;
            
            for (uint256 i = 2; i <= 10; i++) {
                term = safeMul(term, u) / PRECISION;
                if (i % 2 == 0) {
                    result = result - term / i;
                } else {
                    result = result + term / i;
                }
            }
            return result;
        }
        
        // For other values, use approximation
        return _lnApproximation(x);
    }
    
    /**
     * @dev Calculate exponential function using Taylor series
     * @param x Input value (scaled by PRECISION)
     * @return e^x (scaled by PRECISION)
     */
    function exp(uint256 x) internal pure returns (uint256) {
        if (x == 0) return PRECISION;
        
        uint256 result = PRECISION;
        uint256 term = PRECISION;
        
        for (uint256 i = 1; i <= 20; i++) {
            term = safeMul(term, x) / (i * PRECISION);
            result = safeAdd(result, term);
        }
        
        return result;
    }
    
    /**
     * @dev Calculate compound interest
     * @param params Compound interest parameters
     * @return Final amount after compound interest
     */
    function compoundInterest(CompoundInterestParams memory params) 
        internal 
        pure 
        returns (uint256) 
    {
        if (params.principal == 0 || params.rate == 0 || params.periods == 0) {
            return params.principal;
        }
        
        uint256 ratePerPeriod = params.rate / params.compoundingFrequency;
        uint256 totalPeriods = params.periods * params.compoundingFrequency;
        
        uint256 multiplier = PRECISION + ratePerPeriod;
        uint256 result = params.principal;
        
        for (uint256 i = 0; i < totalPeriods; i++) {
            result = safeMul(result, multiplier) / PRECISION;
        }
        
        return result;
    }
    
    /**
     * @dev Calculate statistical measures for an array of values
     * @param values Array of values to analyze
     * @return Statistical data including mean, median, std deviation
     */
    function calculateStatistics(uint256[] memory values) 
        internal 
        pure 
        returns (StatisticalData memory) 
    {
        if (values.length == 0) revert InvalidInput("empty array", 0);
        
        // Sort array for median calculation
        _quickSort(values, 0, int256(values.length - 1));
        
        uint256 sum = 0;
        uint256 min = values[0];
        uint256 max = values[0];
        
        // Calculate sum, min, max
        for (uint256 i = 0; i < values.length; i++) {
            sum = safeAdd(sum, values[i]);
            if (values[i] < min) min = values[i];
            if (values[i] > max) max = values[i];
        }
        
        uint256 mean = sum / values.length;
        uint256 median = values.length % 2 == 0 
            ? (values[values.length / 2 - 1] + values[values.length / 2]) / 2
            : values[values.length / 2];
        
        // Calculate variance
        uint256 varianceSum = 0;
        for (uint256 i = 0; i < values.length; i++) {
            uint256 diff = values[i] > mean ? values[i] - mean : mean - values[i];
            varianceSum = safeAdd(varianceSum, safeMul(diff, diff));
        }
        
        uint256 variance = varianceSum / values.length;
        uint256 standardDeviation = sqrt(variance);
        
        return StatisticalData({
            mean: mean,
            median: median,
            standardDeviation: standardDeviation,
            variance: variance,
            min: min,
            max: max,
            count: values.length
        });
    }
    
    /**
     * @dev Calculate moving average for time series data
     * @param values Array of values
     * @param window Window size for moving average
     * @return Array of moving averages
     */
    function movingAverage(uint256[] memory values, uint256 window) 
        internal 
        pure 
        returns (uint256[] memory) 
    {
        if (window == 0 || window > values.length) {
            revert InvalidInput("window size", window);
        }
        
        uint256[] memory averages = new uint256[](values.length - window + 1);
        
        for (uint256 i = 0; i <= values.length - window; i++) {
            uint256 sum = 0;
            for (uint256 j = i; j < i + window; j++) {
                sum = safeAdd(sum, values[j]);
            }
            averages[i] = sum / window;
        }
        
        return averages;
    }
    
    /**
     * @dev Calculate weighted average
     * @param values Array of values
     * @param weights Array of weights
     * @return Weighted average
     */
    function weightedAverage(
        uint256[] memory values,
        uint256[] memory weights
    ) internal pure returns (uint256) {
        if (values.length != weights.length) {
            revert InvalidInput("array length mismatch", values.length);
        }
        
        uint256 weightedSum = 0;
        uint256 totalWeight = 0;
        
        for (uint256 i = 0; i < values.length; i++) {
            weightedSum = safeAdd(weightedSum, safeMul(values[i], weights[i]));
            totalWeight = safeAdd(totalWeight, weights[i]);
        }
        
        if (totalWeight == 0) revert DivisionByZero();
        return weightedSum / totalWeight;
    }
    
    /**
     * @dev Calculate geometric mean
     * @param values Array of values
     * @return Geometric mean
     */
    function geometricMean(uint256[] memory values) 
        internal 
        pure 
        returns (uint256) 
    {
        if (values.length == 0) revert InvalidInput("empty array", 0);
        
        uint256 product = PRECISION;
        for (uint256 i = 0; i < values.length; i++) {
            if (values[i] == 0) return 0;
            product = safeMul(product, values[i]) / PRECISION;
        }
        
        return _nthRoot(product, values.length);
    }
    
    /**
     * @dev Validate input parameters
     * @param value Value to validate
     * @param min Minimum allowed value
     * @param max Maximum allowed value
     * @return True if valid
     */
    function validateRange(uint256 value, uint256 min, uint256 max) 
        internal 
        pure 
        returns (bool) 
    {
        return value >= min && value <= max;
    }
    
    // Internal helper functions
    
    function _lnApproximation(uint256 x) private pure returns (uint256) {
        // Simplified approximation for demonstration
        // In production, would use more sophisticated algorithm
        if (x > PRECISION) {
            return safeMul(LN_2_SCALED, _log2Approximation(x));
        } else {
            return 0; // Simplified for x < 1
        }
    }
    
    function _log2Approximation(uint256 x) private pure returns (uint256) {
        if (x <= PRECISION) return 0;
        
        uint256 result = 0;
        while (x >= 2 * PRECISION) {
            x = x / 2;
            result += PRECISION;
        }
        
        return result;
    }
    
    function _nthRoot(uint256 value, uint256 n) private pure returns (uint256) {
        if (n == 0) revert DivisionByZero();
        if (n == 1) return value;
        if (value == 0) return 0;
        
        uint256 x = value;
        uint256 y = (x + PRECISION) / 2;
        
        while (y < x) {
            x = y;
            uint256 sum = (n - 1) * x + value / power(x, n - 1);
            y = sum / n;
        }
        
        return x;
    }
    
    function _quickSort(uint256[] memory arr, int256 left, int256 right) private pure {
        if (left < right) {
            int256 pivotIndex = _partition(arr, left, right);
            _quickSort(arr, left, pivotIndex - 1);
            _quickSort(arr, pivotIndex + 1, right);
        }
    }
    
    function _partition(uint256[] memory arr, int256 left, int256 right) 
        private 
        pure 
        returns (int256) 
    {
        uint256 pivot = arr[uint256(right)];
        int256 i = left - 1;
        
        for (int256 j = left; j < right; j++) {
            if (arr[uint256(j)] <= pivot) {
                i++;
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
            }
        }
        
        (arr[uint256(i + 1)], arr[uint256(right)]) = (arr[uint256(right)], arr[uint256(i + 1)]);
        return i + 1;
    }
}