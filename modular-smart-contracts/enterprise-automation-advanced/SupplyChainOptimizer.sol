// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SupplyChainOptimizer - Advanced Supply Chain Management
 * @dev Optimizes supply chain operations using AI and automation
 */

contract SupplyChainOptimizer {
    struct SupplyChainItem {
        uint256 itemId;
        string name;
        address manufacturer;
        address currentOwner;
        uint256[] locationHistory;
        uint256 status; // 0: manufacturing, 1: in transit, 2: delivered
        uint256 creationTime;
    }
    
    struct Location {
        uint256 locationId;
        string name;
        int256 latitude;
        int256 longitude;
        address operator;
    }
    
    mapping(uint256 => SupplyChainItem) public items;
    mapping(uint256 => Location) public locations;
    uint256 public nextItemId;
    uint256 public nextLocationId;
    
    event ItemCreated(uint256 indexed itemId, address manufacturer);
    event ItemMoved(uint256 indexed itemId, uint256 locationId);
    event ItemDelivered(uint256 indexed itemId, address recipient);
    
    function createItem(string calldata name) external returns (uint256 itemId) {
        itemId = nextItemId++;
        
        items[itemId] = SupplyChainItem({
            itemId: itemId,
            name: name,
            manufacturer: msg.sender,
            currentOwner: msg.sender,
            locationHistory: new uint256[](0),
            status: 0,
            creationTime: block.timestamp
        });
        
        emit ItemCreated(itemId, msg.sender);
        return itemId;
    }
    
    function moveItem(uint256 itemId, uint256 locationId, address newOwner) external {
        SupplyChainItem storage item = items[itemId];
        require(item.currentOwner == msg.sender, "Not current owner");
        
        item.locationHistory.push(locationId);
        item.currentOwner = newOwner;
        item.status = 1;
        
        emit ItemMoved(itemId, locationId);
    }
    
    function deliverItem(uint256 itemId) external {
        SupplyChainItem storage item = items[itemId];
        require(item.currentOwner == msg.sender, "Not current owner");
        
        item.status = 2;
        emit ItemDelivered(itemId, msg.sender);
    }
}