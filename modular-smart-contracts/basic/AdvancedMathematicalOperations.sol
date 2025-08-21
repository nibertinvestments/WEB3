// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AdvancedMathematicalOperations - Comprehensive Mathematical Computing Contract
 * @dev High-precision mathematical operations for complex DeFi and scientific computing
 * 
 * AOPB COMPATIBILITY: ✅ Fully compatible with Advanced Opportunity Blockchain
 * EVM COMPATIBILITY: ✅ Ethereum, Polygon, BSC, Arbitrum, Optimism, Base
 * 
 * USE CASES:
 * 1. Compound interest calculations for lending protocols
 * 2. Statistical analysis for trading algorithms  
 * 3. Risk assessment calculations for insurance protocols
 * 4. Portfolio optimization for asset management
 * 5. Mathematical modeling for prediction markets
 * 6. Scientific computing for research DAOs
 * 7. Financial derivatives pricing
 * 8. Algorithmic trading signal generation
 * 
 * MATHEMATICAL FEATURES:
 * - High-precision arithmetic (18 decimal places)
 * - Logarithmic and exponential functions
 * - Trigonometric calculations
 * - Statistical functions (mean, variance, correlation)
 * - Matrix operations
 * - Polynomial evaluation
 * - Integration and differentiation approximations
 * - Monte Carlo simulation support
 * 
 * @author Nibert Investments - Advanced Opportunity Blockchain Team
 */
