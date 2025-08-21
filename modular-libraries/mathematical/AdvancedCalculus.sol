// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AdvancedCalculus - Advanced Mathematical Calculus Library
 * @dev Implements advanced calculus operations for DeFi and financial modeling
 * 
 * FEATURES:
 * - Numerical integration using Simpson's rule and trapezoidal methods
 * - Numerical differentiation with multiple precision levels
 * - Taylor series expansions for complex functions
 * - Multi-variable calculus approximations
 * - Optimization algorithms (gradient descent, Newton's method)
 * - Fourier transform approximations for signal analysis
 * 
 * USE CASES:
 * 1. Options pricing using Black-Scholes differential equations
 * 2. Risk modeling with continuous probability distributions
 * 3. Yield curve construction and interpolation
 * 4. Portfolio optimization using calculus-based methods
 * 5. Automated market maker curve analysis
 * 6. Volatility surface modeling
 * 7. Financial derivative sensitivity calculations (Greeks)
 * 8. Credit risk modeling with continuous-time models
 * 
 * @author Nibert Investments LLC
 * @notice Advanced Mathematical Operations for Financial Applications
 */

library AdvancedCalculus {
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MAX_ITERATIONS = 1000;
    uint256 private constant CONVERGENCE_THRESHOLD = 1e12; // 1e-6 in 1e18 precision
    
    // Error definitions
    error ConvergenceFailure();
    error InvalidInput();
    error MaxIterationsExceeded();
    
    /**
     * @dev Numerical integration using Simpson's rule
     * Use Case: Options pricing integration, probability calculations
     */
    function simpsonsRule(
        uint256[] memory yValues,
        uint256 stepSize
    ) internal pure returns (uint256) {
        require(yValues.length >= 3, "Insufficient data points");
        require(yValues.length % 2 == 1, "Odd number of points required");
        
        uint256 result = yValues[0] + yValues[yValues.length - 1];
        
        // Apply Simpson's coefficients
        for (uint256 i = 1; i < yValues.length - 1; i++) {
            if (i % 2 == 1) {
                result += 4 * yValues[i];
            } else {
                result += 2 * yValues[i];
            }
        }
        
        return (result * stepSize) / 3;
    }
    
    /**
     * @dev Numerical differentiation using central difference method
     * Use Case: Calculating Greeks for options, sensitivity analysis
     */
    function centralDifference(
        uint256 f_plus_h,
        uint256 f_minus_h,
        uint256 stepSize
    ) internal pure returns (uint256) {
        if (f_plus_h >= f_minus_h) {
            return ((f_plus_h - f_minus_h) * PRECISION) / (2 * stepSize);
        } else {
            return ((f_minus_h - f_plus_h) * PRECISION) / (2 * stepSize);
        }
    }
    
    /**
     * @dev Taylor series expansion for exponential function
     * Use Case: Compound interest calculations, growth modeling
     */
    function exponentialTaylor(
        uint256 x,
        uint256 terms
    ) internal pure returns (uint256) {
        if (terms == 0) return PRECISION;
        
        uint256 result = PRECISION; // e^0 = 1
        uint256 term = PRECISION;
        
        for (uint256 n = 1; n <= terms; n++) {
            term = (term * x) / (n * PRECISION);
            result += term;
            
            // Prevent overflow
            if (term < CONVERGENCE_THRESHOLD) break;
        }
        
        return result;
    }
    
    /**
     * @dev Natural logarithm using Taylor series
     * Use Case: Log-normal distributions, volatility calculations
     */
    function naturalLogTaylor(
        uint256 x
    ) internal pure returns (uint256) {
        require(x > 0, "Log undefined for non-positive values");
        
        if (x == PRECISION) return 0; // ln(1) = 0
        
        // Transform to range where series converges: ln(x) = ln(1+y) where y = x-1
        uint256 y;
        bool negative = false;
        
        if (x > PRECISION) {
            y = x - PRECISION;
        } else {
            y = PRECISION - x;
            negative = true;
        }
        
        // Series: ln(1+y) = y - y²/2 + y³/3 - y⁴/4 + ...
        uint256 result = 0;
        uint256 term = y;
        
        for (uint256 n = 1; n <= 50; n++) {
            if (n % 2 == 1) {
                result += term / n;
            } else {
                result -= term / n;
            }
            
            term = (term * y) / PRECISION;
            if (term < CONVERGENCE_THRESHOLD) break;
        }
        
        return negative ? 0 : result; // Simplified for positive results
    }
    
    /**
     * @dev Newton's method for finding roots
     * Use Case: Implied volatility calculations, yield curve bootstrapping
     */
    function newtonsMethod(
        uint256 initialGuess,
        uint256 target,
        function(uint256) pure returns (uint256, uint256) evaluator
    ) internal pure returns (uint256) {
        uint256 x = initialGuess;
        
        for (uint256 i = 0; i < MAX_ITERATIONS; i++) {
            (uint256 fx, uint256 fpx) = evaluator(x);
            
            if (fpx == 0) revert InvalidInput();
            
            uint256 newX = x - ((fx - target) * PRECISION) / fpx;
            
            if (abs(newX, x) < CONVERGENCE_THRESHOLD) {
                return newX;
            }
            
            x = newX;
        }
        
        revert ConvergenceFailure();
    }
    
    /**
     * @dev Gradient descent optimization
     * Use Case: Portfolio optimization, parameter estimation
     */
    function gradientDescent(
        uint256[] memory initialWeights,
        uint256 learningRate,
        function(uint256[] memory) pure returns (uint256, uint256[] memory) objective
    ) internal pure returns (uint256[] memory) {
        uint256[] memory weights = initialWeights;
        uint256[] memory newWeights = new uint256[](weights.length);
        
        for (uint256 iter = 0; iter < MAX_ITERATIONS; iter++) {
            (uint256 cost, uint256[] memory gradients) = objective(weights);
            
            bool converged = true;
            for (uint256 i = 0; i < weights.length; i++) {
                uint256 update = (gradients[i] * learningRate) / PRECISION;
                newWeights[i] = weights[i] > update ? weights[i] - update : 0;
                
                if (abs(newWeights[i], weights[i]) >= CONVERGENCE_THRESHOLD) {
                    converged = false;
                }
                weights[i] = newWeights[i];
            }
            
            if (converged) break;
        }
        
        return weights;
    }
    
    /**
     * @dev Numerical integration for Black-Scholes formula
     * Use Case: European options pricing
     */
    function blackScholesIntegral(
        uint256 spot,
        uint256 strike,
        uint256 timeToExpiry,
        uint256 riskFreeRate,
        uint256 volatility
    ) internal pure returns (uint256) {
        // Simplified Black-Scholes calculation using numerical methods
        uint256 d1 = calculateD1(spot, strike, timeToExpiry, riskFreeRate, volatility);
        uint256 d2 = d1 - (volatility * sqrt(timeToExpiry)) / PRECISION;
        
        uint256 callPrice = (spot * cumulativeNormalDistribution(d1)) - 
                           (strike * exponentialTaylor((riskFreeRate * timeToExpiry) / PRECISION, 20) * 
                            cumulativeNormalDistribution(d2)) / PRECISION;
        
        return callPrice;
    }
    
    /**
     * @dev Calculate d1 parameter for Black-Scholes
     */
    function calculateD1(
        uint256 spot,
        uint256 strike,
        uint256 timeToExpiry,
        uint256 riskFreeRate,
        uint256 volatility
    ) internal pure returns (uint256) {
        uint256 logRatio = naturalLogTaylor((spot * PRECISION) / strike);
        uint256 riskFreeTerm = (riskFreeRate * timeToExpiry) / PRECISION;
        uint256 volatilityTerm = (volatility * volatility * timeToExpiry) / (2 * PRECISION);
        uint256 denominator = (volatility * sqrt(timeToExpiry)) / PRECISION;
        
        return ((logRatio + riskFreeTerm + volatilityTerm) * PRECISION) / denominator;
    }
    
    /**
     * @dev Cumulative normal distribution approximation
     * Use Case: Options pricing, risk calculations
     */
    function cumulativeNormalDistribution(uint256 x) internal pure returns (uint256) {
        // Abramowitz and Stegun approximation
        uint256 a1 = 254829592; // 0.254829592 * 1e9
        uint256 a2 = 284496736; // -0.284496736 * 1e9
        uint256 a3 = 1421413741; // 1.421413741 * 1e9
        uint256 a4 = 1453152027; // -1.453152027 * 1e9
        uint256 a5 = 1061405429; // 1.061405429 * 1e9
        uint256 p = 327591100; // 0.3275911 * 1e9
        
        // Simplified implementation for positive values
        uint256 t = PRECISION / (PRECISION + (p * x) / 1e9);
        uint256 y = PRECISION - (((((a5 * t / 1e9 + a4) * t / 1e9 + a3) * t / 1e9 + a2) * t / 1e9 + a1) * t / 1e9);
        
        return y;
    }
    
    /**
     * @dev Square root calculation using Newton's method
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        
        uint256 guess = x;
        for (uint256 i = 0; i < 20; i++) {
            uint256 newGuess = (guess + (x * PRECISION) / guess) / 2;
            if (abs(newGuess, guess) < CONVERGENCE_THRESHOLD) {
                return newGuess;
            }
            guess = newGuess;
        }
        return guess;
    }
    
    /**
     * @dev Absolute difference between two numbers
     */
    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }
    
    /**
     * @dev Fourier transform coefficient calculation
     * Use Case: Signal analysis for market data, cycle detection
     */
    function fourierCoefficient(
        uint256[] memory timeSeries,
        uint256 frequency,
        bool isReal
    ) internal pure returns (uint256) {
        uint256 n = timeSeries.length;
        uint256 result = 0;
        
        for (uint256 k = 0; k < n; k++) {
            uint256 angle = (2 * 31415926 * frequency * k) / (n * 10000000); // 2π approximation
            
            if (isReal) {
                result += (timeSeries[k] * cos(angle)) / PRECISION;
            } else {
                result += (timeSeries[k] * sin(angle)) / PRECISION;
            }
        }
        
        return (result * 2) / n;
    }
    
    /**
     * @dev Cosine calculation using Taylor series
     */
    function cos(uint256 x) internal pure returns (uint256) {
        // Reduce to [0, 2π] range
        x = x % (2 * 31415926 / 10000000);
        
        uint256 result = PRECISION;
        uint256 term = PRECISION;
        
        for (uint256 n = 1; n <= 10; n++) {
            term = (term * x * x) / ((2 * n - 1) * (2 * n) * PRECISION);
            if (n % 2 == 1) {
                result -= term;
            } else {
                result += term;
            }
        }
        
        return result;
    }
    
    /**
     * @dev Sine calculation using Taylor series
     */
    function sin(uint256 x) internal pure returns (uint256) {
        // Reduce to [0, 2π] range
        x = x % (2 * 31415926 / 10000000);
        
        uint256 result = x;
        uint256 term = x;
        
        for (uint256 n = 1; n <= 10; n++) {
            term = (term * x * x) / ((2 * n) * (2 * n + 1) * PRECISION);
            if (n % 2 == 1) {
                result -= term;
            } else {
                result += term;
            }
        }
        
        return result;
    }
    
    /**
     * @dev Partial derivative approximation for multi-variable functions
     * Use Case: Portfolio sensitivity analysis, risk management
     */
    function partialDerivative(
        uint256[] memory variables,
        uint256 variableIndex,
        uint256 stepSize,
        function(uint256[] memory) pure returns (uint256) func
    ) internal pure returns (uint256) {
        require(variableIndex < variables.length, "Invalid variable index");
        
        uint256[] memory varsPlus = new uint256[](variables.length);
        uint256[] memory varsMinus = new uint256[](variables.length);
        
        for (uint256 i = 0; i < variables.length; i++) {
            varsPlus[i] = variables[i];
            varsMinus[i] = variables[i];
        }
        
        varsPlus[variableIndex] += stepSize;
        varsMinus[variableIndex] -= stepSize;
        
        uint256 fPlus = func(varsPlus);
        uint256 fMinus = func(varsMinus);
        
        return centralDifference(fPlus, fMinus, stepSize);
    }
}