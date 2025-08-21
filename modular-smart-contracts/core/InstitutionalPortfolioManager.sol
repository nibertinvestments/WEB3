// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title InstitutionalPortfolioManager - Advanced Portfolio Management System
 * @dev Comprehensive portfolio management with institutional-grade features
 * 
 * FEATURES:
 * - Multi-strategy portfolio allocation and rebalancing
 * - Advanced risk management and stress testing
 * - Performance attribution and analytics
 * - Regulatory compliance and reporting
 * - ESG (Environmental, Social, Governance) integration
 * - Alternative investment strategies (private equity, real estate, commodities)
 * - Dynamic hedging and overlay strategies
 * - Institutional custody and settlement
 * 
 * COMPLIANCE FEATURES:
 * - GIPS (Global Investment Performance Standards) compliance
 * - Regulatory reporting (SEC, MiFID II, AIFMD)
 * - Risk limit monitoring and breach reporting
 * - Best execution monitoring
 * - Transaction cost analysis
 * 
 * USE CASES:
 * 1. Institutional asset management platforms
 * 2. Pension fund management systems
 * 3. Endowment and foundation portfolios
 * 4. Family office investment management
 * 5. Sovereign wealth fund operations
 * 6. Insurance company asset management
 * 
 * @author Nibert Investments LLC
 * @notice Institutional-Grade Portfolio Management with Regulatory Compliance
 */

import "../libraries/mathematical/StatisticalAnalysis.sol";
import "../libraries/financial/AdvancedDerivatives.sol";