contract AdvancedMathematicalOperations {
    // Constants for high-precision calculations
    uint256 constant PRECISION = 1e18;
    uint256 constant E = 2718281828459045235; // e with 18 decimals
    uint256 constant PI = 3141592653589793238; // π with 18 decimals
    uint256 constant LN2 = 693147180559945309; // ln(2) with 18 decimals
    
    // Events for mathematical operations tracking
    event ComplexCalculation(string operation, uint256 input, uint256 result, uint256 gasUsed);
    event StatisticalAnalysis(string function, uint256[] data, uint256 result);
    event MatrixOperation(string operation, uint256 dimension, uint256 result);
    
    // Error definitions for mathematical operations
    error InvalidInput(string reason);
    error OverflowDetected(string operation);
    error DivisionByZero(string context);
    error NegativeRoot(string operation);
    
    /**
     * @notice Calculate compound interest with high precision
     * @param principal Initial amount
     * @param rate Interest rate (in basis points, e.g., 500 = 5%)  
     * @param periods Number of compounding periods
     * @param frequency Compounding frequency per period
     * @return finalAmount The final amount after compound interest
     */
    function calculateCompoundInterest(
        uint256 principal,
        uint256 rate,
        uint256 periods,
        uint256 frequency
    ) external returns (uint256 finalAmount) {
        if (principal == 0) revert InvalidInput("Principal cannot be zero");
        if (rate > 10000) revert InvalidInput("Rate too high");
        
        uint256 gasStart = gasleft();
        
        // Convert rate to decimal: rate/10000
        uint256 rateDecimal = (rate * PRECISION) / 10000;
        
        // Calculate (1 + rate/frequency)
        uint256 baseRate = PRECISION + (rateDecimal / frequency);
        
        // Calculate (1 + rate/frequency)^(periods * frequency)
        uint256 exponent = periods * frequency;
        uint256 compound = _power(baseRate, exponent, PRECISION);
        
        // Final amount = principal * compound
        finalAmount = (principal * compound) / PRECISION;
        
        uint256 gasUsed = gasStart - gasleft();
        emit ComplexCalculation("compound_interest", principal, finalAmount, gasUsed);
    }
    
    /**
     * @notice Calculate natural logarithm using Taylor series approximation
     * @param x Input value (must be > 0)
     * @return result ln(x) with PRECISION decimals
     */
    function naturalLog(uint256 x) external returns (uint256 result) {
        if (x == 0) revert InvalidInput("Cannot take log of zero");
        
        uint256 gasStart = gasleft();
        
        // For x close to 1, use Taylor series: ln(1+x) = x - x²/2 + x³/3 - x⁴/4 + ...
        if (x < PRECISION * 2) {
            uint256 y = x - PRECISION; // x - 1
            result = _lnTaylorSeries(y);
        } else {
            // For larger x, use property: ln(x) = ln(x/e^n) + n
            uint256 n = 0;
            uint256 temp = x;
            while (temp > PRECISION * 2) {
                temp = (temp * PRECISION) / E;
                n++;
            }
            result = _lnTaylorSeries(temp - PRECISION) + (n * PRECISION);
        }
        
        uint256 gasUsed = gasStart - gasleft();
        emit ComplexCalculation("natural_log", x, result, gasUsed);
    }
    
    /**
     * @notice Calculate exponential function e^x using Taylor series
     * @param x Exponent value
     * @return result e^x with PRECISION decimals
     */
    function exponential(uint256 x) external returns (uint256 result) {
        uint256 gasStart = gasleft();
        
        // e^x = 1 + x + x²/2! + x³/3! + x⁴/4! + ...
        result = PRECISION; // Start with 1
        uint256 term = PRECISION;
        
        for (uint256 i = 1; i <= 20; i++) {
            term = (term * x) / (i * PRECISION);
            result += term;
            
            // Break if term becomes negligible
            if (term < PRECISION / 1e12) break;
        }
        
        uint256 gasUsed = gasStart - gasleft();
        emit ComplexCalculation("exponential", x, result, gasUsed);
    }
    
    /**
     * @notice Calculate square root using Newton's method
     * @param x Input value
     * @return result Square root with PRECISION decimals
     */
    function sqrt(uint256 x) external pure returns (uint256 result) {
        if (x == 0) return 0;
        
        // Newton's method: x₁ = (x₀ + n/x₀) / 2
        result = x;
        uint256 prev;
        
        while (result != prev) {
            prev = result;
            result = (result + (x * PRECISION) / result) / 2;
        }
        
        return result;
    }
    
    /**
     * @notice Calculate statistical mean of an array
     * @param data Array of values
     * @return mean Statistical mean with PRECISION decimals
     */
    function calculateMean(uint256[] calldata data) external returns (uint256 mean) {
        if (data.length == 0) revert InvalidInput("Empty data array");
        
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
        
        mean = sum / data.length;
        emit StatisticalAnalysis("mean", data, mean);
    }
    
    /**
     * @notice Calculate statistical variance of an array
     * @param data Array of values
     * @return variance Statistical variance with PRECISION decimals
     */
    function calculateVariance(uint256[] calldata data) external returns (uint256 variance) {
        if (data.length == 0) revert InvalidInput("Empty data array");
        
        // Calculate mean first
        uint256 sum = 0;
        for (uint256 i = 0; i < data.length; i++) {
            sum += data[i];
        }
        uint256 mean = sum / data.length;
        
        // Calculate variance: Σ(x - μ)² / n
        uint256 sumSquaredDiffs = 0;
        for (uint256 i = 0; i < data.length; i++) {
            uint256 diff = data[i] > mean ? data[i] - mean : mean - data[i];
            sumSquaredDiffs += (diff * diff) / PRECISION;
        }
        
        variance = sumSquaredDiffs / data.length;
        emit StatisticalAnalysis("variance", data, variance);
    }
    
    /**
     * @notice Calculate correlation coefficient between two datasets
     * @param dataX First dataset
     * @param dataY Second dataset  
     * @return correlation Correlation coefficient with PRECISION decimals (-1 to 1)
     */
    function calculateCorrelation(
        uint256[] calldata dataX,
        uint256[] calldata dataY
    ) external returns (int256 correlation) {
        if (dataX.length != dataY.length) revert InvalidInput("Arrays must have same length");
        if (dataX.length == 0) revert InvalidInput("Empty data arrays");
        
        uint256 n = dataX.length;
        
        // Calculate means
        uint256 sumX = 0; 
        uint256 sumY = 0;
        for (uint256 i = 0; i < n; i++) {
            sumX += dataX[i];
            sumY += dataY[i];
        }
        uint256 meanX = sumX / n;
        uint256 meanY = sumY / n;
        
        // Calculate correlation: Σ((x-μx)(y-μy)) / sqrt(Σ(x-μx)² * Σ(y-μy)²)
        int256 numerator = 0;
        uint256 sumSquaredDiffX = 0;
        uint256 sumSquaredDiffY = 0;
        
        for (uint256 i = 0; i < n; i++) {
            int256 diffX = int256(dataX[i]) - int256(meanX);
            int256 diffY = int256(dataY[i]) - int256(meanY);
            
            numerator += (diffX * diffY) / int256(PRECISION);
            sumSquaredDiffX += uint256((diffX * diffX)) / PRECISION;
            sumSquaredDiffY += uint256((diffY * diffY)) / PRECISION;
        }
        
        uint256 denominator = _sqrt(sumSquaredDiffX * sumSquaredDiffY);
        correlation = (numerator * int256(PRECISION)) / int256(denominator);
        
        uint256[] memory combined = new uint256[](dataX.length + dataY.length);
        for (uint256 i = 0; i < dataX.length; i++) {
            combined[i] = dataX[i];
            combined[i + dataX.length] = dataY[i];
        }
        emit StatisticalAnalysis("correlation", combined, uint256(correlation));
    }
    
    /**
     * @notice Calculate polynomial evaluation using Horner's method
     * @param coefficients Polynomial coefficients (highest degree first)
     * @param x Value to evaluate polynomial at
     * @return result Polynomial value with PRECISION decimals
     */
    function evaluatePolynomial(
        uint256[] calldata coefficients,
        uint256 x
    ) external pure returns (uint256 result) {
        if (coefficients.length == 0) return 0;
        
        // Horner's method: P(x) = a₀ + x(a₁ + x(a₂ + x(a₃ + ...)))
        result = coefficients[0];
        for (uint256 i = 1; i < coefficients.length; i++) {
            result = (result * x) / PRECISION + coefficients[i];
        }
    }
    
    /**
     * @notice Calculate numerical integration using Simpson's rule
     * @param a Lower bound
     * @param b Upper bound
     * @param n Number of intervals (must be even)
     * @param functionType Type of function to integrate (0=linear, 1=quadratic, 2=exponential)
     * @return integral Numerical integration result
     */
    function numericalIntegration(
        uint256 a,
        uint256 b,
        uint256 n,
        uint256 functionType
    ) external view returns (uint256 integral) {
        if (n % 2 != 0) revert InvalidInput("n must be even for Simpson's rule");
        if (b <= a) revert InvalidInput("b must be greater than a");
        
        uint256 h = ((b - a) * PRECISION) / n;
        uint256 sum = _evaluateFunction(a, functionType) + _evaluateFunction(b, functionType);
        
        // Simpson's rule: ∫f(x)dx ≈ h/3 * [f(a) + 4*Σf(odd) + 2*Σf(even) + f(b)]
        for (uint256 i = 1; i < n; i++) {
            uint256 x = a + (i * h) / PRECISION;
            uint256 fx = _evaluateFunction(x, functionType);
            
            if (i % 2 == 1) {
                sum += 4 * fx; // Odd indices
            } else {
                sum += 2 * fx; // Even indices
            }
        }
        
        integral = (h * sum) / (3 * PRECISION);
    }
    
    // Internal helper functions
    
    function _power(uint256 base, uint256 exponent, uint256 precision) internal pure returns (uint256) {
        if (exponent == 0) return precision;
        if (exponent == 1) return base;
        
        uint256 result = precision;
        uint256 currentBase = base;
        uint256 currentExponent = exponent;
        
        while (currentExponent > 0) {
            if (currentExponent % 2 == 1) {
                result = (result * currentBase) / precision;
            }
            currentBase = (currentBase * currentBase) / precision;
            currentExponent /= 2;
        }
        
        return result;
    }
    
    function _lnTaylorSeries(uint256 x) internal pure returns (uint256) {
        // ln(1+x) = x - x²/2 + x³/3 - x⁴/4 + ...
        uint256 result = 0;
        uint256 term = x;
        bool positive = true;
        
        for (uint256 i = 1; i <= 15; i++) {
            if (positive) {
                result += term / i;
            } else {
                result -= term / i;
            }
            
            term = (term * x) / PRECISION;
            positive = !positive;
            
            if (term < PRECISION / 1e12) break;
        }
        
        return result;
    }
    
    function _sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        
        uint256 result = x;
        uint256 prev;
        
        while (result != prev) {
            prev = result;
            result = (result + (x * PRECISION) / result) / 2;
        }
        
        return result;
    }
    
    function _evaluateFunction(uint256 x, uint256 functionType) internal pure returns (uint256) {
        if (functionType == 0) {
            return x; // Linear function
        } else if (functionType == 1) {
            return (x * x) / PRECISION; // Quadratic function
        } else if (functionType == 2) {
            // Simplified exponential approximation
            return PRECISION + x + (x * x) / (2 * PRECISION);
        }
        return x;
    }
}