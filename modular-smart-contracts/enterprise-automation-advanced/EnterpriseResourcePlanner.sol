// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title EnterpriseResourcePlanner - ERP System on Blockchain
 * @dev Comprehensive enterprise resource planning system
 */

contract EnterpriseResourcePlanner {
    struct Resource {
        uint256 resourceId;
        string name;
        uint256 quantity;
        uint256 costPerUnit;
        address supplier;
        uint256 reorderLevel;
        bool isActive;
    }
    
    struct Order {
        uint256 orderId;
        uint256 resourceId;
        uint256 quantity;
        address requester;
        uint256 status; // 0: pending, 1: approved, 2: fulfilled
        uint256 orderTime;
    }
    
    mapping(uint256 => Resource) public resources;
    mapping(uint256 => Order) public orders;
    uint256 public nextResourceId;
    uint256 public nextOrderId;
    
    event ResourceAdded(uint256 indexed resourceId, string name);
    event OrderCreated(uint256 indexed orderId, uint256 resourceId);
    event OrderFulfilled(uint256 indexed orderId);
    
    function addResource(
        string calldata name,
        uint256 quantity,
        uint256 costPerUnit,
        address supplier,
        uint256 reorderLevel
    ) external returns (uint256 resourceId) {
        resourceId = nextResourceId++;
        
        resources[resourceId] = Resource({
            resourceId: resourceId,
            name: name,
            quantity: quantity,
            costPerUnit: costPerUnit,
            supplier: supplier,
            reorderLevel: reorderLevel,
            isActive: true
        });
        
        emit ResourceAdded(resourceId, name);
        return resourceId;
    }
    
    function createOrder(uint256 resourceId, uint256 quantity) external returns (uint256 orderId) {
        require(resources[resourceId].isActive, "Resource not active");
        
        orderId = nextOrderId++;
        
        orders[orderId] = Order({
            orderId: orderId,
            resourceId: resourceId,
            quantity: quantity,
            requester: msg.sender,
            status: 0,
            orderTime: block.timestamp
        });
        
        emit OrderCreated(orderId, resourceId);
        return orderId;
    }
    
    function fulfillOrder(uint256 orderId) external {
        Order storage order = orders[orderId];
        require(order.status == 1, "Order not approved");
        
        Resource storage resource = resources[order.resourceId];
        require(resource.quantity >= order.quantity, "Insufficient quantity");
        
        resource.quantity -= order.quantity;
        order.status = 2;
        
        emit OrderFulfilled(orderId);
    }
}