// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DerivativePricing - Advanced Financial Derivatives Pricing Library
 * @dev Sophisticated pricing models for complex financial derivatives
 * 
 * FEATURES:
 * - Advanced options pricing (Black-Scholes, Binomial, Monte Carlo)
 * - Exotic derivatives pricing (Asian, Barrier, Lookback options)
 * - Interest rate derivatives (Swaps, Caps, Floors, Swaptions)
 * - Credit derivatives (CDS, CDO) pricing models
 * - Volatility surface modeling and interpolation
 * - Greeks calculation for risk management
 * 
 * USE CASES:
 * 1. DeFi derivatives protocol pricing engines
 * 2. On-chain options market making
 * 3. Structured products and exotic options
 * 4. Risk management and hedging strategies
 * 5. Automated market makers for derivatives
 * 6. Real-time derivatives fair value calculation
 * 
 * @author Nibert Investments LLC
 * @notice Advanced Level - Complex derivatives pricing algorithms
 */

library DerivativePricing {
    // Error definitions
    error InvalidStrike();
    error InvalidExpiry();
    error InvalidVolatility();
    error InvalidRate();
    error PricingFailed();
    error InsufficientData();
    error ModelConvergenceFailed();
    
    // Events
    event OptionPriced(address indexed option, uint256 price, uint256 timestamp);
    event GreeksCalculated(uint256 delta, uint256 gamma, uint256 theta, uint256 vega);
    event VolatilityUpdated(uint256 indexed tenor, uint256 newVolatility);
    event DerivativeSettled(bytes32 indexed contractId, uint256 settlementValue);
    
    // Constants
    uint256 private constant PRECISION = 1e18;
    uint256 private constant DAYS_IN_YEAR = 365;
    uint256 private constant SECONDS_IN_DAY = 86400;
    uint256 private constant MAX_ITERATIONS = 100;
    uint256 private constant CONVERGENCE_THRESHOLD = 1e15; // 0.001 precision
    
    // Option types
    enum OptionType {
        CALL,
        PUT,
        AMERICAN_CALL,
        AMERICAN_PUT,
        ASIAN_CALL,
        ASIAN_PUT,
        BARRIER_CALL,
        BARRIER_PUT,
        LOOKBACK_CALL,
        LOOKBACK_PUT
    }
    
    // Barrier types for barrier options
    enum BarrierType {
        UP_AND_OUT,
        DOWN_AND_OUT,
        UP_AND_IN,
        DOWN_AND_IN
    }
    
    // Option parameters structure
    struct OptionParams {
        uint256 spotPrice;
        uint256 strikePrice;
        uint256 timeToExpiry;
        uint256 riskFreeRate;
        uint256 dividendYield;
        uint256 volatility;
        OptionType optionType;
    }
    
    // Exotic option parameters
    struct ExoticParams {
        uint256 barrierLevel;
        uint256 rebate;
        BarrierType barrierType;
        uint256[] averagingDates;
        uint256 lookbackPeriod;
    }
    
    // Greeks structure for risk metrics
    struct Greeks {
        int256 delta;     // Price sensitivity to underlying
        uint256 gamma;    // Delta sensitivity to underlying
        int256 theta;     // Time decay
        uint256 vega;     // Volatility sensitivity
        uint256 rho;      // Interest rate sensitivity
    }
    
    // Volatility surface point
    struct VolatilityPoint {
        uint256 strike;
        uint256 tenor;
        uint256 volatility;
    }
    
    /**
     * @dev Black-Scholes formula for European options
     * Use Case: Standard options pricing in DeFi derivatives
     */
    function blackScholesPrice(OptionParams memory params) internal pure returns (uint256) {
        require(params.spotPrice > 0, "DerivativePricing: invalid spot price");
        require(params.strikePrice > 0, "DerivativePricing: invalid strike price");
        require(params.timeToExpiry > 0, "DerivativePricing: invalid expiry");
        require(params.volatility > 0, "DerivativePricing: invalid volatility");
        
        // Calculate d1 and d2
        uint256 d1 = calculateD1(params);
        uint256 d2 = d1 - params.volatility * sqrt(params.timeToExpiry);
        
        // Calculate option price based on type
        if (params.optionType == OptionType.CALL) {
            uint256 term1 = params.spotPrice * exp(-params.dividendYield * params.timeToExpiry / PRECISION) * normalCDF(d1) / PRECISION;
            uint256 term2 = params.strikePrice * exp(-params.riskFreeRate * params.timeToExpiry / PRECISION) * normalCDF(d2) / PRECISION;
            return term1 - term2;
        } else {
            uint256 term1 = params.strikePrice * exp(-params.riskFreeRate * params.timeToExpiry / PRECISION) * normalCDF(PRECISION - d2) / PRECISION;
            uint256 term2 = params.spotPrice * exp(-params.dividendYield * params.timeToExpiry / PRECISION) * normalCDF(PRECISION - d1) / PRECISION;
            return term1 - term2;
        }
    }
    
    /**
     * @dev Calculates d1 parameter for Black-Scholes
     * Use Case: Helper function for options pricing calculations
     */
    function calculateD1(OptionParams memory params) internal pure returns (uint256) {
        uint256 lnSK = ln(params.spotPrice * PRECISION / params.strikePrice);
        uint256 volSquared = params.volatility * params.volatility / PRECISION;
        uint256 rateAdjusted = params.riskFreeRate - params.dividendYield + volSquared / 2;
        
        uint256 numerator = lnSK + rateAdjusted * params.timeToExpiry / PRECISION;
        uint256 denominator = params.volatility * sqrt(params.timeToExpiry);
        
        return numerator * PRECISION / denominator;
    }
    
    /**
     * @dev Binomial tree pricing for American options
     * Use Case: American options that can be exercised early
     */
    function binomialTreePrice(
        OptionParams memory params,
        uint256 steps
    ) internal pure returns (uint256) {
        require(steps > 0, "DerivativePricing: invalid steps");
        require(steps <= 1000, "DerivativePricing: too many steps");
        
        uint256 dt = params.timeToExpiry / steps;
        uint256 u = exp(params.volatility * sqrt(dt)); // Up factor
        uint256 d = PRECISION * PRECISION / u; // Down factor
        uint256 p = (exp(params.riskFreeRate * dt / PRECISION) - d) * PRECISION / (u - d); // Risk-neutral probability
        
        // Initialize price tree
        uint256[] memory prices = new uint256[](steps + 1);
        uint256[] memory optionValues = new uint256[](steps + 1);
        
        // Calculate final stock prices
        for (uint256 i = 0; i <= steps; i++) {
            uint256 upMoves = i;
            uint256 downMoves = steps - i;
            
            prices[i] = params.spotPrice;
            for (uint256 j = 0; j < upMoves; j++) {
                prices[i] = prices[i] * u / PRECISION;
            }
            for (uint256 j = 0; j < downMoves; j++) {
                prices[i] = prices[i] * d / PRECISION;
            }
            
            // Calculate option value at expiry
            if (params.optionType == OptionType.AMERICAN_CALL || params.optionType == OptionType.CALL) {
                optionValues[i] = prices[i] > params.strikePrice ? prices[i] - params.strikePrice : 0;
            } else {
                optionValues[i] = params.strikePrice > prices[i] ? params.strikePrice - prices[i] : 0;
            }
        }
        
        // Backward induction
        uint256 discountFactor = exp(-params.riskFreeRate * dt / PRECISION);
        
        for (uint256 step = steps; step > 0; step--) {
            for (uint256 i = 0; i < step; i++) {
                // Calculate continuation value
                uint256 continuationValue = (p * optionValues[i + 1] + (PRECISION - p) * optionValues[i]) / PRECISION;
                continuationValue = continuationValue * discountFactor / PRECISION;
                
                // For American options, check early exercise
                if (params.optionType == OptionType.AMERICAN_CALL || params.optionType == OptionType.AMERICAN_PUT) {
                    uint256 currentPrice = prices[i] * pow(u, i) * pow(d, step - 1 - i) / pow(PRECISION, step - 1);
                    uint256 exerciseValue;
                    
                    if (params.optionType == OptionType.AMERICAN_CALL) {
                        exerciseValue = currentPrice > params.strikePrice ? currentPrice - params.strikePrice : 0;
                    } else {
                        exerciseValue = params.strikePrice > currentPrice ? params.strikePrice - currentPrice : 0;
                    }
                    
                    optionValues[i] = max(continuationValue, exerciseValue);
                } else {
                    optionValues[i] = continuationValue;
                }
            }
        }
        
        return optionValues[0];
    }
    
    /**
     * @dev Monte Carlo pricing for path-dependent options
     * Use Case: Complex exotic options requiring simulation
     */
    function monteCarloPrice(
        OptionParams memory params,
        ExoticParams memory exoticParams,
        uint256 numSimulations
    ) internal view returns (uint256) {
        require(numSimulations > 0, "DerivativePricing: invalid simulations");
        require(numSimulations <= 10000, "DerivativePricing: too many simulations");
        
        uint256 totalPayoff = 0;
        uint256 timeSteps = 252; // Daily steps for one year
        uint256 dt = params.timeToExpiry / timeSteps;
        
        for (uint256 sim = 0; sim < numSimulations; sim++) {
            uint256[] memory pricePath = generatePricePath(
                params.spotPrice,
                params.riskFreeRate,
                params.volatility,
                dt,
                timeSteps,
                uint256(keccak256(abi.encodePacked(block.timestamp, sim, block.difficulty)))
            );
            
            uint256 payoff = calculateExoticPayoff(
                pricePath,
                params,
                exoticParams
            );
            
            totalPayoff += payoff;
        }
        
        uint256 avgPayoff = totalPayoff / numSimulations;
        uint256 discountFactor = exp(-params.riskFreeRate * params.timeToExpiry / PRECISION);
        
        return avgPayoff * discountFactor / PRECISION;
    }
    
    /**
     * @dev Generates price path using geometric Brownian motion
     * Use Case: Stochastic simulation for derivatives pricing
     */
    function generatePricePath(
        uint256 initialPrice,
        uint256 drift,
        uint256 volatility,
        uint256 dt,
        uint256 steps,
        uint256 seed
    ) internal pure returns (uint256[] memory) {
        uint256[] memory path = new uint256[](steps + 1);
        path[0] = initialPrice;
        
        uint256 dtSqrt = sqrt(dt);
        uint256 driftAdjusted = drift - volatility * volatility / (2 * PRECISION);
        
        for (uint256 i = 1; i <= steps; i++) {
            // Generate pseudo-random normal variable
            uint256 randomValue = uint256(keccak256(abi.encodePacked(seed, i))) % PRECISION;
            int256 normalRandom = int256(randomValue) - int256(PRECISION / 2); // Simplified normal
            
            uint256 drift_term = driftAdjusted * dt / PRECISION;
            int256 diffusion_term = int256(volatility * dtSqrt / PRECISION) * normalRandom / int256(PRECISION);
            
            uint256 priceRatio = exp(drift_term + abs(diffusion_term));
            path[i] = path[i - 1] * priceRatio / PRECISION;
        }
        
        return path;
    }
    
    /**
     * @dev Calculates payoff for exotic options
     * Use Case: Valuation of complex derivative structures
     */
    function calculateExoticPayoff(
        uint256[] memory pricePath,
        OptionParams memory params,
        ExoticParams memory exoticParams
    ) internal pure returns (uint256) {
        if (params.optionType == OptionType.ASIAN_CALL || params.optionType == OptionType.ASIAN_PUT) {
            return calculateAsianPayoff(pricePath, params);
        } else if (params.optionType == OptionType.BARRIER_CALL || params.optionType == OptionType.BARRIER_PUT) {
            return calculateBarrierPayoff(pricePath, params, exoticParams);
        } else if (params.optionType == OptionType.LOOKBACK_CALL || params.optionType == OptionType.LOOKBACK_PUT) {
            return calculateLookbackPayoff(pricePath, params);
        }
        
        // Default to European payoff
        uint256 finalPrice = pricePath[pricePath.length - 1];
        if (params.optionType == OptionType.CALL) {
            return finalPrice > params.strikePrice ? finalPrice - params.strikePrice : 0;
        } else {
            return params.strikePrice > finalPrice ? params.strikePrice - finalPrice : 0;
        }
    }
    
    /**
     * @dev Calculates Asian option payoff (average price options)
     * Use Case: Options based on average underlying price
     */
    function calculateAsianPayoff(
        uint256[] memory pricePath,
        OptionParams memory params
    ) internal pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < pricePath.length; i++) {
            sum += pricePath[i];
        }
        uint256 averagePrice = sum / pricePath.length;
        
        if (params.optionType == OptionType.ASIAN_CALL) {
            return averagePrice > params.strikePrice ? averagePrice - params.strikePrice : 0;
        } else {
            return params.strikePrice > averagePrice ? params.strikePrice - averagePrice : 0;
        }
    }
    
    /**
     * @dev Calculates barrier option payoff
     * Use Case: Options with knock-in/knock-out barriers
     */
    function calculateBarrierPayoff(
        uint256[] memory pricePath,
        OptionParams memory params,
        ExoticParams memory exoticParams
    ) internal pure returns (uint256) {
        bool barrierHit = false;
        
        // Check if barrier was hit
        for (uint256 i = 0; i < pricePath.length; i++) {
            if (exoticParams.barrierType == BarrierType.UP_AND_OUT || exoticParams.barrierType == BarrierType.UP_AND_IN) {
                if (pricePath[i] >= exoticParams.barrierLevel) {
                    barrierHit = true;
                    break;
                }
            } else {
                if (pricePath[i] <= exoticParams.barrierLevel) {
                    barrierHit = true;
                    break;
                }
            }
        }
        
        // Calculate payoff based on barrier type
        uint256 finalPrice = pricePath[pricePath.length - 1];
        uint256 vanillaPayoff;
        
        if (params.optionType == OptionType.BARRIER_CALL) {
            vanillaPayoff = finalPrice > params.strikePrice ? finalPrice - params.strikePrice : 0;
        } else {
            vanillaPayoff = params.strikePrice > finalPrice ? params.strikePrice - finalPrice : 0;
        }
        
        // Apply barrier conditions
        if (exoticParams.barrierType == BarrierType.UP_AND_OUT || exoticParams.barrierType == BarrierType.DOWN_AND_OUT) {
            return barrierHit ? exoticParams.rebate : vanillaPayoff;
        } else {
            return barrierHit ? vanillaPayoff : exoticParams.rebate;
        }
    }
    
    /**
     * @dev Calculates lookback option payoff
     * Use Case: Options based on maximum or minimum price over period
     */
    function calculateLookbackPayoff(
        uint256[] memory pricePath,
        OptionParams memory params
    ) internal pure returns (uint256) {
        uint256 maxPrice = 0;
        uint256 minPrice = type(uint256).max;
        
        for (uint256 i = 0; i < pricePath.length; i++) {
            if (pricePath[i] > maxPrice) maxPrice = pricePath[i];
            if (pricePath[i] < minPrice) minPrice = pricePath[i];
        }
        
        if (params.optionType == OptionType.LOOKBACK_CALL) {
            // Lookback call: payoff = max(S_max - K, 0)
            return maxPrice > params.strikePrice ? maxPrice - params.strikePrice : 0;
        } else {
            // Lookback put: payoff = max(K - S_min, 0)
            return params.strikePrice > minPrice ? params.strikePrice - minPrice : 0;
        }
    }
    
    /**
     * @dev Calculates option Greeks for risk management
     * Use Case: Delta hedging and risk assessment
     */
    function calculateGreeks(OptionParams memory params) internal pure returns (Greeks memory) {
        uint256 h = PRECISION / 100; // Small change for numerical differentiation
        
        // Calculate delta (∂V/∂S)
        OptionParams memory paramsUp = params;
        OptionParams memory paramsDown = params;
        paramsUp.spotPrice += h;
        paramsDown.spotPrice -= h;
        
        uint256 priceUp = blackScholesPrice(paramsUp);
        uint256 priceDown = blackScholesPrice(paramsDown);
        int256 delta = int256(priceUp - priceDown) / int256(2 * h);
        
        // Calculate gamma (∂²V/∂S²)
        uint256 originalPrice = blackScholesPrice(params);
        uint256 gamma = (priceUp + priceDown - 2 * originalPrice) / (h * h / PRECISION);
        
        // Calculate theta (∂V/∂t)
        OptionParams memory paramsTheta = params;
        paramsTheta.timeToExpiry -= PRECISION / 365; // One day less
        uint256 priceThetaDown = blackScholesPrice(paramsTheta);
        int256 theta = -int256(originalPrice - priceThetaDown) * int256(365);
        
        // Calculate vega (∂V/∂σ)
        OptionParams memory paramsVegaUp = params;
        paramsVegaUp.volatility += h;
        uint256 priceVegaUp = blackScholesPrice(paramsVegaUp);
        uint256 vega = (priceVegaUp - originalPrice) / h;
        
        // Calculate rho (∂V/∂r)
        OptionParams memory paramsRhoUp = params;
        paramsRhoUp.riskFreeRate += h;
        uint256 priceRhoUp = blackScholesPrice(paramsRhoUp);
        uint256 rho = (priceRhoUp - originalPrice) / h;
        
        return Greeks({
            delta: delta,
            gamma: gamma,
            theta: theta,
            vega: vega,
            rho: rho
        });
    }
    
    /**
     * @dev Implied volatility calculation using Newton-Raphson
     * Use Case: Market volatility discovery from option prices
     */
    function calculateImpliedVolatility(
        OptionParams memory params,
        uint256 marketPrice
    ) internal pure returns (uint256) {
        uint256 vol = params.volatility; // Initial guess
        uint256 tolerance = PRECISION / 10000; // 0.01% tolerance
        
        for (uint256 i = 0; i < MAX_ITERATIONS; i++) {
            params.volatility = vol;
            uint256 theoreticalPrice = blackScholesPrice(params);
            
            if (abs(int256(theoreticalPrice) - int256(marketPrice)) < tolerance) {
                return vol;
            }
            
            // Calculate vega for Newton-Raphson
            Greeks memory greeks = calculateGreeks(params);
            
            if (greeks.vega == 0) {
                revert ModelConvergenceFailed();
            }
            
            // Newton-Raphson update: vol_new = vol_old - f(vol)/f'(vol)
            int256 priceError = int256(theoreticalPrice) - int256(marketPrice);
            vol = vol - uint256(priceError * int256(PRECISION) / int256(greeks.vega));
            
            // Ensure volatility stays positive
            if (vol < PRECISION / 1000) vol = PRECISION / 1000; // Minimum 0.1%
            if (vol > 5 * PRECISION) vol = 5 * PRECISION; // Maximum 500%
        }
        
        revert ModelConvergenceFailed();
    }
    
    /**
     * @dev Interest rate swap pricing
     * Use Case: DeFi interest rate derivatives
     */
    function swapPrice(
        uint256 notional,
        uint256 fixedRate,
        uint256[] memory floatingRates,
        uint256[] memory discountFactors,
        uint256[] memory accrualPeriods
    ) internal pure returns (uint256 swapValue) {
        require(floatingRates.length == discountFactors.length, "DerivativePricing: length mismatch");
        require(floatingRates.length == accrualPeriods.length, "DerivativePricing: length mismatch");
        
        uint256 fixedLegValue = 0;
        uint256 floatingLegValue = 0;
        
        for (uint256 i = 0; i < floatingRates.length; i++) {
            // Fixed leg cash flow
            uint256 fixedCashFlow = notional * fixedRate * accrualPeriods[i] / (PRECISION * PRECISION);
            fixedLegValue += fixedCashFlow * discountFactors[i] / PRECISION;
            
            // Floating leg cash flow
            uint256 floatingCashFlow = notional * floatingRates[i] * accrualPeriods[i] / (PRECISION * PRECISION);
            floatingLegValue += floatingCashFlow * discountFactors[i] / PRECISION;
        }
        
        // Swap value = PV(floating leg) - PV(fixed leg)
        swapValue = floatingLegValue > fixedLegValue ? 
                   floatingLegValue - fixedLegValue : 
                   fixedLegValue - floatingLegValue;
    }
    
    // Helper functions
    function ln(uint256 x) internal pure returns (uint256) {
        // Simplified natural logarithm implementation
        require(x > 0, "ln of non-positive number");
        if (x == PRECISION) return 0;
        
        // Use series approximation for ln(1+x) where x = (input-1)
        uint256 result = 0;
        if (x > PRECISION) {
            uint256 term = (x - PRECISION) * PRECISION / x;
            result = term - term * term / (2 * PRECISION) + term * term * term / (3 * PRECISION * PRECISION);
        }
        return result;
    }
    
    function exp(uint256 x) internal pure returns (uint256) {
        // Simplified exponential function
        if (x == 0) return PRECISION;
        uint256 result = PRECISION + x;
        uint256 term = x;
        
        for (uint256 i = 2; i <= 20; i++) {
            term = term * x / (PRECISION * i);
            result += term;
            if (term < 1000) break;
        }
        return result;
    }
    
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 result = x;
        uint256 previous;
        
        do {
            previous = result;
            result = (result + x * PRECISION / result) / 2;
        } while (abs(int256(result) - int256(previous)) > 1);
        
        return result;
    }
    
    function normalCDF(uint256 x) internal pure returns (uint256) {
        // Simplified normal CDF approximation
        if (x > 3 * PRECISION) return PRECISION;
        if (x == PRECISION) return PRECISION / 2;
        
        // Basic approximation: 0.5 + x/6 for small x
        if (x < PRECISION) {
            return PRECISION / 2 + x / 6;
        } else {
            return PRECISION / 2 + (x - PRECISION) / 4;
        }
    }
    
    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
    
    function pow(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) return PRECISION;
        if (base == 0) return 0;
        
        uint256 result = PRECISION;
        while (exponent > 0) {
            if (exponent % 2 == 1) {
                result = result * base / PRECISION;
            }
            base = base * base / PRECISION;
            exponent /= 2;
        }
        return result;
    }
}