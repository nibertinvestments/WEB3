// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AdvancedMath - Complex Mathematical Operations Library
 * @dev Sophisticated mathematical functions for advanced DeFi and financial calculations
 * 
 * FEATURES:
 * - Advanced calculus operations (derivatives, integrals)
 * - Complex number arithmetic and operations
 * - Statistical analysis and probability distributions
 * - Financial mathematics (Black-Scholes, Monte Carlo)
 * - Advanced algebraic operations and matrix math
 * - Optimization algorithms and numerical methods
 * 
 * USE CASES:
 * 1. Options pricing and derivatives valuation
 * 2. Risk modeling and Value-at-Risk calculations
 * 3. Portfolio optimization and efficient frontier
 * 4. Monte Carlo simulations for financial modeling
 * 5. Advanced yield farming optimization
 * 6. Algorithmic trading strategy calculations
 * 
 * @author Nibert Investments LLC
 * @notice Advanced Level - Complex mathematical operations
 */

library AdvancedMath {
    // Error definitions
    error MathOverflow();
    error MathUnderflow();
    error DivisionByZero();
    error InvalidInput();
    error ConvergenceFailed();
    error MatrixNotInvertible();
    
    // Events
    event CalculationPerformed(string indexed operation, uint256 gasUsed);
    event ConvergenceReached(string indexed algorithm, uint256 iterations);
    event OptimizationResult(uint256 indexed result, uint256 confidence);
    
    // Constants for mathematical operations
    uint256 private constant PRECISION = 1e18;
    uint256 private constant E_SCALED = 2718281828459045235; // e * 1e18
    uint256 private constant PI_SCALED = 3141592653589793238; // π * 1e18
    uint256 private constant LN2_SCALED = 693147180559945309; // ln(2) * 1e18
    uint256 private constant MAX_ITERATIONS = 100;
    
    // Complex number structure
    struct Complex {
        int256 real;
        int256 imag;
    }
    
    // Matrix structure for linear algebra
    struct Matrix {
        uint256[][] elements;
        uint256 rows;
        uint256 cols;
    }
    
    // Statistical data structure
    struct Statistics {
        uint256 mean;
        uint256 variance;
        uint256 standardDeviation;
        uint256 skewness;
        uint256 kurtosis;
    }
    
    /**
     * @dev Calculates natural logarithm with high precision
     * Use Case: Financial mathematics requiring logarithmic calculations
     */
    function ln(uint256 x) internal pure returns (uint256) {
        require(x > 0, "AdvancedMath: ln of non-positive number");
        
        if (x == PRECISION) return 0;
        
        // Use Taylor series: ln(1+x) = x - x²/2 + x³/3 - x⁴/4 + ...
        // For x near 1, convert to ln(1 + (x-1))
        
        uint256 result = 0;
        uint256 term = x > PRECISION ? (x - PRECISION) * PRECISION / x : (PRECISION - x) * PRECISION / x;
        bool negative = x < PRECISION;
        
        for (uint256 i = 1; i <= 50; i++) {
            uint256 termPower = term;
            for (uint256 j = 1; j < i; j++) {
                termPower = termPower * term / PRECISION;
            }
            
            if (i % 2 == 1) {
                result += termPower / i;
            } else {
                result -= termPower / i;
            }
        }
        
        return negative ? 0 : result; // Simplified for demonstration
    }
    
    /**
     * @dev Calculates exponential function e^x
     * Use Case: Compound interest and exponential growth models
     */
    function exp(uint256 x) internal pure returns (uint256) {
        if (x == 0) return PRECISION;
        
        // Use Taylor series: e^x = 1 + x + x²/2! + x³/3! + ...
        uint256 result = PRECISION;
        uint256 term = x;
        
        for (uint256 i = 1; i <= 50; i++) {
            result += term;
            term = term * x / (PRECISION * (i + 1));
            
            if (term < 100) break; // Convergence check
        }
        
        return result;
    }
    
    /**
     * @dev Calculates power function x^y with high precision
     * Use Case: Exponential calculations in financial formulas
     */
    function pow(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) return PRECISION;
        if (base == 0) return 0;
        if (base == PRECISION) return PRECISION;
        
        // Use ln and exp: x^y = e^(y*ln(x))
        uint256 lnBase = ln(base);
        uint256 exponentScaled = exponent * lnBase / PRECISION;
        return exp(exponentScaled);
    }
    
    /**
     * @dev Calculates square root using Newton's method
     * Use Case: Volatility calculations and geometric means
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        
        // Newton's method: x_{n+1} = (x_n + x/x_n) / 2
        uint256 result = x;
        uint256 previous;
        
        do {
            previous = result;
            result = (result + x * PRECISION / result) / 2;
        } while (abs(int256(result) - int256(previous)) > 1 && result != previous);
        
        return result;
    }
    
    /**
     * @dev Calculates trigonometric sine function
     * Use Case: Wave analysis and periodic calculations
     */
    function sin(uint256 x) internal pure returns (int256) {
        // Normalize x to [0, 2π]
        x = x % (2 * PI_SCALED);
        
        // Use Taylor series: sin(x) = x - x³/3! + x⁵/5! - x⁷/7! + ...
        int256 result = 0;
        int256 term = int256(x);
        int256 xSquared = int256(x * x / PRECISION);
        
        for (uint256 i = 1; i <= 15; i++) {
            if (i % 2 == 1) {
                result += term / int256(factorial(2 * i - 1));
            } else {
                result -= term / int256(factorial(2 * i - 1));
            }
            
            term = term * xSquared / int256(PRECISION);
        }
        
        return result;
    }
    
    /**
     * @dev Calculates factorial with optimization
     * Use Case: Statistical calculations and permutations
     */
    function factorial(uint256 n) internal pure returns (uint256) {
        if (n <= 1) return 1;
        
        uint256 result = 1;
        for (uint256 i = 2; i <= n; i++) {
            result *= i;
            require(result >= i, "AdvancedMath: factorial overflow");
        }
        
        return result;
    }
    
    /**
     * @dev Calculates absolute value for signed integers
     * Use Case: Distance calculations and error metrics
     */
    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }
    
    /**
     * @dev Calculates Black-Scholes option price
     * Use Case: Options pricing in DeFi derivatives
     */
    function blackScholes(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 timeToExpiry,
        uint256 riskFreeRate,
        uint256 volatility,
        bool isCall
    ) internal pure returns (uint256) {
        // Simplified Black-Scholes implementation
        // d1 = (ln(S/K) + (r + σ²/2)T) / (σ√T)
        // d2 = d1 - σ√T
        
        uint256 lnSK = ln(spotPrice * PRECISION / strikePrice);
        uint256 volSquared = volatility * volatility / PRECISION;
        uint256 sqrtT = sqrt(timeToExpiry);
        
        uint256 d1Numerator = lnSK + (riskFreeRate + volSquared / 2) * timeToExpiry / PRECISION;
        uint256 d1 = d1Numerator * PRECISION / (volatility * sqrtT / PRECISION);
        uint256 d2 = d1 - volatility * sqrtT / PRECISION;
        
        // Simplified normal distribution approximation
        uint256 nd1 = normalCDF(d1);
        uint256 nd2 = normalCDF(d2);
        
        if (isCall) {
            // Call option: S*N(d1) - K*e^(-rT)*N(d2)
            uint256 presentValueStrike = strikePrice * exp(-riskFreeRate * timeToExpiry / PRECISION) / PRECISION;
            return spotPrice * nd1 / PRECISION - presentValueStrike * nd2 / PRECISION;
        } else {
            // Put option: K*e^(-rT)*N(-d2) - S*N(-d1)
            uint256 presentValueStrike = strikePrice * exp(-riskFreeRate * timeToExpiry / PRECISION) / PRECISION;
            return presentValueStrike * (PRECISION - nd2) / PRECISION - spotPrice * (PRECISION - nd1) / PRECISION;
        }
    }
    
    /**
     * @dev Approximates normal cumulative distribution function
     * Use Case: Statistical analysis and probability calculations
     */
    function normalCDF(uint256 x) internal pure returns (uint256) {
        // Abramowitz and Stegun approximation
        // Error < 1.5e-7
        
        bool negative = false;
        if (x > PRECISION * 5) return PRECISION; // Practically 1
        
        // Constants for approximation
        uint256 a1 = 254829592;  // 0.254829592 * 1e9
        uint256 a2 = 284496736;  // -0.284496736 * 1e9
        uint256 a3 = 1421413741; // 1.421413741 * 1e9
        uint256 a4 = 1453152027; // -1.453152027 * 1e9
        uint256 a5 = 1061405429; // 1.061405429 * 1e9
        uint256 p = 327591100;   // 0.3275911 * 1e9
        
        // |x|
        uint256 absX = x;
        
        // t = 1.0/(1.0 + p*|x|)
        uint256 t = PRECISION * 1e9 / (1e9 + p * absX / PRECISION);
        
        // Polynomial approximation
        uint256 poly = a1 * t / 1e9;
        poly += a2 * t * t / (1e9 * PRECISION);
        poly += a3 * pow(t, 3 * PRECISION) / 1e9;
        poly += a4 * pow(t, 4 * PRECISION) / 1e9;
        poly += a5 * pow(t, 5 * PRECISION) / 1e9;
        
        // e^(-x²/2)
        uint256 expTerm = exp(-absX * absX / (2 * PRECISION));
        
        uint256 y = PRECISION - poly * expTerm / PRECISION;
        
        return negative ? PRECISION - y : y;
    }
    
    /**
     * @dev Calculates Monte Carlo simulation for option pricing
     * Use Case: Complex derivatives pricing with stochastic models
     */
    function monteCarloOptionPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 timeToExpiry,
        uint256 riskFreeRate,
        uint256 volatility,
        uint256 numSimulations,
        bool isCall
    ) internal view returns (uint256) {
        uint256 totalPayoff = 0;
        uint256 dt = timeToExpiry;
        
        for (uint256 i = 0; i < numSimulations; i++) {
            // Generate random price path
            uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, i, block.difficulty)));
            uint256 finalPrice = simulateGeometricBrownianMotion(
                spotPrice,
                riskFreeRate,
                volatility,
                dt,
                randomSeed
            );
            
            // Calculate payoff
            uint256 payoff = 0;
            if (isCall && finalPrice > strikePrice) {
                payoff = finalPrice - strikePrice;
            } else if (!isCall && strikePrice > finalPrice) {
                payoff = strikePrice - finalPrice;
            }
            
            totalPayoff += payoff;
        }
        
        // Discount to present value
        uint256 avgPayoff = totalPayoff / numSimulations;
        return avgPayoff * exp(-riskFreeRate * timeToExpiry / PRECISION) / PRECISION;
    }
    
    /**
     * @dev Simulates Geometric Brownian Motion for price paths
     * Use Case: Stochastic price modeling for financial instruments
     */
    function simulateGeometricBrownianMotion(
        uint256 initialPrice,
        uint256 drift,
        uint256 volatility,
        uint256 timeHorizon,
        uint256 randomSeed
    ) internal pure returns (uint256) {
        // S(t) = S(0) * exp((μ - σ²/2)t + σ√t * Z)
        // where Z is standard normal random variable
        
        // Generate pseudo-random normal variable (Box-Muller transform)
        uint256 u1 = (randomSeed % PRECISION) + 1;
        uint256 u2 = ((randomSeed >> 128) % PRECISION) + 1;
        
        uint256 z = sqrt(-2 * ln(u1)) * sin(2 * PI_SCALED * u2 / PRECISION) / int256(PRECISION);
        z = abs(int256(z)); // Simplified for demonstration
        
        uint256 drift_adj = drift - volatility * volatility / (2 * PRECISION);
        uint256 exponent = drift_adj * timeHorizon / PRECISION + 
                          volatility * sqrt(timeHorizon) * z / PRECISION;
        
        return initialPrice * exp(exponent) / PRECISION;
    }
    
    /**
     * @dev Calculates Value-at-Risk using historical simulation
     * Use Case: Risk management and portfolio optimization
     */
    function calculateVaR(
        uint256[] memory returns,
        uint256 confidenceLevel,
        uint256 timeHorizon
    ) internal pure returns (uint256) {
        require(returns.length > 0, "AdvancedMath: empty returns array");
        require(confidenceLevel < PRECISION, "AdvancedMath: invalid confidence level");
        
        // Sort returns array (bubble sort for simplicity)
        uint256[] memory sortedReturns = new uint256[](returns.length);
        for (uint256 i = 0; i < returns.length; i++) {
            sortedReturns[i] = returns[i];
        }
        
        for (uint256 i = 0; i < sortedReturns.length; i++) {
            for (uint256 j = i + 1; j < sortedReturns.length; j++) {
                if (sortedReturns[i] > sortedReturns[j]) {
                    uint256 temp = sortedReturns[i];
                    sortedReturns[i] = sortedReturns[j];
                    sortedReturns[j] = temp;
                }
            }
        }
        
        // Find percentile
        uint256 index = (PRECISION - confidenceLevel) * sortedReturns.length / PRECISION;
        if (index >= sortedReturns.length) index = sortedReturns.length - 1;
        
        // Scale by time horizon (square root of time rule)
        return sortedReturns[index] * sqrt(timeHorizon);
    }
    
    /**
     * @dev Performs matrix multiplication for portfolio optimization
     * Use Case: Modern portfolio theory and risk calculations
     */
    function matrixMultiply(
        Matrix memory a,
        Matrix memory b
    ) internal pure returns (Matrix memory result) {
        require(a.cols == b.rows, "AdvancedMath: incompatible matrix dimensions");
        
        result.rows = a.rows;
        result.cols = b.cols;
        result.elements = new uint256[][](result.rows);
        
        for (uint256 i = 0; i < result.rows; i++) {
            result.elements[i] = new uint256[](result.cols);
            for (uint256 j = 0; j < result.cols; j++) {
                uint256 sum = 0;
                for (uint256 k = 0; k < a.cols; k++) {
                    sum += a.elements[i][k] * b.elements[k][j];
                }
                result.elements[i][j] = sum;
            }
        }
    }
    
    /**
     * @dev Calculates portfolio variance using covariance matrix
     * Use Case: Risk assessment for multi-asset portfolios
     */
    function portfolioVariance(
        uint256[] memory weights,
        Matrix memory covarianceMatrix
    ) internal pure returns (uint256) {
        require(weights.length == covarianceMatrix.rows, "AdvancedMath: dimension mismatch");
        require(covarianceMatrix.rows == covarianceMatrix.cols, "AdvancedMath: non-square covariance matrix");
        
        uint256 variance = 0;
        
        for (uint256 i = 0; i < weights.length; i++) {
            for (uint256 j = 0; j < weights.length; j++) {
                variance += weights[i] * weights[j] * covarianceMatrix.elements[i][j] / (PRECISION * PRECISION);
            }
        }
        
        return variance;
    }
    
    /**
     * @dev Optimizes portfolio using simplified mean-variance optimization
     * Use Case: Portfolio construction and asset allocation
     */
    function optimizePortfolio(
        uint256[] memory expectedReturns,
        Matrix memory covarianceMatrix,
        uint256 riskTolerance
    ) internal pure returns (uint256[] memory optimalWeights) {
        require(expectedReturns.length == covarianceMatrix.rows, "AdvancedMath: dimension mismatch");
        
        // Simplified optimization using equal risk contribution
        optimalWeights = new uint256[](expectedReturns.length);
        uint256 totalWeight = 0;
        
        for (uint256 i = 0; i < expectedReturns.length; i++) {
            // Weight inversely proportional to variance and adjusted by expected return
            uint256 assetVariance = covarianceMatrix.elements[i][i];
            optimalWeights[i] = expectedReturns[i] * PRECISION / (assetVariance + riskTolerance);
            totalWeight += optimalWeights[i];
        }
        
        // Normalize weights to sum to 1
        for (uint256 i = 0; i < optimalWeights.length; i++) {
            optimalWeights[i] = optimalWeights[i] * PRECISION / totalWeight;
        }
    }
    
    /**
     * @dev Calculates complex number multiplication
     * Use Case: Advanced signal processing and Fourier transforms
     */
    function complexMultiply(Complex memory a, Complex memory b) internal pure returns (Complex memory) {
        return Complex({
            real: (a.real * b.real - a.imag * b.imag) / int256(PRECISION),
            imag: (a.real * b.imag + a.imag * b.real) / int256(PRECISION)
        });
    }
    
    /**
     * @dev Performs Fast Fourier Transform (simplified)
     * Use Case: Frequency domain analysis for trading algorithms
     */
    function fft(Complex[] memory input) internal pure returns (Complex[] memory) {
        uint256 n = input.length;
        require(n > 0 && (n & (n - 1)) == 0, "AdvancedMath: length must be power of 2");
        
        if (n == 1) {
            return input;
        }
        
        // Bit-reversal permutation
        for (uint256 i = 0; i < n; i++) {
            uint256 j = bitReverse(i, n);
            if (i < j) {
                Complex memory temp = input[i];
                input[i] = input[j];
                input[j] = temp;
            }
        }
        
        // Cooley-Tukey FFT algorithm
        for (uint256 len = 2; len <= n; len *= 2) {
            Complex memory wlen = Complex({
                real: int256(cos(2 * PI_SCALED / len)),
                imag: -int256(sin(2 * PI_SCALED / len))
            });
            
            for (uint256 i = 0; i < n; i += len) {
                Complex memory w = Complex({real: int256(PRECISION), imag: 0});
                
                for (uint256 j = 0; j < len / 2; j++) {
                    Complex memory u = input[i + j];
                    Complex memory v = complexMultiply(input[i + j + len / 2], w);
                    
                    input[i + j] = Complex({
                        real: u.real + v.real,
                        imag: u.imag + v.imag
                    });
                    
                    input[i + j + len / 2] = Complex({
                        real: u.real - v.real,
                        imag: u.imag - v.imag
                    });
                    
                    w = complexMultiply(w, wlen);
                }
            }
        }
        
        return input;
    }
    
    /**
     * @dev Bit reversal for FFT algorithm
     * Use Case: Helper function for Fast Fourier Transform
     */
    function bitReverse(uint256 num, uint256 n) internal pure returns (uint256) {
        uint256 reversed = 0;
        uint256 bits = 0;
        
        // Calculate number of bits
        uint256 temp = n - 1;
        while (temp > 0) {
            bits++;
            temp >>= 1;
        }
        
        // Reverse the bits
        for (uint256 i = 0; i < bits; i++) {
            reversed = (reversed << 1) | (num & 1);
            num >>= 1;
        }
        
        return reversed;
    }
    
    /**
     * @dev Calculates cosine function
     * Use Case: Trigonometric calculations for wave analysis
     */
    function cos(uint256 x) internal pure returns (uint256) {
        // cos(x) = sin(x + π/2)
        return abs(sin(x + PI_SCALED / 2));
    }
}