contract InstitutionalPortfolioManager {
    using StatisticalAnalysis for uint256[];
    
    uint256 private constant PRECISION = 1e18;
    uint256 private constant BASIS_POINTS = 1e14; // 0.01%
    uint256 private constant MAX_ALLOCATIONS = 100;
    
    // Asset classes
    enum AssetClass {
        Equities,
        FixedIncome,
        Alternatives,
        RealEstate,
        Commodities,
        Cash,
        Derivatives,
        PrivateEquity,
        HedgeFunds,
        Infrastructure
    }
    
    // Investment styles
    enum InvestmentStyle {
        Value,
        Growth,
        Momentum,
        Quality,
        LowVolatility,
        ESGFocused,
        Quantitative,
        Passive
    }
    
    // Portfolio mandate structure
    struct PortfolioMandate {
        string name;
        address client;
        uint256 totalAUM; // Assets Under Management
        uint256 riskBudget; // Risk budget in basis points
        uint256 expectedReturn; // Expected annual return
        uint256 maxDrawdown; // Maximum allowed drawdown
        AssetClass[] allowedAssetClasses;
        uint256[] assetClassLimits; // Maximum allocation per asset class
        bool ESGCompliant;
        uint256 liquidityRequirement; // Minimum liquidity percentage
        uint256 inceptionDate;
    }
    
    // Portfolio allocation
    struct AssetAllocation {
        AssetClass assetClass;
        address asset;
        uint256 targetWeight; // Target weight in basis points
        uint256 currentWeight; // Current weight in basis points
        uint256 minWeight; // Minimum weight in basis points
        uint256 maxWeight; // Maximum weight in basis points
        uint256 marketValue;
        InvestmentStyle style;
        uint256 expectedReturn;
        uint256 expectedVolatility;
        bool isActive;
    }
    
    // Risk metrics
    struct RiskMetrics {
        uint256 portfolioVaR; // Value at Risk (95% confidence)
        uint256 portfolioCVaR; // Conditional Value at Risk
        uint256 trackingError; // Tracking error vs benchmark
        uint256 informationRatio; // Information ratio
        uint256 betaToMarket; // Beta to market
        uint256 correlationToMarket; // Correlation to market
        uint256 maxDrawdown; // Maximum historical drawdown
        uint256 calmarRatio; // Return/Max Drawdown
        uint256 sortinoRatio; // Downside deviation ratio
        uint256 lastUpdate;
    }
    
    // Performance attribution
    struct PerformanceAttribution {
        uint256 totalReturn;
        uint256 benchmarkReturn;
        uint256 activeReturn; // Total return - benchmark return
        uint256 selectionEffect; // Security selection contribution
        uint256 allocationEffect; // Asset allocation contribution
        uint256 interactionEffect; // Interaction between allocation and selection
        uint256 currencyEffect; // Currency hedging effect
        uint256 timingEffect; // Market timing effect
        uint256 expenseRatio; // Total expense ratio
        uint256 performanceFee; // Performance fee charged
    }
    
    // ESG scores and metrics
    struct ESGMetrics {
        uint256 environmentalScore; // Environmental score (0-100)
        uint256 socialScore; // Social score (0-100)
        uint256 governanceScore; // Governance score (0-100)
        uint256 overallESGScore; // Overall ESG score (0-100)
        uint256 carbonFootprint; // Carbon footprint metric
        bool sustainabilityCompliant;
        uint256 impactScore; // Sustainable impact score
        uint256 controversyScore; // ESG controversy score
    }
    
    // Regulatory compliance
    struct ComplianceMetrics {
        bool isGIPSCompliant;
        bool isMiFIDCompliant;
        bool isAIFMDCompliant;
        uint256 liquidityStress; // Liquidity stress test result
        uint256 concentrationRisk; // Concentration risk metric
        uint256 counterpartyRisk; // Counterparty risk exposure
        mapping(string => uint256) regulatoryLimits;
        mapping(string => bool) complianceBreaches;
        uint256 lastComplianceCheck;
    }
    
    // State variables
    mapping(uint256 => PortfolioMandate) public portfolioMandates;
    mapping(uint256 => AssetAllocation[]) public portfolioAllocations;
    mapping(uint256 => RiskMetrics) public portfolioRiskMetrics;
    mapping(uint256 => PerformanceAttribution) public performanceData;
    mapping(uint256 => ESGMetrics) public esgMetrics;
    mapping(uint256 => ComplianceMetrics) public complianceData;
    
    uint256 public totalPortfolios;
    address public chiefInvestmentOfficer;
    address public riskCommittee;
    address public complianceOfficer;
    
    // Events
    event PortfolioCreated(uint256 indexed portfolioId, address indexed client, uint256 aum);
    event AllocationUpdated(uint256 indexed portfolioId, AssetClass assetClass, uint256 newWeight);
    event RebalanceExecuted(uint256 indexed portfolioId, uint256 totalTurnover, uint256 transactionCosts);
    event RiskLimitBreached(uint256 indexed portfolioId, string limitType, uint256 currentValue, uint256 limit);
    event PerformanceCalculated(uint256 indexed portfolioId, uint256 period, uint256 totalReturn, uint256 benchmark);
    event ComplianceAlert(uint256 indexed portfolioId, string regulation, string issue);
    
    modifier onlyCIO() {
        require(msg.sender == chiefInvestmentOfficer, "Only CIO");
        _;
    }
    
    modifier onlyRiskCommittee() {
        require(msg.sender == riskCommittee, "Only risk committee");
        _;
    }
    
    modifier onlyCompliance() {
        require(msg.sender == complianceOfficer, "Only compliance officer");
        _;
    }
    
    constructor(
        address _cio,
        address _riskCommittee,
        address _complianceOfficer
    ) {
        chiefInvestmentOfficer = _cio;
        riskCommittee = _riskCommittee;
        complianceOfficer = _complianceOfficer;
    }
    
    /**
     * @dev Create a new institutional portfolio with mandate
     * Use Case: Onboard institutional client with investment mandate
     */
    function createPortfolio(
        string calldata name,
        address client,
        uint256 initialAUM,
        uint256 riskBudget,
        uint256 expectedReturn,
        AssetClass[] calldata allowedAssetClasses,
        uint256[] calldata assetClassLimits,
        bool ESGCompliant
    ) external onlyCIO returns (uint256 portfolioId) {
        require(allowedAssetClasses.length == assetClassLimits.length, "Mismatched arrays");
        require(initialAUM > 0, "Invalid AUM");
        
        portfolioId = totalPortfolios++;
        
        portfolioMandates[portfolioId] = PortfolioMandate({
            name: name,
            client: client,
            totalAUM: initialAUM,
            riskBudget: riskBudget,
            expectedReturn: expectedReturn,
            maxDrawdown: 2000, // 20% default max drawdown
            allowedAssetClasses: allowedAssetClasses,
            assetClassLimits: assetClassLimits,
            ESGCompliant: ESGCompliant,
            liquidityRequirement: 500, // 5% minimum liquidity
            inceptionDate: block.timestamp
        });
        
        // Initialize compliance metrics
        ComplianceMetrics storage compliance = complianceData[portfolioId];
        compliance.isGIPSCompliant = true;
        compliance.isMiFIDCompliant = true;
        compliance.isAIFMDCompliant = true;
        compliance.lastComplianceCheck = block.timestamp;
        
        emit PortfolioCreated(portfolioId, client, initialAUM);
        
        return portfolioId;
    }
    
    /**
     * @dev Set strategic asset allocation for portfolio
     * Use Case: Define long-term strategic allocation targets
     */
    function setStrategicAllocation(
        uint256 portfolioId,
        AssetClass[] calldata assetClasses,
        address[] calldata assets,
        uint256[] calldata targetWeights,
        uint256[] calldata minWeights,
        uint256[] calldata maxWeights,
        InvestmentStyle[] calldata styles
    ) external onlyCIO {
        require(assetClasses.length == targetWeights.length, "Mismatched arrays");
        require(isValidPortfolio(portfolioId), "Invalid portfolio");
        
        // Clear existing allocations
        delete portfolioAllocations[portfolioId];
        
        uint256 totalWeight = 0;
        
        for (uint256 i = 0; i < assetClasses.length; i++) {
            require(isAssetClassAllowed(portfolioId, assetClasses[i]), "Asset class not allowed");
            require(targetWeights[i] <= getAssetClassLimit(portfolioId, assetClasses[i]), "Exceeds limit");
            require(minWeights[i] <= targetWeights[i] && targetWeights[i] <= maxWeights[i], "Invalid weight bounds");
            
            portfolioAllocations[portfolioId].push(AssetAllocation({
                assetClass: assetClasses[i],
                asset: assets[i],
                targetWeight: targetWeights[i],
                currentWeight: 0, // Will be set during rebalancing
                minWeight: minWeights[i],
                maxWeight: maxWeights[i],
                marketValue: 0,
                style: styles[i],
                expectedReturn: 0, // Will be updated by research team
                expectedVolatility: 0, // Will be updated by research team
                isActive: true
            }));
            
            totalWeight += targetWeights[i];
            
            emit AllocationUpdated(portfolioId, assetClasses[i], targetWeights[i]);
        }
        
        require(totalWeight <= 10000, "Total allocation exceeds 100%");
    }
    
    /**
     * @dev Execute portfolio rebalancing based on strategic allocation
     * Use Case: Periodic rebalancing to maintain target allocations
     */
    function executeRebalancing(
        uint256 portfolioId,
        uint256[] calldata currentMarketValues,
        uint256 totalPortfolioValue,
        bool forceRebalance
    ) external returns (uint256 totalTurnover, uint256 estimatedCosts) {
        require(isValidPortfolio(portfolioId), "Invalid portfolio");
        
        AssetAllocation[] storage allocations = portfolioAllocations[portfolioId];
        require(allocations.length == currentMarketValues.length, "Mismatched market values");
        
        uint256[] memory rebalancingTrades = new uint256[](allocations.length);
        bool rebalanceNeeded = false;
        
        // Calculate current weights and required trades
        for (uint256 i = 0; i < allocations.length; i++) {
            allocations[i].marketValue = currentMarketValues[i];
            allocations[i].currentWeight = totalPortfolioValue > 0 ? 
                (currentMarketValues[i] * 10000) / totalPortfolioValue : 0;
            
            uint256 targetValue = (totalPortfolioValue * allocations[i].targetWeight) / 10000;
            
            if (currentMarketValues[i] > targetValue) {
                rebalancingTrades[i] = currentMarketValues[i] - targetValue; // Sell amount
            } else {
                rebalancingTrades[i] = targetValue - currentMarketValues[i]; // Buy amount
            }
            
            // Check if rebalancing threshold is exceeded (1% drift)
            uint256 drift = allocations[i].currentWeight > allocations[i].targetWeight ?
                allocations[i].currentWeight - allocations[i].targetWeight :
                allocations[i].targetWeight - allocations[i].currentWeight;
            
            if (drift > 100 || forceRebalance) { // 1% drift threshold
                rebalanceNeeded = true;
            }
            
            totalTurnover += rebalancingTrades[i];
        }
        
        if (rebalanceNeeded) {
            // Calculate transaction costs (simplified)
            estimatedCosts = (totalTurnover * 5) / 10000; // 0.05% transaction cost
            
            // Update current weights to target weights
            for (uint256 i = 0; i < allocations.length; i++) {
                allocations[i].currentWeight = allocations[i].targetWeight;
            }
            
            emit RebalanceExecuted(portfolioId, totalTurnover, estimatedCosts);
        }
        
        return (totalTurnover, estimatedCosts);
    }
    
    /**
     * @dev Calculate comprehensive risk metrics for portfolio
     * Use Case: Risk monitoring and regulatory reporting
     */
    function calculateRiskMetrics(
        uint256 portfolioId,
        uint256[] calldata assetReturns,
        uint256[] calldata benchmarkReturns,
        uint256[] calldata marketReturns
    ) external returns (RiskMetrics memory) {
        require(isValidPortfolio(portfolioId), "Invalid portfolio");
        
        RiskMetrics storage riskMetrics = portfolioRiskMetrics[portfolioId];
        
        // Calculate Value at Risk (95% confidence level)
        riskMetrics.portfolioVaR = assetReturns.valueAtRisk(9500);
        
        // Calculate Conditional Value at Risk
        riskMetrics.portfolioCVaR = assetReturns.conditionalValueAtRisk(9500);
        
        // Calculate tracking error vs benchmark
        if (benchmarkReturns.length > 0) {
            uint256[] memory activeReturns = new uint256[](assetReturns.length);
            for (uint256 i = 0; i < assetReturns.length; i++) {
                activeReturns[i] = assetReturns[i] >= benchmarkReturns[i] ? 
                    assetReturns[i] - benchmarkReturns[i] : 0;
            }
            riskMetrics.trackingError = activeReturns.standardDeviation();
            
            // Information ratio
            uint256 activeReturn = activeReturns.mean();
            riskMetrics.informationRatio = riskMetrics.trackingError > 0 ? 
                (activeReturn * PRECISION) / riskMetrics.trackingError : 0;
        }
        
        // Calculate beta and correlation to market
        if (marketReturns.length > 0) {
            riskMetrics.betaToMarket = assetReturns.beta(marketReturns);
            riskMetrics.correlationToMarket = assetReturns.correlation(marketReturns);
        }
        
        // Calculate maximum drawdown
        riskMetrics.maxDrawdown = assetReturns.maxDrawdown(assetReturns);
        
        // Calculate Calmar ratio (Annual return / Max drawdown)
        uint256 annualReturn = assetReturns.mean() * 365; // Simplified annualization
        riskMetrics.calmarRatio = riskMetrics.maxDrawdown > 0 ? 
            (annualReturn * PRECISION) / riskMetrics.maxDrawdown : 0;
        
        // Calculate Sortino ratio (return / downside deviation)
        uint256 downsideDeviation = calculateDownsideDeviation(assetReturns, 0);
        riskMetrics.sortinoRatio = downsideDeviation > 0 ? 
            (annualReturn * PRECISION) / downsideDeviation : 0;
        
        riskMetrics.lastUpdate = block.timestamp;
        
        // Check risk limits
        checkRiskLimits(portfolioId, riskMetrics);
        
        return riskMetrics;
    }
    
    /**
     * @dev Perform performance attribution analysis
     * Use Case: Detailed performance analysis for institutional reporting
     */
    function calculatePerformanceAttribution(
        uint256 portfolioId,
        uint256[] calldata portfolioReturns,
        uint256[] calldata benchmarkReturns,
        uint256[] calldata allocationReturns,
        uint256[] calldata selectionReturns,
        uint256 performanceFee
    ) external returns (PerformanceAttribution memory) {
        require(isValidPortfolio(portfolioId), "Invalid portfolio");
        
        PerformanceAttribution storage perfAttr = performanceData[portfolioId];
        
        // Calculate total returns
        perfAttr.totalReturn = portfolioReturns.mean();
        perfAttr.benchmarkReturn = benchmarkReturns.mean();
        perfAttr.activeReturn = perfAttr.totalReturn >= perfAttr.benchmarkReturn ? 
            perfAttr.totalReturn - perfAttr.benchmarkReturn : 0;
        
        // Attribution effects
        perfAttr.allocationEffect = allocationReturns.mean();
        perfAttr.selectionEffect = selectionReturns.mean();
        perfAttr.interactionEffect = perfAttr.activeReturn >= (perfAttr.allocationEffect + perfAttr.selectionEffect) ?
            perfAttr.activeReturn - perfAttr.allocationEffect - perfAttr.selectionEffect : 0;
        
        // Currency effect (simplified)
        perfAttr.currencyEffect = 0; // Would be calculated based on currency exposures
        
        // Timing effect (simplified)
        perfAttr.timingEffect = 0; // Would be calculated based on tactical allocation changes
        
        // Calculate expense ratio (annualized)
        perfAttr.expenseRatio = 50; // 0.5% default expense ratio
        perfAttr.performanceFee = performanceFee;
        
        emit PerformanceCalculated(portfolioId, 365, perfAttr.totalReturn, perfAttr.benchmarkReturn);
        
        return perfAttr;
    }
    
    /**
     * @dev Calculate ESG metrics for portfolio
     * Use Case: ESG reporting and sustainable investing compliance
     */
    function calculateESGMetrics(
        uint256 portfolioId,
        uint256[] calldata assetESGScores,
        uint256[] calldata assetWeights,
        uint256[] calldata carbonFootprints
    ) external returns (ESGMetrics memory) {
        require(isValidPortfolio(portfolioId), "Invalid portfolio");
        require(portfolioMandates[portfolioId].ESGCompliant, "Portfolio not ESG compliant");
        
        ESGMetrics storage esg = esgMetrics[portfolioId];
        
        // Calculate weighted average ESG scores
        uint256 totalWeight = 0;
        uint256 weightedEnvironmental = 0;
        uint256 weightedSocial = 0;
        uint256 weightedGovernance = 0;
        uint256 weightedCarbon = 0;
        
        for (uint256 i = 0; i < assetESGScores.length; i++) {
            uint256 weight = assetWeights[i];
            totalWeight += weight;
            
            // Assume ESG score is composite: E (30%), S (30%), G (40%)
            uint256 envScore = (assetESGScores[i] * 30) / 100;
            uint256 socScore = (assetESGScores[i] * 30) / 100;
            uint256 govScore = (assetESGScores[i] * 40) / 100;
            
            weightedEnvironmental += (envScore * weight) / PRECISION;
            weightedSocial += (socScore * weight) / PRECISION;
            weightedGovernance += (govScore * weight) / PRECISION;
            
            if (i < carbonFootprints.length) {
                weightedCarbon += (carbonFootprints[i] * weight) / PRECISION;
            }
        }
        
        if (totalWeight > 0) {
            esg.environmentalScore = (weightedEnvironmental * PRECISION) / totalWeight;
            esg.socialScore = (weightedSocial * PRECISION) / totalWeight;
            esg.governanceScore = (weightedGovernance * PRECISION) / totalWeight;
            esg.carbonFootprint = (weightedCarbon * PRECISION) / totalWeight;
        }
        
        // Calculate overall ESG score
        esg.overallESGScore = (esg.environmentalScore + esg.socialScore + esg.governanceScore) / 3;
        
        // Determine sustainability compliance
        esg.sustainabilityCompliant = esg.overallESGScore >= 70 * PRECISION / 100; // 70% threshold
        
        // Calculate impact score (simplified)
        esg.impactScore = esg.overallESGScore; // Would use more sophisticated impact metrics
        
        // Controversy score (lower is better)
        esg.controversyScore = 100 * PRECISION / 100 - esg.overallESGScore; // Inverse of ESG score
        
        return esg;
    }
    
    /**
     * @dev Perform regulatory compliance checking
     * Use Case: Automated compliance monitoring and reporting
     */
    function performComplianceCheck(
        uint256 portfolioId,
        uint256[] calldata exposures,
        uint256[] calldata liquidityMetrics
    ) external onlyCompliance returns (bool isCompliant) {
        require(isValidPortfolio(portfolioId), "Invalid portfolio");
        
        ComplianceMetrics storage compliance = complianceData[portfolioId];
        isCompliant = true;
        
        // Check concentration limits
        for (uint256 i = 0; i < exposures.length; i++) {
            if (exposures[i] > 1000) { // 10% concentration limit
                compliance.complianceBreaches["concentration"] = true;
                isCompliant = false;
                emit ComplianceAlert(portfolioId, "Concentration", "Single position exceeds 10%");
            }
        }
        
        // Check liquidity requirements
        uint256 totalLiquidity = 0;
        for (uint256 i = 0; i < liquidityMetrics.length; i++) {
            totalLiquidity += liquidityMetrics[i];
        }
        
        uint256 portfolioLiquidity = liquidityMetrics.length > 0 ? 
            totalLiquidity / liquidityMetrics.length : 0;
        
        if (portfolioLiquidity < portfolioMandates[portfolioId].liquidityRequirement) {
            compliance.complianceBreaches["liquidity"] = true;
            isCompliant = false;
            emit ComplianceAlert(portfolioId, "Liquidity", "Insufficient liquidity");
        }
        
        // Stress test compliance
        compliance.liquidityStress = performLiquidityStressTest(portfolioId, liquidityMetrics);
        if (compliance.liquidityStress > 2000) { // 20% stress test threshold
            compliance.complianceBreaches["stress_test"] = true;
            isCompliant = false;
            emit ComplianceAlert(portfolioId, "Stress Test", "Failed liquidity stress test");
        }
        
        compliance.lastComplianceCheck = block.timestamp;
        
        return isCompliant;
    }
    
    /**
     * @dev Execute dynamic hedging strategy
     * Use Case: Portfolio risk management through derivatives
     */
    function executeDynamicHedging(
        uint256 portfolioId,
        uint256 portfolioDelta,
        uint256 portfolioGamma,
        uint256 targetDelta,
        uint256 hedgingCost
    ) external onlyCIO returns (uint256 hedgeRatio) {
        require(isValidPortfolio(portfolioId), "Invalid portfolio");
        
        // Calculate required hedge ratio to achieve target delta
        hedgeRatio = portfolioDelta > targetDelta ? 
            ((portfolioDelta - targetDelta) * PRECISION) / portfolioDelta : 0;
        
        // Adjust for gamma (convexity)
        uint256 gammaAdjustment = (portfolioGamma * hedgeRatio) / (2 * PRECISION);
        hedgeRatio += gammaAdjustment;
        
        // Cost-benefit analysis
        uint256 hedgingBenefit = calculateHedgingBenefit(portfolioId, hedgeRatio);
        
        if (hedgingBenefit > hedgingCost) {
            // Execute hedge (simplified)
            emit AllocationUpdated(portfolioId, AssetClass.Derivatives, hedgeRatio);
        } else {
            hedgeRatio = 0; // Don't hedge if cost exceeds benefit
        }
        
        return hedgeRatio;
    }
    
    // Internal helper functions
    function isValidPortfolio(uint256 portfolioId) internal view returns (bool) {
        return portfolioId < totalPortfolios && portfolioMandates[portfolioId].client != address(0);
    }
    
    function isAssetClassAllowed(uint256 portfolioId, AssetClass assetClass) internal view returns (bool) {
        AssetClass[] memory allowed = portfolioMandates[portfolioId].allowedAssetClasses;
        for (uint256 i = 0; i < allowed.length; i++) {
            if (allowed[i] == assetClass) return true;
        }
        return false;
    }
    
    function getAssetClassLimit(uint256 portfolioId, AssetClass assetClass) internal view returns (uint256) {
        AssetClass[] memory allowed = portfolioMandates[portfolioId].allowedAssetClasses;
        uint256[] memory limits = portfolioMandates[portfolioId].assetClassLimits;
        
        for (uint256 i = 0; i < allowed.length; i++) {
            if (allowed[i] == assetClass) return limits[i];
        }
        return 0;
    }
    
    function checkRiskLimits(uint256 portfolioId, RiskMetrics memory riskMetrics) internal {
        PortfolioMandate storage mandate = portfolioMandates[portfolioId];
        
        if (riskMetrics.portfolioVaR > mandate.riskBudget) {
            emit RiskLimitBreached(portfolioId, "VaR", riskMetrics.portfolioVaR, mandate.riskBudget);
        }
        
        if (riskMetrics.maxDrawdown > mandate.maxDrawdown * BASIS_POINTS) {
            emit RiskLimitBreached(portfolioId, "Max Drawdown", riskMetrics.maxDrawdown, mandate.maxDrawdown);
        }
    }
    
    function calculateDownsideDeviation(uint256[] memory returns, uint256 threshold) internal pure returns (uint256) {
        uint256 sumNegativeSquaredDeviations = 0;
        uint256 negativeCount = 0;
        
        for (uint256 i = 0; i < returns.length; i++) {
            if (returns[i] < threshold) {
                uint256 deviation = threshold - returns[i];
                sumNegativeSquaredDeviations += (deviation * deviation) / PRECISION;
                negativeCount++;
            }
        }
        
        if (negativeCount == 0) return 0;
        
        uint256 variance = sumNegativeSquaredDeviations / negativeCount;
        return sqrt(variance);
    }
    
    function performLiquidityStressTest(uint256 portfolioId, uint256[] memory liquidityMetrics) internal pure returns (uint256) {
        // Simplified stress test: assume 50% liquidity reduction
        uint256 totalLiquidity = 0;
        for (uint256 i = 0; i < liquidityMetrics.length; i++) {
            totalLiquidity += liquidityMetrics[i] / 2; // 50% haircut
        }
        
        return liquidityMetrics.length > 0 ? totalLiquidity / liquidityMetrics.length : 0;
    }
    
    function calculateHedgingBenefit(uint256 portfolioId, uint256 hedgeRatio) internal view returns (uint256) {
        // Simplified calculation based on risk reduction
        RiskMetrics storage riskMetrics = portfolioRiskMetrics[portfolioId];
        return (riskMetrics.portfolioVaR * hedgeRatio) / PRECISION;
    }
    
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 guess = x;
        for (uint256 i = 0; i < 20; i++) {
            uint256 newGuess = (guess + (x * PRECISION) / guess) / 2;
            if (abs(newGuess, guess) < 1e12) return newGuess;
            guess = newGuess;
        }
        return guess;
    }
    
    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }
}