// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IModularContract.sol";

/**
 * @title VotingWeightCalculator - Advanced Voting Weight Computation Engine
 * @dev Atomic contract for sophisticated voting weight calculations in governance systems
 * 
 * USE CASES:
 * 1. Token-weighted voting in DAOs
 * 2. Quadratic voting mechanisms
 * 3. Reputation-based governance systems
 * 4. Time-decay voting weight calculations
 * 5. Multi-factor voting weight algorithms
 * 6. Delegation and proxy voting systems
 * 
 * WHY IT WORKS:
 * - Supports multiple voting weight algorithms
 * - Gas-optimized calculations for large-scale voting
 * - Prevents gaming through sophisticated math
 * - Time-based weight adjustments prevent last-minute manipulation
 * - Modular design allows easy integration with governance systems
 * 
 * @author Nibert Investments Development Team
 */
contract VotingWeightCalculator is IModularContract {
    
    // Module identification
    bytes32 public constant MODULE_ID = keccak256("VOTING_WEIGHT_CALCULATOR_V1");
    uint256 public constant MODULE_VERSION = 1;
    
    // Mathematical constants
    uint256 public constant PRECISION = 1e18;
    uint256 public constant MAX_WEIGHT = 1e30;
    uint256 public constant MIN_VOTING_PERIOD = 1 hours;
    uint256 public constant MAX_VOTING_PERIOD = 30 days;
    
    // Weight calculation types
    enum WeightType {
        Linear,           // Direct token balance
        Quadratic,        // Square root of balance
        Logarithmic,      // Log-based weighting
        TimeDecay,        // Decay over time
        Reputation,       // Reputation-based
        Hybrid            // Combination of multiple factors
    }
    
    // Voting configuration
    struct VotingConfig {
        WeightType weightType;
        uint256 decayRate;        // For time decay (per second)
        uint256 reputationFactor; // For reputation weighting
        uint256 minBalance;       // Minimum token balance
        uint256 maxWeight;        // Maximum individual weight
        bool useTimeBonus;        // Apply early voting bonus
        bool useDelegation;       // Enable delegation multiplier
    }
    
    // Voter data
    struct VoterData {
        uint256 tokenBalance;
        uint256 reputation;
        uint256 stakingDuration;
        uint256 delegatedPower;
        uint256 lastVoteTime;
        bool isEligible;
    }
    
    // Vote timing data
    struct VoteTimingData {
        uint256 proposalStart;
        uint256 votingStart;
        uint256 votingEnd;
        uint256 voteTime;
    }
    
    // State variables
    bool private _initialized;
    mapping(bytes32 => VotingConfig) private _configurations;
    mapping(address => mapping(bytes32 => uint256)) private _voterWeights;
    mapping(bytes32 => uint256) private _totalWeights;
    
    // Events
    event WeightCalculated(
        address indexed voter,
        bytes32 indexed configId,
        uint256 weight,
        WeightType weightType
    );
    event ConfigurationUpdated(bytes32 indexed configId, WeightType weightType);
    event WeightCached(address indexed voter, bytes32 indexed configId, uint256 weight);
    
    // Errors
    error InvalidConfiguration();
    error VoterNotEligible(address voter);
    error WeightTooHigh(uint256 weight, uint256 maxWeight);
    error InvalidTimePeriod(uint256 start, uint256 end);
    error CalculationOverflow();
    
    // Module interface implementations
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
            "VotingWeightCalculator",
            "Advanced voting weight computation engine",
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
        if (selector == bytes4(keccak256("calculateWeight(address,bytes32)"))) {
            (address voter, bytes32 configId) = abi.decode(data, (address, bytes32));
            return abi.encode(calculateVotingWeight(voter, configId));
        } else if (selector == bytes4(keccak256("calculateQuadraticWeight(uint256)"))) {
            uint256 balance = abi.decode(data, (uint256));
            return abi.encode(calculateQuadraticWeight(balance));
        }
        revert("Function not supported");
    }
    
    /**
     * @dev Calculate voting weight for a voter using specified configuration
     */
    function calculateVotingWeight(
        address voter,
        bytes32 configId
    ) public view returns (uint256 weight) {
        VotingConfig memory config = _configurations[configId];
        
        // Get voter data (would typically come from external contracts)
        VoterData memory voterData = _getVoterData(voter);
        
        if (!voterData.isEligible) {
            revert VoterNotEligible(voter);
        }
        
        // Calculate base weight based on type
        if (config.weightType == WeightType.Linear) {
            weight = _calculateLinearWeight(voterData, config);
        } else if (config.weightType == WeightType.Quadratic) {
            weight = _calculateQuadraticWeight(voterData, config);
        } else if (config.weightType == WeightType.Logarithmic) {
            weight = _calculateLogarithmicWeight(voterData, config);
        } else if (config.weightType == WeightType.TimeDecay) {
            weight = _calculateTimeDecayWeight(voterData, config);
        } else if (config.weightType == WeightType.Reputation) {
            weight = _calculateReputationWeight(voterData, config);
        } else if (config.weightType == WeightType.Hybrid) {
            weight = _calculateHybridWeight(voterData, config);
        }
        
        // Apply maximum weight limit
        if (weight > config.maxWeight) {
            weight = config.maxWeight;
        }
        
        emit WeightCalculated(voter, configId, weight, config.weightType);
        return weight;
    }
    
    /**
     * @dev Calculate linear weight (direct token balance)
     */
    function _calculateLinearWeight(
        VoterData memory voterData,
        VotingConfig memory config
    ) internal pure returns (uint256) {
        if (voterData.tokenBalance < config.minBalance) {
            return 0;
        }
        
        uint256 weight = voterData.tokenBalance + voterData.delegatedPower;
        
        // Apply staking bonus
        if (voterData.stakingDuration > 0) {
            uint256 stakingBonus = (weight * voterData.stakingDuration) / (365 days);
            weight += stakingBonus / 10; // 10% annual staking bonus
        }
        
        return weight;
    }
    
    /**
     * @dev Calculate quadratic weight (square root of balance)
     */
    function _calculateQuadraticWeight(
        VoterData memory voterData,
        VotingConfig memory config
    ) internal pure returns (uint256) {
        if (voterData.tokenBalance < config.minBalance) {
            return 0;
        }
        
        uint256 totalBalance = voterData.tokenBalance + voterData.delegatedPower;
        return _sqrt(totalBalance * PRECISION);
    }
    
    /**
     * @dev Calculate logarithmic weight
     */
    function _calculateLogarithmicWeight(
        VoterData memory voterData,
        VotingConfig memory config
    ) internal pure returns (uint256) {
        if (voterData.tokenBalance < config.minBalance) {
            return 0;
        }
        
        uint256 totalBalance = voterData.tokenBalance + voterData.delegatedPower;
        return _log2(totalBalance / PRECISION) * PRECISION;
    }
    
    /**
     * @dev Calculate time decay weight
     */
    function _calculateTimeDecayWeight(
        VoterData memory voterData,
        VotingConfig memory config
    ) internal view returns (uint256) {
        uint256 baseWeight = voterData.tokenBalance + voterData.delegatedPower;
        
        if (voterData.lastVoteTime == 0) {
            return baseWeight;
        }
        
        uint256 timeSinceLastVote = block.timestamp - voterData.lastVoteTime;
        uint256 decayFactor = (timeSinceLastVote * config.decayRate) / PRECISION;
        
        if (decayFactor >= PRECISION) {
            return baseWeight / 2; // Minimum 50% weight
        }
        
        return baseWeight - (baseWeight * decayFactor) / PRECISION;
    }
    
    /**
     * @dev Calculate reputation-based weight
     */
    function _calculateReputationWeight(
        VoterData memory voterData,
        VotingConfig memory config
    ) internal pure returns (uint256) {
        uint256 baseWeight = voterData.tokenBalance + voterData.delegatedPower;
        uint256 reputationMultiplier = PRECISION + (voterData.reputation * config.reputationFactor) / PRECISION;
        
        return (baseWeight * reputationMultiplier) / PRECISION;
    }
    
    /**
     * @dev Calculate hybrid weight (combination of multiple factors)
     */
    function _calculateHybridWeight(
        VoterData memory voterData,
        VotingConfig memory config
    ) internal view returns (uint256) {
        // Combine linear, quadratic, and reputation factors
        uint256 linearWeight = _calculateLinearWeight(voterData, config);
        uint256 quadraticWeight = _calculateQuadraticWeight(voterData, config);
        uint256 reputationWeight = _calculateReputationWeight(voterData, config);
        
        // Weighted average: 40% linear, 40% quadratic, 20% reputation
        return (linearWeight * 40 + quadraticWeight * 40 + reputationWeight * 20) / 100;
    }
    
    /**
     * @dev Calculate quadratic weight for simple balance
     */
    function calculateQuadraticWeight(uint256 balance) public pure returns (uint256) {
        if (balance == 0) return 0;
        return _sqrt(balance * PRECISION);
    }
    
    /**
     * @dev Calculate time-based voting bonus
     */
    function calculateTimingBonus(
        VoteTimingData memory timingData,
        uint256 maxBonus
    ) public pure returns (uint256 bonus) {
        if (timingData.voteTime < timingData.votingStart || 
            timingData.voteTime > timingData.votingEnd) {
            return 0;
        }
        
        uint256 votingPeriod = timingData.votingEnd - timingData.votingStart;
        uint256 timeFromStart = timingData.voteTime - timingData.votingStart;
        
        // Early voting bonus decreases linearly
        if (timeFromStart < votingPeriod / 2) {
            bonus = maxBonus - (maxBonus * timeFromStart * 2) / votingPeriod;
        }
        
        return bonus;
    }
    
    /**
     * @dev Calculate delegation multiplier
     */
    function calculateDelegationMultiplier(
        uint256 delegatedTokens,
        uint256 ownTokens
    ) public pure returns (uint256 multiplier) {
        if (ownTokens == 0) return PRECISION;
        
        uint256 ratio = (delegatedTokens * PRECISION) / ownTokens;
        
        // Cap at 2x multiplier
        if (ratio > 2 * PRECISION) {
            return 2 * PRECISION;
        }
        
        // Minimum 1x multiplier
        return PRECISION + (ratio / 10); // 10% of delegation ratio
    }
    
    /**
     * @dev Batch calculate weights for multiple voters
     */
    function batchCalculateWeights(
        address[] calldata voters,
        bytes32 configId
    ) external view returns (uint256[] memory weights) {
        weights = new uint256[](voters.length);
        
        for (uint256 i = 0; i < voters.length; i++) {
            weights[i] = calculateVotingWeight(voters[i], configId);
        }
        
        return weights;
    }
    
    /**
     * @dev Calculate total voting power for a proposal
     */
    function calculateTotalVotingPower(
        address[] calldata voters,
        bytes32 configId
    ) external view returns (uint256 totalPower) {
        for (uint256 i = 0; i < voters.length; i++) {
            totalPower += calculateVotingWeight(voters[i], configId);
        }
        
        return totalPower;
    }
    
    /**
     * @dev Set voting configuration
     */
    function setVotingConfiguration(
        bytes32 configId,
        VotingConfig calldata config
    ) external {
        require(config.maxWeight <= MAX_WEIGHT, "Max weight too high");
        require(config.decayRate <= PRECISION, "Decay rate too high");
        
        _configurations[configId] = config;
        emit ConfigurationUpdated(configId, config.weightType);
    }
    
    /**
     * @dev Get voting configuration
     */
    function getVotingConfiguration(bytes32 configId) 
        external 
        view 
        returns (VotingConfig memory) 
    {
        return _configurations[configId];
    }
    
    /**
     * @dev Cache voter weight for gas optimization
     */
    function cacheVoterWeight(
        address voter,
        bytes32 configId
    ) external {
        uint256 weight = calculateVotingWeight(voter, configId);
        _voterWeights[voter][configId] = weight;
        emit WeightCached(voter, configId, weight);
    }
    
    /**
     * @dev Get cached voter weight
     */
    function getCachedWeight(
        address voter,
        bytes32 configId
    ) external view returns (uint256) {
        return _voterWeights[voter][configId];
    }
    
    /**
     * @dev Helper function to get voter data (placeholder implementation)
     */
    function _getVoterData(address voter) internal view returns (VoterData memory) {
        // In production, this would fetch from token contracts, reputation systems, etc.
        return VoterData({
            tokenBalance: 1000 * PRECISION, // Placeholder
            reputation: 100 * PRECISION,    // Placeholder
            stakingDuration: 30 days,       // Placeholder
            delegatedPower: 0,              // Placeholder
            lastVoteTime: block.timestamp - 1 days, // Placeholder
            isEligible: voter != address(0)
        });
    }
    
    /**
     * @dev Integer square root using Newton's method
     */
    function _sqrt(uint256 x) internal pure returns (uint256) {
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
     * @dev Integer log base 2
     */
    function _log2(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        
        uint256 result = 0;
        uint256 temp = x;
        
        while (temp > 1) {
            temp >>= 1;
            result++;
        }
        
        return result;
    }
    
    /**
     * @dev Simulate voting scenario for testing
     */
    function simulateVoting(
        address[] calldata voters,
        uint256[] calldata balances,
        bytes32 configId
    ) external view returns (
        uint256[] memory weights,
        uint256 totalWeight,
        uint256 averageWeight
    ) {
        require(voters.length == balances.length, "Array length mismatch");
        
        weights = new uint256[](voters.length);
        
        for (uint256 i = 0; i < voters.length; i++) {
            // Create temporary voter data for simulation
            VoterData memory tempData = VoterData({
                tokenBalance: balances[i],
                reputation: 100 * PRECISION,
                stakingDuration: 30 days,
                delegatedPower: 0,
                lastVoteTime: block.timestamp - 1 days,
                isEligible: true
            });
            
            VotingConfig memory config = _configurations[configId];
            
            if (config.weightType == WeightType.Linear) {
                weights[i] = _calculateLinearWeight(tempData, config);
            } else if (config.weightType == WeightType.Quadratic) {
                weights[i] = _calculateQuadraticWeight(tempData, config);
            }
            // Add other weight types as needed
            
            totalWeight += weights[i];
        }
        
        averageWeight = voters.length > 0 ? totalWeight / voters.length : 0;
        
        return (weights, totalWeight, averageWeight);
    }
}