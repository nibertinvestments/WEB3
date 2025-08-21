// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PriorityQueue - Advanced Heap-Based Priority Queue
 * @dev High-performance priority queue with sophisticated operations
 * 
 * FEATURES:
 * - Min-heap and max-heap implementations
 * - Dynamic priority updates
 * - Efficient insertion and extraction
 * - Custom comparison functions
 * - Batch operations for gas optimization
 * 
 * USE CASES:
 * 1. Order book management with price priorities
 * 2. Transaction fee bidding systems
 * 3. Task scheduling with urgency levels
 * 4. Liquidity provision optimization
 * 5. Automated liquidation queues
 * 6. Governance proposal prioritization
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library PriorityQueue {
    enum QueueType {
        MIN_HEAP,
        MAX_HEAP
    }
    
    struct Element {
        uint256 priority;
        uint256 value;
        address owner;
        uint256 timestamp;
        bool exists;
    }
    
    struct Queue {
        Element[] elements;
        QueueType queueType;
        mapping(uint256 => uint256) valueToIndex; // For O(log n) updates
        uint256 size;
    }
    
    // Events for monitoring queue operations
    event ElementInserted(uint256 indexed value, uint256 priority, address owner);
    event ElementExtracted(uint256 indexed value, uint256 priority, address owner);
    event PriorityUpdated(uint256 indexed value, uint256 oldPriority, uint256 newPriority);
    event QueueCleared();
    
    /**
     * @dev Initializes a new priority queue
     * Use Case: Setting up order books, task queues
     */
    function initialize(Queue storage queue, QueueType queueType) internal {
        queue.queueType = queueType;
        queue.size = 0;
        // Add dummy element at index 0 for 1-based indexing
        queue.elements.push(Element(0, 0, address(0), 0, false));
    }
    
    /**
     * @dev Inserts an element with given priority
     * Use Case: Adding orders, scheduling tasks
     */
    function insert(
        Queue storage queue,
        uint256 value,
        uint256 priority,
        address owner
    ) internal {
        require(!queue.valueToIndex[value] != 0, "PriorityQueue: value already exists");
        
        Element memory newElement = Element({
            priority: priority,
            value: value,
            owner: owner,
            timestamp: block.timestamp,
            exists: true
        });
        
        queue.elements.push(newElement);
        queue.size++;
        uint256 index = queue.size;
        queue.valueToIndex[value] = index;
        
        _heapifyUp(queue, index);
        
        emit ElementInserted(value, priority, owner);
    }
    
    /**
     * @dev Extracts the highest priority element
     * Use Case: Processing orders, executing tasks
     */
    function extractTop(Queue storage queue) 
        internal returns (uint256 value, uint256 priority, address owner) {
        require(queue.size > 0, "PriorityQueue: empty queue");
        
        Element storage topElement = queue.elements[1];
        value = topElement.value;
        priority = topElement.priority;
        owner = topElement.owner;
        
        emit ElementExtracted(value, priority, owner);
        
        // Move last element to top
        queue.elements[1] = queue.elements[queue.size];
        queue.valueToIndex[queue.elements[1].value] = 1;
        
        // Remove the last element
        delete queue.valueToIndex[value];
        queue.elements.pop();
        queue.size--;
        
        if (queue.size > 0) {
            _heapifyDown(queue, 1);
        }
    }
    
    /**
     * @dev Peeks at the highest priority element without removing
     * Use Case: Checking next order, previewing tasks
     */
    function peek(Queue storage queue) 
        internal view returns (uint256 value, uint256 priority, address owner) {
        require(queue.size > 0, "PriorityQueue: empty queue");
        
        Element storage topElement = queue.elements[1];
        value = topElement.value;
        priority = topElement.priority;
        owner = topElement.owner;
    }
    
    /**
     * @dev Updates the priority of an existing element
     * Use Case: Updating order prices, changing task urgency
     */
    function updatePriority(
        Queue storage queue,
        uint256 value,
        uint256 newPriority
    ) internal {
        uint256 index = queue.valueToIndex[value];
        require(index > 0, "PriorityQueue: value not found");
        
        uint256 oldPriority = queue.elements[index].priority;
        queue.elements[index].priority = newPriority;
        
        emit PriorityUpdated(value, oldPriority, newPriority);
        
        // Determine direction to heapify
        bool shouldGoUp = (queue.queueType == QueueType.MIN_HEAP && newPriority < oldPriority) ||
                         (queue.queueType == QueueType.MAX_HEAP && newPriority > oldPriority);
        
        if (shouldGoUp) {
            _heapifyUp(queue, index);
        } else {
            _heapifyDown(queue, index);
        }
    }
    
    /**
     * @dev Removes a specific element from the queue
     * Use Case: Canceling orders, removing tasks
     */
    function remove(Queue storage queue, uint256 value) 
        internal returns (uint256 priority, address owner) {
        uint256 index = queue.valueToIndex[value];
        require(index > 0, "PriorityQueue: value not found");
        
        Element storage element = queue.elements[index];
        priority = element.priority;
        owner = element.owner;
        
        // Move last element to this position
        queue.elements[index] = queue.elements[queue.size];
        queue.valueToIndex[queue.elements[index].value] = index;
        
        // Remove the last element
        delete queue.valueToIndex[value];
        queue.elements.pop();
        queue.size--;
        
        if (queue.size > 0 && index <= queue.size) {
            // Heapify in both directions to maintain heap property
            _heapifyUp(queue, index);
            _heapifyDown(queue, index);
        }
    }
    
    /**
     * @dev Batch insert multiple elements
     * Use Case: Bulk order placement, mass task scheduling
     */
    function batchInsert(
        Queue storage queue,
        uint256[] memory values,
        uint256[] memory priorities,
        address[] memory owners
    ) internal {
        require(
            values.length == priorities.length && 
            priorities.length == owners.length,
            "PriorityQueue: array length mismatch"
        );
        
        for (uint256 i = 0; i < values.length; i++) {
            insert(queue, values[i], priorities[i], owners[i]);
        }
    }
    
    /**
     * @dev Extracts multiple top elements
     * Use Case: Batch order execution, multi-task processing
     */
    function extractMultiple(Queue storage queue, uint256 count) 
        internal returns (
            uint256[] memory values,
            uint256[] memory priorities,
            address[] memory owners
        ) {
        require(count <= queue.size, "PriorityQueue: not enough elements");
        
        values = new uint256[](count);
        priorities = new uint256[](count);
        owners = new address[](count);
        
        for (uint256 i = 0; i < count; i++) {
            (values[i], priorities[i], owners[i]) = extractTop(queue);
        }
    }
    
    /**
     * @dev Merges two priority queues
     * Use Case: Combining order books, merging task queues
     */
    function merge(Queue storage queue1, Queue storage queue2) internal {
        require(queue1.queueType == queue2.queueType, "PriorityQueue: incompatible queue types");
        
        // Extract all elements from queue2 and insert into queue1
        while (queue2.size > 0) {
            (uint256 value, uint256 priority, address owner) = extractTop(queue2);
            insert(queue1, value, priority, owner);
        }
    }
    
    /**
     * @dev Filters queue elements based on criteria
     * Use Case: Conditional processing, selective extraction
     */
    function filter(
        Queue storage queue,
        function(uint256, uint256, address) internal pure returns (bool) predicate
    ) internal view returns (
        uint256[] memory values,
        uint256[] memory priorities,
        address[] memory owners
    ) {
        uint256[] memory tempValues = new uint256[](queue.size);
        uint256[] memory tempPriorities = new uint256[](queue.size);
        address[] memory tempOwners = new address[](queue.size);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= queue.size; i++) {
            Element storage element = queue.elements[i];
            if (predicate(element.value, element.priority, element.owner)) {
                tempValues[count] = element.value;
                tempPriorities[count] = element.priority;
                tempOwners[count] = element.owner;
                count++;
            }
        }
        
        values = new uint256[](count);
        priorities = new uint256[](count);
        owners = new address[](count);
        
        for (uint256 i = 0; i < count; i++) {
            values[i] = tempValues[i];
            priorities[i] = tempPriorities[i];
            owners[i] = tempOwners[i];
        }
    }
    
    /**
     * @dev Gets queue statistics
     * Use Case: Analytics, monitoring
     */
    function getStats(Queue storage queue) 
        internal view returns (
            uint256 size,
            uint256 minPriority,
            uint256 maxPriority,
            uint256 avgPriority
        ) {
        size = queue.size;
        
        if (size == 0) {
            return (0, 0, 0, 0);
        }
        
        minPriority = type(uint256).max;
        maxPriority = 0;
        uint256 totalPriority = 0;
        
        for (uint256 i = 1; i <= size; i++) {
            uint256 priority = queue.elements[i].priority;
            if (priority < minPriority) minPriority = priority;
            if (priority > maxPriority) maxPriority = priority;
            totalPriority += priority;
        }
        
        avgPriority = totalPriority / size;
    }
    
    /**
     * @dev Checks if queue is empty
     * Use Case: Conditional logic, validation
     */
    function isEmpty(Queue storage queue) internal view returns (bool) {
        return queue.size == 0;
    }
    
    /**
     * @dev Gets current queue size
     * Use Case: Size queries, capacity planning
     */
    function size(Queue storage queue) internal view returns (uint256) {
        return queue.size;
    }
    
    /**
     * @dev Clears all elements from queue
     * Use Case: Reset operations, cleanup
     */
    function clear(Queue storage queue) internal {
        for (uint256 i = 1; i <= queue.size; i++) {
            delete queue.valueToIndex[queue.elements[i].value];
        }
        
        // Keep the dummy element at index 0
        while (queue.elements.length > 1) {
            queue.elements.pop();
        }
        
        queue.size = 0;
        emit QueueCleared();
    }
    
    // Internal helper functions
    
    function _heapifyUp(Queue storage queue, uint256 index) private {
        while (index > 1) {
            uint256 parentIndex = index / 2;
            
            if (!_shouldSwap(queue, index, parentIndex)) {
                break;
            }
            
            _swap(queue, index, parentIndex);
            index = parentIndex;
        }
    }
    
    function _heapifyDown(Queue storage queue, uint256 index) private {
        while (index * 2 <= queue.size) {
            uint256 childIndex = _getBestChild(queue, index);
            
            if (!_shouldSwap(queue, childIndex, index)) {
                break;
            }
            
            _swap(queue, index, childIndex);
            index = childIndex;
        }
    }
    
    function _getBestChild(Queue storage queue, uint256 index) 
        private view returns (uint256) {
        uint256 leftChild = index * 2;
        uint256 rightChild = index * 2 + 1;
        
        if (rightChild > queue.size) {
            return leftChild;
        }
        
        if (_shouldSwap(queue, leftChild, rightChild)) {
            return leftChild;
        } else {
            return rightChild;
        }
    }
    
    function _shouldSwap(Queue storage queue, uint256 index1, uint256 index2) 
        private view returns (bool) {
        uint256 priority1 = queue.elements[index1].priority;
        uint256 priority2 = queue.elements[index2].priority;
        
        if (queue.queueType == QueueType.MIN_HEAP) {
            return priority1 < priority2;
        } else {
            return priority1 > priority2;
        }
    }
    
    function _swap(Queue storage queue, uint256 index1, uint256 index2) private {
        Element storage element1 = queue.elements[index1];
        Element storage element2 = queue.elements[index2];
        
        // Update index mappings
        queue.valueToIndex[element1.value] = index2;
        queue.valueToIndex[element2.value] = index1;
        
        // Swap elements
        Element memory temp = element1;
        queue.elements[index1] = element2;
        queue.elements[index2] = temp;
    }
}