// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MathUtils - Advanced Mathematical Operations Library
 * @dev Comprehensive mathematical utility library with precision calculations
 * 
 * FEATURES:
 * - High-precision arithmetic operations
 * - Advanced mathematical functions (logarithms, exponentials, trigonometry)
 * - Statistical calculations and financial mathematics
 * - Overflow-safe operations with custom precision
 * - Gas-optimized implementations
 * 
 * USE CASES:
 * 1. DeFi protocol calculations (AMM, lending, derivatives)
 * 2. Financial modeling and risk assessment
 * 3. Yield farming and staking reward calculations
 * 4. Pricing models for complex financial instruments
 * 5. Statistical analysis for governance and decision making
 * 6. Compound interest and time-value calculations
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library MathUtils {
    // Constants for high-precision calculations
    uint256 private constant PRECISION = 1e18;
    uint256 private constant HALF_PRECISION = 5e17;
    uint256 private constant MAX_UINT256 = 2**256 - 1;
    
    // Mathematical constants with 18 decimal precision
    uint256 private constant E = 2718281828459045235;  // Euler's number
    uint256 private constant PI = 3141592653589793238;  // Pi
    uint256 private constant LN2 = 693147180559945309;  // Natural log of 2
    
    /**
     * @dev Calculates compound interest with precise decimal handling
     * Use Case: DeFi lending protocols, yield farming calculations
     */
    function compoundInterest(
        uint256 principal,
        uint256 rate,
        uint256 periods
    ) internal pure returns (uint256) {
        if (periods == 0) return principal;
        
        uint256 base = PRECISION + rate;
        uint256 result = principal;
        
        // Efficient exponentiation by squaring
        uint256 exp = periods;
        uint256 currentBase = base;
        
        while (exp > 0) {
            if (exp % 2 == 1) {
                result = (result * currentBase) / PRECISION;
            }
            currentBase = (currentBase * currentBase) / PRECISION;
            exp /= 2;
        }
        
        return result;
    }
    
    /**
     * @dev Calculates square root using Babylonian method
     * Use Case: AMM price calculations, volatility calculations
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
     * @dev Calculates natural logarithm with high precision
     * Use Case: Black-Scholes calculations, risk modeling
     */
    function ln(uint256 x) internal pure returns (int256) {
        require(x > 0, "MathUtils: ln of zero or negative");
        
        if (x == PRECISION) return 0;
        
        // Handle x < 1 case
        bool negative = x < PRECISION;
        if (negative) {
            x = (PRECISION * PRECISION) / x;
        }
        
        // Use Taylor series approximation
        int256 result = 0;
        uint256 term = x - PRECISION;
        
        for (uint256 i = 1; i <= 20; i++) {
            int256 termValue = int256(term / i);
            if (i % 2 == 0) {
                result -= termValue;
            } else {
                result += termValue;
            }
            term = (term * (x - PRECISION)) / PRECISION;
        }
        
        return negative ? -result : result;
    }
    
    /**
     * @dev Calculates exponential function e^x
     * Use Case: Option pricing, yield curve calculations
     */
    function exp(int256 x) internal pure returns (uint256) {
        if (x < 0) {
            return PRECISION / exp(-x);
        }
        
        uint256 result = PRECISION;
        uint256 term = uint256(x);
        
        for (uint256 i = 1; i <= 20; i++) {
            result += term / factorial(i);
            term = (term * uint256(x)) / PRECISION;
        }
        
        return result;
    }
    
    /**
     * @dev Calculates factorial for exponential function
     * Use Case: Internal helper for exp() function
     */
    function factorial(uint256 n) internal pure returns (uint256) {
        if (n <= 1) return 1;
        
        uint256 result = 1;
        for (uint256 i = 2; i <= n; i++) {
            result *= i;
        }
        
        return result;
    }
    
    /**
     * @dev Calculates weighted average with precision handling
     * Use Case: Portfolio valuation, price aggregation
     */
    function weightedAverage(
        uint256[] memory values,
        uint256[] memory weights
    ) internal pure returns (uint256) {
        require(values.length == weights.length, "MathUtils: array length mismatch");
        
        uint256 numerator = 0;
        uint256 denominator = 0;
        
        for (uint256 i = 0; i < values.length; i++) {
            numerator += values[i] * weights[i];
            denominator += weights[i];
        }
        
        require(denominator > 0, "MathUtils: zero total weight");
        return numerator / denominator;
    }
    
    /**
     * @dev Calculates standard deviation for risk analysis
     * Use Case: Risk assessment, volatility calculations
     */
    function standardDeviation(uint256[] memory values) internal pure returns (uint256) {
        require(values.length > 1, "MathUtils: insufficient data points");
        
        uint256 mean = average(values);
        uint256 squaredDiffsSum = 0;
        
        for (uint256 i = 0; i < values.length; i++) {
            uint256 diff = values[i] > mean ? values[i] - mean : mean - values[i];
            squaredDiffsSum += (diff * diff) / PRECISION;
        }
        
        uint256 variance = squaredDiffsSum / (values.length - 1);
        return sqrt(variance * PRECISION);
    }
    
    /**
     * @dev Calculates arithmetic mean
     * Use Case: Statistical analysis, price averaging
     */
    function average(uint256[] memory values) internal pure returns (uint256) {
        require(values.length > 0, "MathUtils: empty array");
        
        uint256 sum = 0;
        for (uint256 i = 0; i < values.length; i++) {
            sum += values[i];
        }
        
        return sum / values.length;
    }
    
    /**
     * @dev Calculates percentage with precision
     * Use Case: Fee calculations, percentage-based operations
     */
    function percentage(uint256 value, uint256 percent) internal pure returns (uint256) {
        return (value * percent) / (100 * PRECISION);
    }
    
    /**
     * @dev Safe multiplication with overflow checking
     * Use Case: All mathematical operations requiring overflow protection
     */
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        
        uint256 c = a * b;
        require(c / a == b, "MathUtils: multiplication overflow");
        
        return c;
    }
    
    /**
     * @dev Calculates geometric mean for APY calculations
     * Use Case: Yield farming, compound return calculations
     */
    function geometricMean(uint256[] memory values) internal pure returns (uint256) {
        require(values.length > 0, "MathUtils: empty array");
        
        uint256 product = PRECISION;
        for (uint256 i = 0; i < values.length; i++) {
            require(values[i] > 0, "MathUtils: zero or negative value");
            product = (product * values[i]) / PRECISION;
        }
        
        // Calculate nth root using approximation
        return nthRoot(product, values.length);
    }
    
    /**
     * @dev Calculates nth root using Newton's method
     * Use Case: Internal helper for geometric mean
     */
    function nthRoot(uint256 value, uint256 n) internal pure returns (uint256) {
        require(n > 0, "MathUtils: invalid root");
        if (n == 1) return value;
        if (value == 0) return 0;
        
        uint256 x = value;
        uint256 prev;
        
        do {
            prev = x;
            uint256 x_pow_n_minus_1 = pow(x, n - 1);
            x = ((n - 1) * x + value / x_pow_n_minus_1) / n;
        } while (x < prev);
        
        return prev;
    }
    
    /**
     * @dev Calculates integer power efficiently
     * Use Case: Exponentiation operations in various calculations
     */
    function pow(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) return PRECISION;
        if (base == 0) return 0;
        
        uint256 result = PRECISION;
        uint256 currentBase = base;
        uint256 exp = exponent;
        
        while (exp > 0) {
            if (exp % 2 == 1) {
                result = (result * currentBase) / PRECISION;
            }
            currentBase = (currentBase * currentBase) / PRECISION;
            exp /= 2;
        }
        
        return result;
    }
}