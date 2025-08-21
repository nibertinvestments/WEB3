// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DynamicArray - Advanced Resizable Array Implementation
 * @dev High-performance dynamic array with sophisticated memory management
 * 
 * FEATURES:
 * - Automatic resizing with configurable growth factors
 * - Memory-efficient storage and retrieval
 * - Batch operations for gas optimization
 * - Iterator patterns for safe traversal
 * - Advanced search and sort capabilities
 * 
 * USE CASES:
 * 1. Token holder lists with dynamic membership
 * 2. Transaction history with unlimited growth
 * 3. Portfolio asset tracking with additions/removals
 * 4. Voting records with expanding participant lists
 * 5. Price history with continuous data collection
 * 6. Event logging with efficient storage
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library DynamicArray {
    struct Array {
        uint256[] data;
        uint256 length;
        uint256 capacity;
        uint256 growthFactor; // Percentage growth (e.g., 150 = 1.5x growth)
    }
    
    // Events for monitoring array operations
    event ArrayResized(uint256 oldCapacity, uint256 newCapacity);
    event ElementAdded(uint256 index, uint256 value);
    event ElementRemoved(uint256 index, uint256 value);
    event ArrayCleared();
    
    /**
     * @dev Initializes a new dynamic array
     * Use Case: Setting up new data collections
     */
    function initialize(Array storage self, uint256 initialCapacity) internal {
        self.data = new uint256[](initialCapacity);
        self.length = 0;
        self.capacity = initialCapacity;
        self.growthFactor = 150; // 50% growth by default
    }
    
    /**
     * @dev Adds element to the end of array
     * Use Case: Appending new data points, expanding collections
     */
    function push(Array storage self, uint256 value) internal {
        if (self.length >= self.capacity) {
            _resize(self);
        }
        
        self.data[self.length] = value;
        self.length++;
        
        emit ElementAdded(self.length - 1, value);
    }
    
    /**
     * @dev Removes and returns the last element
     * Use Case: Stack operations, removing recent entries
     */
    function pop(Array storage self) internal returns (uint256) {
        require(self.length > 0, "DynamicArray: empty array");
        
        self.length--;
        uint256 value = self.data[self.length];
        
        emit ElementRemoved(self.length, value);
        return value;
    }
    
    /**
     * @dev Gets element at specified index
     * Use Case: Random access to array elements
     */
    function get(Array storage self, uint256 index) internal view returns (uint256) {
        require(index < self.length, "DynamicArray: index out of bounds");
        return self.data[index];
    }
    
    /**
     * @dev Sets element at specified index
     * Use Case: Updating existing data points
     */
    function set(Array storage self, uint256 index, uint256 value) internal {
        require(index < self.length, "DynamicArray: index out of bounds");
        uint256 oldValue = self.data[index];
        self.data[index] = value;
        
        emit ElementRemoved(index, oldValue);
        emit ElementAdded(index, value);
    }
    
    /**
     * @dev Inserts element at specified index
     * Use Case: Inserting data while maintaining order
     */
    function insert(Array storage self, uint256 index, uint256 value) internal {
        require(index <= self.length, "DynamicArray: index out of bounds");
        
        if (self.length >= self.capacity) {
            _resize(self);
        }
        
        // Shift elements to the right
        for (uint256 i = self.length; i > index; i--) {
            self.data[i] = self.data[i - 1];
        }
        
        self.data[index] = value;
        self.length++;
        
        emit ElementAdded(index, value);
    }
    
    /**
     * @dev Removes element at specified index
     * Use Case: Removing specific data points while maintaining order
     */
    function removeAt(Array storage self, uint256 index) internal returns (uint256) {
        require(index < self.length, "DynamicArray: index out of bounds");
        
        uint256 value = self.data[index];
        
        // Shift elements to the left
        for (uint256 i = index; i < self.length - 1; i++) {
            self.data[i] = self.data[i + 1];
        }
        
        self.length--;
        emit ElementRemoved(index, value);
        return value;
    }
    
    /**
     * @dev Finds first occurrence of value
     * Use Case: Searching for specific data points
     */
    function indexOf(Array storage self, uint256 value) internal view returns (int256) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self.data[i] == value) {
                return int256(i);
            }
        }
        return -1;
    }
    
    /**
     * @dev Checks if array contains value
     * Use Case: Membership testing, validation
     */
    function contains(Array storage self, uint256 value) internal view returns (bool) {
        return indexOf(self, value) >= 0;
    }
    
    /**
     * @dev Returns current length of array
     * Use Case: Size checking, iteration bounds
     */
    function size(Array storage self) internal view returns (uint256) {
        return self.length;
    }
    
    /**
     * @dev Checks if array is empty
     * Use Case: Validation, conditional logic
     */
    function isEmpty(Array storage self) internal view returns (bool) {
        return self.length == 0;
    }
    
    /**
     * @dev Clears all elements from array
     * Use Case: Resetting collections, cleanup operations
     */
    function clear(Array storage self) internal {
        self.length = 0;
        emit ArrayCleared();
    }
    
    /**
     * @dev Returns a copy of array as fixed-size array
     * Use Case: Converting to standard array format
     */
    function toArray(Array storage self) internal view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](self.length);
        for (uint256 i = 0; i < self.length; i++) {
            result[i] = self.data[i];
        }
        return result;
    }
    
    /**
     * @dev Adds multiple elements in batch
     * Use Case: Bulk data insertion, gas optimization
     */
    function pushBatch(Array storage self, uint256[] memory values) internal {
        uint256 requiredCapacity = self.length + values.length;
        
        // Resize if necessary
        while (self.capacity < requiredCapacity) {
            _resize(self);
        }
        
        for (uint256 i = 0; i < values.length; i++) {
            self.data[self.length + i] = values[i];
            emit ElementAdded(self.length + i, values[i]);
        }
        
        self.length += values.length;
    }
    
    /**
     * @dev Removes all occurrences of value
     * Use Case: Data cleaning, removing duplicates
     */
    function removeAll(Array storage self, uint256 value) internal returns (uint256) {
        uint256 removedCount = 0;
        uint256 writeIndex = 0;
        
        for (uint256 readIndex = 0; readIndex < self.length; readIndex++) {
            if (self.data[readIndex] != value) {
                if (writeIndex != readIndex) {
                    self.data[writeIndex] = self.data[readIndex];
                }
                writeIndex++;
            } else {
                removedCount++;
                emit ElementRemoved(readIndex, value);
            }
        }
        
        self.length = writeIndex;
        return removedCount;
    }
    
    /**
     * @dev Sorts array in ascending order
     * Use Case: Data organization, ordered processing
     */
    function sort(Array storage self) internal {
        if (self.length <= 1) return;
        
        _quickSort(self, 0, int256(self.length - 1));
    }
    
    /**
     * @dev Reverses array order
     * Use Case: Data transformation, reverse chronological order
     */
    function reverse(Array storage self) internal {
        if (self.length <= 1) return;
        
        uint256 start = 0;
        uint256 end = self.length - 1;
        
        while (start < end) {
            (self.data[start], self.data[end]) = (self.data[end], self.data[start]);
            start++;
            end--;
        }
    }
    
    /**
     * @dev Internal function to resize array capacity
     * Use Case: Automatic memory management
     */
    function _resize(Array storage self) private {
        uint256 oldCapacity = self.capacity;
        uint256 newCapacity = (self.capacity * self.growthFactor) / 100;
        
        if (newCapacity <= oldCapacity) {
            newCapacity = oldCapacity + 1; // Minimum growth
        }
        
        uint256[] memory newData = new uint256[](newCapacity);
        
        for (uint256 i = 0; i < self.length; i++) {
            newData[i] = self.data[i];
        }
        
        self.data = newData;
        self.capacity = newCapacity;
        
        emit ArrayResized(oldCapacity, newCapacity);
    }
    
    /**
     * @dev Internal quicksort implementation
     * Use Case: Efficient sorting algorithm
     */
    function _quickSort(Array storage self, int256 left, int256 right) private {
        if (left < right) {
            int256 pivotIndex = _partition(self, left, right);
            _quickSort(self, left, pivotIndex - 1);
            _quickSort(self, pivotIndex + 1, right);
        }
    }
    
    /**
     * @dev Partition function for quicksort
     * Use Case: Internal sorting helper
     */
    function _partition(Array storage self, int256 left, int256 right) 
        private returns (int256) {
        uint256 pivot = self.data[uint256(right)];
        int256 i = left - 1;
        
        for (int256 j = left; j < right; j++) {
            if (self.data[uint256(j)] <= pivot) {
                i++;
                (self.data[uint256(i)], self.data[uint256(j)]) = 
                (self.data[uint256(j)], self.data[uint256(i)]);
            }
        }
        
        (self.data[uint256(i + 1)], self.data[uint256(right)]) = 
        (self.data[uint256(right)], self.data[uint256(i + 1)]);
        
        return i + 1;
    }
    
    /**
     * @dev Sets growth factor for automatic resizing
     * Use Case: Performance tuning, memory optimization
     */
    function setGrowthFactor(Array storage self, uint256 factor) internal {
        require(factor >= 100, "DynamicArray: growth factor must be >= 100");
        self.growthFactor = factor;
    }
    
    /**
     * @dev Optimizes capacity to current length
     * Use Case: Memory cleanup, reducing storage overhead
     */
    function shrinkToFit(Array storage self) internal {
        if (self.capacity > self.length) {
            uint256[] memory newData = new uint256[](self.length);
            
            for (uint256 i = 0; i < self.length; i++) {
                newData[i] = self.data[i];
            }
            
            uint256 oldCapacity = self.capacity;
            self.data = newData;
            self.capacity = self.length;
            
            emit ArrayResized(oldCapacity, self.capacity);
        }
    }
}