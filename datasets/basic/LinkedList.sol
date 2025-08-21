// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title LinkedList - Advanced Doubly Linked List Implementation
 * @dev High-performance linked list with sophisticated operations
 * 
 * FEATURES:
 * - Doubly linked structure for bidirectional traversal
 * - Efficient insertion and deletion operations
 * - Iterator patterns for safe traversal
 * - Sorted insertion and search capabilities
 * - Memory-efficient node management
 * 
 * USE CASES:
 * 1. Order book management for trading systems
 * 2. Priority queue implementations
 * 3. Transaction history with frequent insertions
 * 4. Token holder lists with dynamic membership
 * 5. Event logging with chronological ordering
 * 6. Cache implementations with LRU eviction
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library LinkedList {
    struct Node {
        uint256 value;
        address next;
        address prev;
        bool exists;
    }
    
    struct List {
        address head;
        address tail;
        uint256 length;
        mapping(address => Node) nodes;
        mapping(uint256 => address) valueToNode; // For O(1) value lookup
    }
    
    // Events for monitoring list operations
    event NodeInserted(address indexed nodeId, uint256 value, uint256 position);
    event NodeRemoved(address indexed nodeId, uint256 value);
    event ListCleared();
    
    /**
     * @dev Inserts a new node at the head of the list
     * Use Case: Most recent transactions, latest events
     */
    function insertHead(List storage list, address nodeId, uint256 value) internal {
        require(!list.nodes[nodeId].exists, "LinkedList: node already exists");
        
        Node storage newNode = list.nodes[nodeId];
        newNode.value = value;
        newNode.exists = true;
        newNode.next = list.head;
        newNode.prev = address(0);
        
        if (list.head != address(0)) {
            list.nodes[list.head].prev = nodeId;
        } else {
            list.tail = nodeId;
        }
        
        list.head = nodeId;
        list.length++;
        list.valueToNode[value] = nodeId;
        
        emit NodeInserted(nodeId, value, 0);
    }
    
    /**
     * @dev Inserts a new node at the tail of the list
     * Use Case: Maintaining chronological order, append operations
     */
    function insertTail(List storage list, address nodeId, uint256 value) internal {
        require(!list.nodes[nodeId].exists, "LinkedList: node already exists");
        
        Node storage newNode = list.nodes[nodeId];
        newNode.value = value;
        newNode.exists = true;
        newNode.next = address(0);
        newNode.prev = list.tail;
        
        if (list.tail != address(0)) {
            list.nodes[list.tail].next = nodeId;
        } else {
            list.head = nodeId;
        }
        
        list.tail = nodeId;
        list.length++;
        list.valueToNode[value] = nodeId;
        
        emit NodeInserted(nodeId, value, list.length - 1);
    }
    
    /**
     * @dev Inserts a node in sorted order (ascending)
     * Use Case: Maintaining sorted lists, price levels in order books
     */
    function insertSorted(List storage list, address nodeId, uint256 value) internal {
        require(!list.nodes[nodeId].exists, "LinkedList: node already exists");
        
        if (list.length == 0 || value <= list.nodes[list.head].value) {
            insertHead(list, nodeId, value);
            return;
        }
        
        if (value >= list.nodes[list.tail].value) {
            insertTail(list, nodeId, value);
            return;
        }
        
        // Find insertion position
        address current = list.head;
        uint256 position = 0;
        
        while (current != address(0) && list.nodes[current].value < value) {
            current = list.nodes[current].next;
            position++;
        }
        
        // Insert before current
        Node storage newNode = list.nodes[nodeId];
        newNode.value = value;
        newNode.exists = true;
        newNode.next = current;
        newNode.prev = list.nodes[current].prev;
        
        list.nodes[list.nodes[current].prev].next = nodeId;
        list.nodes[current].prev = nodeId;
        
        list.length++;
        list.valueToNode[value] = nodeId;
        
        emit NodeInserted(nodeId, value, position);
    }
    
    /**
     * @dev Removes a node from the list
     * Use Case: Removing completed orders, expired entries
     */
    function remove(List storage list, address nodeId) internal returns (uint256 value) {
        require(list.nodes[nodeId].exists, "LinkedList: node does not exist");
        
        Node storage node = list.nodes[nodeId];
        value = node.value;
        
        // Update links
        if (node.prev != address(0)) {
            list.nodes[node.prev].next = node.next;
        } else {
            list.head = node.next;
        }
        
        if (node.next != address(0)) {
            list.nodes[node.next].prev = node.prev;
        } else {
            list.tail = node.prev;
        }
        
        // Clean up node
        delete list.nodes[nodeId];
        delete list.valueToNode[value];
        list.length--;
        
        emit NodeRemoved(nodeId, value);
    }
    
    /**
     * @dev Removes and returns the head node
     * Use Case: Queue operations, processing oldest items
     */
    function removeHead(List storage list) internal returns (address nodeId, uint256 value) {
        require(list.length > 0, "LinkedList: empty list");
        
        nodeId = list.head;
        value = remove(list, nodeId);
    }
    
    /**
     * @dev Removes and returns the tail node
     * Use Case: Stack operations, processing newest items
     */
    function removeTail(List storage list) internal returns (address nodeId, uint256 value) {
        require(list.length > 0, "LinkedList: empty list");
        
        nodeId = list.tail;
        value = remove(list, nodeId);
    }
    
    /**
     * @dev Finds a node by value
     * Use Case: Value-based lookups, search operations
     */
    function findByValue(List storage list, uint256 value) 
        internal view returns (address nodeId, bool exists) {
        nodeId = list.valueToNode[value];
        exists = list.nodes[nodeId].exists;
    }
    
    /**
     * @dev Gets the value at a specific position
     * Use Case: Indexed access, position-based queries
     */
    function getAtPosition(List storage list, uint256 position) 
        internal view returns (address nodeId, uint256 value) {
        require(position < list.length, "LinkedList: position out of bounds");
        
        nodeId = list.head;
        for (uint256 i = 0; i < position; i++) {
            nodeId = list.nodes[nodeId].next;
        }
        
        value = list.nodes[nodeId].value;
    }
    
    /**
     * @dev Converts list to array
     * Use Case: Batch processing, external interface
     */
    function toArray(List storage list) internal view returns (uint256[] memory values) {
        values = new uint256[](list.length);
        
        address current = list.head;
        for (uint256 i = 0; i < list.length; i++) {
            values[i] = list.nodes[current].value;
            current = list.nodes[current].next;
        }
    }
    
    /**
     * @dev Converts list to array in reverse order
     * Use Case: Reverse chronological processing
     */
    function toArrayReverse(List storage list) internal view returns (uint256[] memory values) {
        values = new uint256[](list.length);
        
        address current = list.tail;
        for (uint256 i = 0; i < list.length; i++) {
            values[i] = list.nodes[current].value;
            current = list.nodes[current].prev;
        }
    }
    
    /**
     * @dev Merges two sorted lists
     * Use Case: Combining order books, merging data streams
     */
    function mergeSorted(
        List storage list1,
        List storage list2
    ) internal returns (List storage mergedList) {
        require(list1.length == 0, "LinkedList: first list must be empty for merge");
        
        address current1 = list1.head;
        address current2 = list2.head;
        uint256 nodeCounter = 0;
        
        while (current1 != address(0) && current2 != address(0)) {
            address newNodeId = address(uint160(uint256(keccak256(abi.encode(nodeCounter++)))));
            
            if (list1.nodes[current1].value <= list2.nodes[current2].value) {
                insertTail(list1, newNodeId, list1.nodes[current1].value);
                current1 = list1.nodes[current1].next;
            } else {
                insertTail(list1, newNodeId, list2.nodes[current2].value);
                current2 = list2.nodes[current2].next;
            }
        }
        
        // Add remaining nodes
        while (current1 != address(0)) {
            address newNodeId = address(uint160(uint256(keccak256(abi.encode(nodeCounter++)))));
            insertTail(list1, newNodeId, list1.nodes[current1].value);
            current1 = list1.nodes[current1].next;
        }
        
        while (current2 != address(0)) {
            address newNodeId = address(uint160(uint256(keccak256(abi.encode(nodeCounter++)))));
            insertTail(list1, newNodeId, list2.nodes[current2].value);
            current2 = list2.nodes[current2].next;
        }
        
        return list1;
    }
    
    /**
     * @dev Filters list based on predicate
     * Use Case: Conditional processing, data filtering
     */
    function filter(
        List storage list,
        function(uint256) internal pure returns (bool) predicate
    ) internal view returns (uint256[] memory filteredValues) {
        uint256[] memory tempValues = new uint256[](list.length);
        uint256 count = 0;
        
        address current = list.head;
        while (current != address(0)) {
            uint256 value = list.nodes[current].value;
            if (predicate(value)) {
                tempValues[count++] = value;
            }
            current = list.nodes[current].next;
        }
        
        filteredValues = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredValues[i] = tempValues[i];
        }
    }
    
    /**
     * @dev Reverses the list
     * Use Case: Order reversal, stack conversion
     */
    function reverse(List storage list) internal {
        if (list.length <= 1) return;
        
        address current = list.head;
        list.head = list.tail;
        list.tail = current;
        
        while (current != address(0)) {
            address next = list.nodes[current].next;
            list.nodes[current].next = list.nodes[current].prev;
            list.nodes[current].prev = next;
            current = next;
        }
    }
    
    /**
     * @dev Clears all nodes from the list
     * Use Case: Reset operations, cleanup
     */
    function clear(List storage list) internal {
        address current = list.head;
        
        while (current != address(0)) {
            address next = list.nodes[current].next;
            uint256 value = list.nodes[current].value;
            delete list.nodes[current];
            delete list.valueToNode[value];
            current = next;
        }
        
        list.head = address(0);
        list.tail = address(0);
        list.length = 0;
        
        emit ListCleared();
    }
    
    /**
     * @dev Gets list statistics
     * Use Case: Analytics, monitoring
     */
    function getStats(List storage list) 
        internal view returns (uint256 length, uint256 minValue, uint256 maxValue) {
        length = list.length;
        
        if (length == 0) {
            return (0, 0, 0);
        }
        
        minValue = type(uint256).max;
        maxValue = 0;
        
        address current = list.head;
        while (current != address(0)) {
            uint256 value = list.nodes[current].value;
            if (value < minValue) minValue = value;
            if (value > maxValue) maxValue = value;
            current = list.nodes[current].next;
        }
    }
    
    /**
     * @dev Checks if list is sorted
     * Use Case: Validation, integrity checking
     */
    function isSorted(List storage list) internal view returns (bool) {
        if (list.length <= 1) return true;
        
        address current = list.head;
        while (list.nodes[current].next != address(0)) {
            address next = list.nodes[current].next;
            if (list.nodes[current].value > list.nodes[next].value) {
                return false;
            }
            current = next;
        }
        
        return true;
    }
    
    /**
     * @dev Gets list length
     * Use Case: Size queries, validation
     */
    function length(List storage list) internal view returns (uint256) {
        return list.length;
    }
    
    /**
     * @dev Checks if list is empty
     * Use Case: Conditional logic, validation
     */
    function isEmpty(List storage list) internal view returns (bool) {
        return list.length == 0;
    }
}