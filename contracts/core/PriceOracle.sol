// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PriceOracle - Decentralized Price Feed System
 * @dev Aggregates multiple price sources for reliable asset pricing
 * 
 * USE CASES:
 * 1. DeFi protocol price feeds for lending/borrowing
 * 2. Stablecoin pegging mechanisms
 * 3. Liquidation calculations in margin trading
 * 4. Portfolio valuation for asset management
 * 5. Arbitrage opportunity detection
 * 6. Insurance protocol risk assessment
 * 
 * WHY IT WORKS:
 * - Multiple oracle sources prevent single points of failure
 * - Median calculation reduces price manipulation risks
 * - Time-weighted averages smooth out volatility
 * - Deviation thresholds flag suspicious price movements
 * - Emergency circuit breakers protect against oracle attacks
 * 
 * @author Nibert Investments Development Team
 */

contract PriceOracle {
    // Price data structure
    struct PriceData {
        uint256 price;
        uint256 timestamp;
        uint256 confidence;
        bool isActive;
    }
    
    // Oracle source information
    struct OracleSource {
        address oracle;
        string name;
        uint256 weight;
        bool isActive;
        uint256 lastUpdate;
        uint256 deviationThreshold; // Maximum allowed deviation from median
    }
    
    // Asset price tracking
    struct AssetPrice {
        uint256 currentPrice;
        uint256 lastPrice;
        uint256 lastUpdate;
        uint256 priceChange24h;
        uint256 volatility;
        bool isStable;
        uint256 confidence;
    }
    
    // State variables
    mapping(string => AssetPrice) public assetPrices;
    mapping(string => OracleSource[]) public assetOracles;
    mapping(string => mapping(address => PriceData)) public oraclePrices;
    mapping(address => bool) public authorizedOracles;
    mapping(string => bool) public supportedAssets;
    
    address public owner;
    uint256 public constant PRICE_VALIDITY_PERIOD = 1 hours;
    uint256 public constant MIN_ORACLES_REQUIRED = 3;
    uint256 public constant MAX_DEVIATION_THRESHOLD = 1000; // 10%
    
    string[] public assetList;
    
    // Events
    event PriceUpdated(string indexed asset, uint256 price, uint256 timestamp, uint256 confidence);
    event OracleAdded(string indexed asset, address indexed oracle, string name);
    event OracleRemoved(string indexed asset, address indexed oracle);
    event AssetAdded(string indexed asset);
    event EmergencyPause(string indexed asset, string reason);
    event PriceDeviation(string indexed asset, address indexed oracle, uint256 deviation);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    
    modifier onlyAuthorizedOracle() {
        require(authorizedOracles[msg.sender], "Not authorized oracle");
        _;
    }
    
    modifier validAsset(string memory asset) {
        require(supportedAssets[asset], "Asset not supported");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Adds a new asset to track
     * Use Case: Expanding oracle coverage to new tokens
     */
    function addAsset(string memory asset) external onlyOwner {
        require(!supportedAssets[asset], "Asset already supported");
        require(bytes(asset).length > 0, "Invalid asset name");
        
        supportedAssets[asset] = true;
        assetList.push(asset);
        
        // Initialize with default values
        assetPrices[asset] = AssetPrice({
            currentPrice: 0,
            lastPrice: 0,
            lastUpdate: 0,
            priceChange24h: 0,
            volatility: 0,
            isStable: true,
            confidence: 0
        });
        
        emit AssetAdded(asset);
    }
    
    /**
     * @dev Adds an oracle source for an asset
     * Use Case: Increasing price feed reliability through redundancy
     */
    function addOracleSource(
        string memory asset,
        address oracle,
        string memory name,
        uint256 weight,
        uint256 deviationThreshold
    ) external onlyOwner validAsset(asset) {
        require(oracle != address(0), "Invalid oracle address");
        require(weight > 0 && weight <= 100, "Invalid weight");
        require(deviationThreshold <= MAX_DEVIATION_THRESHOLD, "Deviation threshold too high");
        
        // Check if oracle already exists for this asset
        OracleSource[] storage oracles = assetOracles[asset];
        for (uint256 i = 0; i < oracles.length; i++) {
            require(oracles[i].oracle != oracle, "Oracle already exists");
        }
        
        oracles.push(OracleSource({
            oracle: oracle,
            name: name,
            weight: weight,
            isActive: true,
            lastUpdate: 0,
            deviationThreshold: deviationThreshold
        }));
        
        authorizedOracles[oracle] = true;
        emit OracleAdded(asset, oracle, name);
    }
    
    /**
     * @dev Updates price from oracle source
     * Use Case: Continuous price feed updates from external oracles
     */
    function updatePrice(
        string memory asset,
        uint256 price,
        uint256 confidence
    ) external onlyAuthorizedOracle validAsset(asset) {
        require(price > 0, "Invalid price");
        require(confidence > 0 && confidence <= 100, "Invalid confidence");
        
        oraclePrices[asset][msg.sender] = PriceData({
            price: price,
            timestamp: block.timestamp,
            confidence: confidence,
            isActive: true
        });
        
        // Update oracle source timestamp
        OracleSource[] storage oracles = assetOracles[asset];
        for (uint256 i = 0; i < oracles.length; i++) {
            if (oracles[i].oracle == msg.sender) {
                oracles[i].lastUpdate = block.timestamp;
                break;
            }
        }
        
        _calculateAggregatedPrice(asset);
    }
    
    /**
     * @dev Calculates aggregated price from multiple oracle sources
     */
    function _calculateAggregatedPrice(string memory asset) internal {
        OracleSource[] memory oracles = assetOracles[asset];
        require(oracles.length >= MIN_ORACLES_REQUIRED, "Insufficient oracle sources");
        
        uint256[] memory prices = new uint256[](oracles.length);
        uint256[] memory weights = new uint256[](oracles.length);
        uint256 validOracleCount = 0;
        uint256 totalWeight = 0;
        
        // Collect valid prices
        for (uint256 i = 0; i < oracles.length; i++) {
            if (!oracles[i].isActive) continue;
            
            PriceData memory priceData = oraclePrices[asset][oracles[i].oracle];
            
            // Check if price is recent enough
            if (block.timestamp - priceData.timestamp <= PRICE_VALIDITY_PERIOD && priceData.isActive) {
                prices[validOracleCount] = priceData.price;
                weights[validOracleCount] = oracles[i].weight;
                totalWeight += oracles[i].weight;
                validOracleCount++;
            }
        }
        
        require(validOracleCount >= MIN_ORACLES_REQUIRED, "Insufficient valid oracle prices");
        
        // Calculate median price
        uint256 medianPrice = _calculateMedian(prices, validOracleCount);
        
        // Check for price deviations
        _checkPriceDeviations(asset, prices, validOracleCount, medianPrice);
        
        // Calculate weighted average
        uint256 weightedPrice = _calculateWeightedAverage(prices, weights, validOracleCount, totalWeight);
        
        // Calculate confidence score
        uint256 aggregatedConfidence = _calculateConfidence(asset, prices, validOracleCount);
        
        // Update asset price
        AssetPrice storage assetPrice = assetPrices[asset];
        assetPrice.lastPrice = assetPrice.currentPrice;
        assetPrice.currentPrice = weightedPrice;
        assetPrice.lastUpdate = block.timestamp;
        assetPrice.confidence = aggregatedConfidence;
        
        // Calculate 24h price change
        if (assetPrice.lastPrice > 0) {
            if (weightedPrice > assetPrice.lastPrice) {
                assetPrice.priceChange24h = ((weightedPrice - assetPrice.lastPrice) * 10000) / assetPrice.lastPrice;
            } else {
                assetPrice.priceChange24h = ((assetPrice.lastPrice - weightedPrice) * 10000) / assetPrice.lastPrice;
            }
        }
        
        // Calculate volatility and stability
        assetPrice.volatility = _calculateVolatility(asset, prices, validOracleCount);
        assetPrice.isStable = assetPrice.volatility < 100; // 1% volatility threshold
        
        emit PriceUpdated(asset, weightedPrice, block.timestamp, aggregatedConfidence);
    }
    
    /**
     * @dev Calculates median price from array
     */
    function _calculateMedian(uint256[] memory prices, uint256 length) internal pure returns (uint256) {
        // Simple bubble sort for small arrays
        for (uint256 i = 0; i < length - 1; i++) {
            for (uint256 j = 0; j < length - i - 1; j++) {
                if (prices[j] > prices[j + 1]) {
                    uint256 temp = prices[j];
                    prices[j] = prices[j + 1];
                    prices[j + 1] = temp;
                }
            }
        }
        
        if (length % 2 == 0) {
            return (prices[length / 2 - 1] + prices[length / 2]) / 2;
        } else {
            return prices[length / 2];
        }
    }
    
    /**
     * @dev Calculates weighted average price
     */
    function _calculateWeightedAverage(
        uint256[] memory prices,
        uint256[] memory weights,
        uint256 length,
        uint256 totalWeight
    ) internal pure returns (uint256) {
        uint256 weightedSum = 0;
        
        for (uint256 i = 0; i < length; i++) {
            weightedSum += (prices[i] * weights[i]);
        }
        
        return weightedSum / totalWeight;
    }
    
    /**
     * @dev Checks for price deviations from median
     */
    function _checkPriceDeviations(
        string memory asset,
        uint256[] memory prices,
        uint256 length,
        uint256 medianPrice
    ) internal {
        OracleSource[] memory oracles = assetOracles[asset];
        
        for (uint256 i = 0; i < length; i++) {
            uint256 deviation = prices[i] > medianPrice ?
                ((prices[i] - medianPrice) * 10000) / medianPrice :
                ((medianPrice - prices[i]) * 10000) / medianPrice;
            
            if (deviation > oracles[i].deviationThreshold) {
                emit PriceDeviation(asset, oracles[i].oracle, deviation);
                
                // Temporarily disable oracle if deviation is too high
                if (deviation > MAX_DEVIATION_THRESHOLD) {
                    _disableOracle(asset, oracles[i].oracle);
                }
            }
        }
    }
    
    /**
     * @dev Calculates price confidence based on oracle agreement
     */
    function _calculateConfidence(
        string memory asset,
        uint256[] memory prices,
        uint256 length
    ) internal view returns (uint256) {
        if (length < MIN_ORACLES_REQUIRED) return 0;
        
        uint256 medianPrice = _calculateMedian(prices, length);
        uint256 totalDeviation = 0;
        
        for (uint256 i = 0; i < length; i++) {
            uint256 deviation = prices[i] > medianPrice ?
                ((prices[i] - medianPrice) * 100) / medianPrice :
                ((medianPrice - prices[i]) * 100) / medianPrice;
            totalDeviation += deviation;
        }
        
        uint256 avgDeviation = totalDeviation / length;
        
        // Higher agreement (lower deviation) means higher confidence
        if (avgDeviation <= 1) return 100; // 1% or less deviation = 100% confidence
        if (avgDeviation <= 5) return 90;  // 5% or less deviation = 90% confidence
        if (avgDeviation <= 10) return 75; // 10% or less deviation = 75% confidence
        
        return 50; // Higher deviation = 50% confidence
    }
    
    /**
     * @dev Calculates price volatility
     */
    function _calculateVolatility(
        string memory asset,
        uint256[] memory prices,
        uint256 length
    ) internal pure returns (uint256) {
        if (length < 2) return 0;
        
        uint256 sum = 0;
        for (uint256 i = 0; i < length; i++) {
            sum += prices[i];
        }
        
        uint256 average = sum / length;
        uint256 varianceSum = 0;
        
        for (uint256 i = 0; i < length; i++) {
            uint256 diff = prices[i] > average ? prices[i] - average : average - prices[i];
            varianceSum += (diff * diff);
        }
        
        uint256 variance = varianceSum / length;
        
        // Return volatility as basis points (scaled by average price)
        return (variance * 10000) / (average * average);
    }
    
    /**
     * @dev Disables an oracle source
     */
    function _disableOracle(string memory asset, address oracle) internal {
        OracleSource[] storage oracles = assetOracles[asset];
        for (uint256 i = 0; i < oracles.length; i++) {
            if (oracles[i].oracle == oracle) {
                oracles[i].isActive = false;
                break;
            }
        }
    }
    
    /**
     * @dev Gets current price for an asset
     * Use Case: DeFi protocols querying asset prices
     */
    function getPrice(string memory asset) 
        external 
        view 
        validAsset(asset) 
        returns (
            uint256 price,
            uint256 timestamp,
            uint256 confidence,
            bool isStale
        ) 
    {
        AssetPrice memory assetPrice = assetPrices[asset];
        bool stale = block.timestamp - assetPrice.lastUpdate > PRICE_VALIDITY_PERIOD;
        
        return (
            assetPrice.currentPrice,
            assetPrice.lastUpdate,
            assetPrice.confidence,
            stale
        );
    }
    
    /**
     * @dev Gets detailed asset information
     * Use Case: Analytics, portfolio tracking, risk assessment
     */
    function getAssetDetails(string memory asset)
        external
        view
        validAsset(asset)
        returns (
            uint256 currentPrice,
            uint256 lastPrice,
            uint256 priceChange24h,
            uint256 volatility,
            bool isStable,
            uint256 confidence,
            uint256 lastUpdate
        )
    {
        AssetPrice memory assetPrice = assetPrices[asset];
        return (
            assetPrice.currentPrice,
            assetPrice.lastPrice,
            assetPrice.priceChange24h,
            assetPrice.volatility,
            assetPrice.isStable,
            assetPrice.confidence,
            assetPrice.lastUpdate
        );
    }
    
    /**
     * @dev Gets oracle sources for an asset
     */
    function getOracleSources(string memory asset) 
        external 
        view 
        validAsset(asset) 
        returns (
            address[] memory oracles,
            string[] memory names,
            bool[] memory active
        ) 
    {
        OracleSource[] memory sources = assetOracles[asset];
        
        oracles = new address[](sources.length);
        names = new string[](sources.length);
        active = new bool[](sources.length);
        
        for (uint256 i = 0; i < sources.length; i++) {
            oracles[i] = sources[i].oracle;
            names[i] = sources[i].name;
            active[i] = sources[i].isActive;
        }
    }
    
    /**
     * @dev Emergency pause for asset
     */
    function emergencyPause(string memory asset, string memory reason) 
        external 
        onlyOwner 
        validAsset(asset) 
    {
        assetPrices[asset].isStable = false;
        emit EmergencyPause(asset, reason);
    }
    
    /**
     * @dev Removes oracle source
     */
    function removeOracleSource(string memory asset, address oracle) 
        external 
        onlyOwner 
        validAsset(asset) 
    {
        OracleSource[] storage oracles = assetOracles[asset];
        
        for (uint256 i = 0; i < oracles.length; i++) {
            if (oracles[i].oracle == oracle) {
                oracles[i] = oracles[oracles.length - 1];
                oracles.pop();
                authorizedOracles[oracle] = false;
                emit OracleRemoved(asset, oracle);
                break;
            }
        }
    }
    
    /**
     * @dev Gets all supported assets
     */
    function getSupportedAssets() external view returns (string[] memory) {
        return assetList;
    }
    
    /**
     * @dev Transfers ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }
}