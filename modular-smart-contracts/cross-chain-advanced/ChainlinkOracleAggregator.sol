// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ChainlinkOracleAggregator - Multi-Chain Oracle Data Aggregation
 * @dev Aggregates oracle data from multiple blockchain networks
 */

contract ChainlinkOracleAggregator {
    struct OracleData {
        uint256 dataId;
        uint256 sourceChain;
        int256 value;
        uint256 timestamp;
        uint256 confidence;
        address oracle;
    }
    
    mapping(bytes32 => OracleData[]) public oracleFeeds;
    mapping(bytes32 => int256) public aggregatedValues;
    
    event DataSubmitted(bytes32 indexed feedId, uint256 sourceChain, int256 value);
    event DataAggregated(bytes32 indexed feedId, int256 aggregatedValue);
    
    function submitOracleData(
        bytes32 feedId,
        uint256 sourceChain,
        int256 value,
        uint256 confidence
    ) external {
        oracleFeeds[feedId].push(OracleData({
            dataId: oracleFeeds[feedId].length,
            sourceChain: sourceChain,
            value: value,
            timestamp: block.timestamp,
            confidence: confidence,
            oracle: msg.sender
        }));
        
        emit DataSubmitted(feedId, sourceChain, value);
    }
    
    function aggregateData(bytes32 feedId) external returns (int256 aggregatedValue) {
        OracleData[] storage feed = oracleFeeds[feedId];
        require(feed.length > 0, "No data available");
        
        int256 weightedSum = 0;
        uint256 totalWeight = 0;
        
        for (uint256 i = 0; i < feed.length; i++) {
            weightedSum += feed[i].value * int256(feed[i].confidence);
            totalWeight += feed[i].confidence;
        }
        
        aggregatedValue = weightedSum / int256(totalWeight);
        aggregatedValues[feedId] = aggregatedValue;
        
        emit DataAggregated(feedId, aggregatedValue);
        return aggregatedValue;
    }
}