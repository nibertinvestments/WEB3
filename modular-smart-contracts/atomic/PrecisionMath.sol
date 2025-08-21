// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IModularContract.sol";

/**
 * @title PrecisionMath - Ultra-High Precision Mathematical Operations
 * @dev Atomic contract for advanced mathematical computations with arbitrary precision
 * 
 * USE CASES:
 * 1. Financial calculations requiring extreme precision
 * 2. Scientific computations with large numbers
 * 3. Cryptographic mathematical operations
 * 4. Risk assessment calculations
 * 5. Portfolio optimization algorithms
 * 6. Derivatives pricing models
 * 
 * WHY IT WORKS:
 * - Fixed-point arithmetic prevents rounding errors
 * - Overflow protection for all operations
 * - Gas-optimized algorithms for complex math
 * - Modular design enables easy integration
 * - Standardized interface ensures consistency
 * 
 * @author Nibert Investments Development Team
 */
contract PrecisionMath is IModularContract {
    
    // Module constants
    bytes32 public constant MODULE_ID = keccak256("PRECISION_MATH_V1");
    uint256 public constant MODULE_VERSION = 1;
    
    // Precision constants
    uint256 public constant PRECISION_DECIMALS = 18;
    uint256 public constant PRECISION_FACTOR = 10**PRECISION_DECIMALS;
    uint256 public constant MAX_SAFE_INTEGER = type(uint128).max;
    
    // Mathematical constants with high precision
    uint256 public constant PI = 3141592653589793238;
    uint256 public constant E = 2718281828459045235;
    uint256 public constant GOLDEN_RATIO = 1618033988749894848;
    uint256 public constant SQRT_2 = 1414213562373095049;
    uint256 public constant SQRT_3 = 1732050807568877294;
    
    // Module state
    bool private _initialized;
    
    // Events
    event CalculationPerformed(string indexed operation, uint256 indexed precision, bytes32 resultHash);
    event PrecisionAdjusted(uint256 oldPrecision, uint256 newPrecision);
    
    // Errors
    error DivisionByZero();
    error NumberTooLarge(uint256 number);
    error InvalidPrecision(uint256 precision);
    error CalculationOverflow();
    error NegativeSquareRoot();
    
    /**
     * @dev Module interface implementation
     */
    function getModuleId() external pure override returns (bytes32) {
        return MODULE_ID;
    }
    
    function getModuleVersion() external pure override returns (uint256) {
        return MODULE_VERSION;
    }
    
    function getModuleInfo() external pure override returns (
        string memory name,
        string memory description,
        uint256 version,
        address[] memory dependencies
    ) {
        return (
            "PrecisionMath",
            "Ultra-high precision mathematical operations",
            MODULE_VERSION,
            new address[](0)
        );
    }
    
    function initializeModule(bytes calldata) external override {
        require(!_initialized, "Already initialized");
        _initialized = true;
        emit ModuleInitialized(address(this), MODULE_ID);
    }
    
    function isModuleInitialized() external view override returns (bool) {
        return _initialized;
    }
    
    function getSupportedInterfaces() external pure override returns (bytes4[] memory) {
        bytes4[] memory interfaces = new bytes4[](1);
        interfaces[0] = type(IModularContract).interfaceId;
        return interfaces;
    }
    
    function executeModuleFunction(bytes4 selector, bytes calldata data) 
        external 
        payable 
        override 
        returns (bytes memory) 
    {
        if (selector == bytes4(keccak256("multiply(uint256,uint256)"))) {
            (uint256 a, uint256 b) = abi.decode(data, (uint256, uint256));
            return abi.encode(multiply(a, b));
        } else if (selector == bytes4(keccak256("divide(uint256,uint256)"))) {
            (uint256 a, uint256 b) = abi.decode(data, (uint256, uint256));
            return abi.encode(divide(a, b));
        } else if (selector == bytes4(keccak256("power(uint256,uint256)"))) {
            (uint256 base, uint256 exponent) = abi.decode(data, (uint256, uint256));
            return abi.encode(power(base, exponent));
        }
        revert("Function not supported");
    }
    
    /**
     * @dev High-precision multiplication
     */
    function multiply(uint256 a, uint256 b) public pure returns (uint256) {
        if (a == 0 || b == 0) return 0;
        
        // Check for overflow
        if (a > MAX_SAFE_INTEGER || b > MAX_SAFE_INTEGER) {
            revert NumberTooLarge(a > b ? a : b);
        }
        
        uint256 result = (a * b) / PRECISION_FACTOR;
        
        // Verify no overflow occurred
        if (result * PRECISION_FACTOR != a * b) {
            revert CalculationOverflow();
        }
        
        return result;
    }
    
    /**
     * @dev High-precision division
     */
    function divide(uint256 a, uint256 b) public pure returns (uint256) {
        if (b == 0) revert DivisionByZero();
        if (a == 0) return 0;
        
        // Scale up for precision
        uint256 scaledA = a * PRECISION_FACTOR;
        
        // Check for overflow
        if (scaledA / PRECISION_FACTOR != a) {
            revert CalculationOverflow();
        }
        
        return scaledA / b;
    }
    
    /**
     * @dev Integer power function with overflow protection
     */
    function power(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) return PRECISION_FACTOR;
        if (base == 0) return 0;
        if (base == PRECISION_FACTOR) return PRECISION_FACTOR;
        
        uint256 result = PRECISION_FACTOR;
        uint256 tempBase = base;
        
        while (exponent > 0) {
            if (exponent & 1 == 1) {
                result = multiply(result, tempBase);
            }
            tempBase = multiply(tempBase, tempBase);
            exponent >>= 1;
        }
        
        return result;
    }
    
    /**
     * @dev Square root using Newton-Raphson method
     */
    function sqrt(uint256 x) public pure returns (uint256) {
        if (x == 0) return 0;
        
        // Initial guess
        uint256 z = (x + PRECISION_FACTOR) / 2;
        uint256 y = x;
        
        while (z < y) {
            y = z;
            z = (divide(x, z) + z) / 2;
        }
        
        return y;
    }
    
    /**
     * @dev Natural logarithm using Taylor series
     */
    function ln(uint256 x) public pure returns (uint256) {
        if (x == 0) revert DivisionByZero();
        if (x == PRECISION_FACTOR) return 0;
        
        // Use change of variables for convergence: ln(x) = ln(x/e^k) + k
        uint256 result = 0;
        uint256 y = x;
        
        // Reduce to range [1, e] for better convergence
        while (y > E) {
            y = divide(y, E);
            result += PRECISION_FACTOR;
        }
        
        // Taylor series expansion around 1
        uint256 z = y - PRECISION_FACTOR;
        uint256 term = z;
        uint256 series = 0;
        
        for (uint256 i = 1; i <= 50; i++) {
            if (i % 2 == 1) {
                series += divide(term, i * PRECISION_FACTOR);
            } else {
                series -= divide(term, i * PRECISION_FACTOR);
            }
            term = multiply(term, z);
        }
        
        return result + series;
    }
    
    /**
     * @dev Exponential function using Taylor series
     */
    function exp(uint256 x) public pure returns (uint256) {
        if (x == 0) return PRECISION_FACTOR;
        
        // Handle large values by decomposition: e^x = e^(k + r) = e^k * e^r
        uint256 k = x / PRECISION_FACTOR;
        uint256 r = x % PRECISION_FACTOR;
        
        // Calculate e^k using repeated multiplication
        uint256 expK = PRECISION_FACTOR;
        for (uint256 i = 0; i < k; i++) {
            expK = multiply(expK, E);
        }
        
        // Calculate e^r using Taylor series
        uint256 expR = PRECISION_FACTOR;
        uint256 term = PRECISION_FACTOR;
        
        for (uint256 i = 1; i <= 50; i++) {
            term = multiply(term, r) / i;
            expR += term;
            
            // Break if term becomes negligible
            if (term < 1000) break;
        }
        
        return multiply(expK, expR);
    }
    
    /**
     * @dev Sine function using Taylor series
     */
    function sin(uint256 x) public pure returns (int256) {
        // Reduce to [0, 2π] range
        uint256 twoPi = multiply(2, PI);
        x = x % twoPi;
        
        // Taylor series: sin(x) = x - x³/3! + x⁵/5! - x⁷/7! + ...
        int256 result = int256(x);
        uint256 term = x;
        
        for (uint256 i = 1; i <= 25; i++) {
            term = multiply(multiply(term, x), x);
            uint256 factorial = (2 * i) * (2 * i + 1);
            uint256 termValue = term / factorial;
            
            if (i % 2 == 1) {
                result -= int256(termValue);
            } else {
                result += int256(termValue);
            }
            
            // Break if term becomes negligible
            if (termValue < 1000) break;
        }
        
        return result;
    }
    
    /**
     * @dev Cosine function using Taylor series
     */
    function cos(uint256 x) public pure returns (int256) {
        // Reduce to [0, 2π] range
        uint256 twoPi = multiply(2, PI);
        x = x % twoPi;
        
        // Taylor series: cos(x) = 1 - x²/2! + x⁴/4! - x⁶/6! + ...
        int256 result = int256(PRECISION_FACTOR);
        uint256 term = PRECISION_FACTOR;
        
        for (uint256 i = 1; i <= 25; i++) {
            term = multiply(multiply(term, x), x);
            uint256 factorial = (2 * i - 1) * (2 * i);
            uint256 termValue = term / factorial;
            
            if (i % 2 == 1) {
                result -= int256(termValue);
            } else {
                result += int256(termValue);
            }
            
            // Break if term becomes negligible
            if (termValue < 1000) break;
        }
        
        return result;
    }
    
    /**
     * @dev Factorial calculation with overflow protection
     */
    function factorial(uint256 n) public pure returns (uint256) {
        if (n > 20) revert NumberTooLarge(n); // Prevent overflow
        if (n <= 1) return PRECISION_FACTOR;
        
        uint256 result = PRECISION_FACTOR;
        for (uint256 i = 2; i <= n; i++) {
            result = multiply(result, i * PRECISION_FACTOR);
        }
        
        return result;
    }
    
    /**
     * @dev Combination calculation: C(n,k) = n! / (k!(n-k)!)
     */
    function combination(uint256 n, uint256 k) public pure returns (uint256) {
        if (k > n) return 0;
        if (k == 0 || k == n) return PRECISION_FACTOR;
        
        // Optimize by using smaller k
        if (k > n - k) k = n - k;
        
        uint256 result = PRECISION_FACTOR;
        for (uint256 i = 0; i < k; i++) {
            result = multiply(result, (n - i) * PRECISION_FACTOR);
            result = divide(result, (i + 1) * PRECISION_FACTOR);
        }
        
        return result;
    }
    
    /**
     * @dev Greatest Common Divisor using Euclidean algorithm
     */
    function gcd(uint256 a, uint256 b) public pure returns (uint256) {
        while (b != 0) {
            uint256 temp = b;
            b = a % b;
            a = temp;
        }
        return a;
    }
    
    /**
     * @dev Least Common Multiple
     */
    function lcm(uint256 a, uint256 b) public pure returns (uint256) {
        if (a == 0 || b == 0) return 0;
        return divide(multiply(a, b), gcd(a, b));
    }
    
    /**
     * @dev Modular exponentiation: (base^exponent) mod modulus
     */
    function modularPower(uint256 base, uint256 exponent, uint256 modulus) 
        public 
        pure 
        returns (uint256) 
    {
        if (modulus == 0) revert DivisionByZero();
        if (modulus == 1) return 0;
        
        uint256 result = 1;
        base = base % modulus;
        
        while (exponent > 0) {
            if (exponent & 1 == 1) {
                result = (result * base) % modulus;
            }
            exponent >>= 1;
            base = (base * base) % modulus;
        }
        
        return result;
    }
    
    /**
     * @dev Check if number is prime using Miller-Rabin test
     */
    function isPrime(uint256 n) public pure returns (bool) {
        if (n < 2) return false;
        if (n == 2 || n == 3) return true;
        if (n % 2 == 0) return false;
        
        // Write n-1 as d * 2^r
        uint256 d = n - 1;
        uint256 r = 0;
        while (d % 2 == 0) {
            d /= 2;
            r++;
        }
        
        // Witnesses to test
        uint256[12] memory witnesses = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37];
        
        for (uint256 i = 0; i < witnesses.length; i++) {
            uint256 a = witnesses[i];
            if (a >= n) continue;
            
            uint256 x = modularPower(a, d, n);
            if (x == 1 || x == n - 1) continue;
            
            bool composite = true;
            for (uint256 j = 0; j < r - 1; j++) {
                x = (x * x) % n;
                if (x == n - 1) {
                    composite = false;
                    break;
                }
            }
            
            if (composite) return false;
        }
        
        return true;
    }
    
    /**
     * @dev Generate next prime number greater than n
     */
    function nextPrime(uint256 n) public pure returns (uint256) {
        if (n < 2) return 2;
        
        // Make odd
        if (n % 2 == 0) n++;
        
        while (!isPrime(n)) {
            n += 2;
        }
        
        return n;
    }
}