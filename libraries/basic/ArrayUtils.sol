// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ArrayUtils - Advanced Array Processing Library
 * @dev Comprehensive utilities for array manipulation and analysis
 * 
 * FEATURES:
 * - Dynamic array operations (insert, remove, search)
 * - Array sorting and filtering algorithms
 * - Set operations (union, intersection, difference)
 * - Statistical analysis on arrays
 * - Memory-efficient implementations
 * 
 * USE CASES:
 * 1. Token holder management and analysis
 * 2. Voting system data processing
 * 3. Portfolio rebalancing algorithms
 * 4. Whitelist and blacklist management
 * 5. Price feed aggregation and filtering
 * 6. Multi-asset protocol operations
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library ArrayUtils {
    /**
     * @dev Removes element at index from uint256 array
     * Use Case: Dynamic whitelist management, portfolio rebalancing
     */
    function removeAt(uint256[] memory array, uint256 index) 
        internal pure returns (uint256[] memory) {
        require(index < array.length, "ArrayUtils: index out of bounds");
        
        uint256[] memory result = new uint256[](array.length - 1);
        
        for (uint256 i = 0; i < index; i++) {
            result[i] = array[i];
        }
        
        for (uint256 i = index + 1; i < array.length; i++) {
            result[i - 1] = array[i];
        }
        
        return result;
    }
    
    /**
     * @dev Removes element at index from address array
     * Use Case: User management, access control lists
     */
    function removeAtAddress(address[] memory array, uint256 index) 
        internal pure returns (address[] memory) {
        require(index < array.length, "ArrayUtils: index out of bounds");
        
        address[] memory result = new address[](array.length - 1);
        
        for (uint256 i = 0; i < index; i++) {
            result[i] = array[i];
        }
        
        for (uint256 i = index + 1; i < array.length; i++) {
            result[i - 1] = array[i];
        }
        
        return result;
    }
    
    /**
     * @dev Finds index of element in uint256 array
     * Use Case: Token search, portfolio analysis
     */
    function indexOf(uint256[] memory array, uint256 element) 
        internal pure returns (int256) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                return int256(i);
            }
        }
        return -1;
    }
    
    /**
     * @dev Finds index of element in address array
     * Use Case: User lookup, access control verification
     */
    function indexOfAddress(address[] memory array, address element) 
        internal pure returns (int256) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                return int256(i);
            }
        }
        return -1;
    }
    
    /**
     * @dev Checks if element exists in uint256 array
     * Use Case: Membership verification, validation checks
     */
    function contains(uint256[] memory array, uint256 element) 
        internal pure returns (bool) {
        return indexOf(array, element) >= 0;
    }
    
    /**
     * @dev Checks if element exists in address array
     * Use Case: Whitelist verification, access control
     */
    function containsAddress(address[] memory array, address element) 
        internal pure returns (bool) {
        return indexOfAddress(array, element) >= 0;
    }
    
    /**
     * @dev Removes duplicates from uint256 array
     * Use Case: Data cleaning, unique token lists
     */
    function unique(uint256[] memory array) 
        internal pure returns (uint256[] memory) {
        if (array.length <= 1) return array;
        
        uint256[] memory temp = new uint256[](array.length);
        uint256 uniqueCount = 0;
        
        for (uint256 i = 0; i < array.length; i++) {
            bool isDuplicate = false;
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (temp[j] == array[i]) {
                    isDuplicate = true;
                    break;
                }
            }
            if (!isDuplicate) {
                temp[uniqueCount++] = array[i];
            }
        }
        
        uint256[] memory result = new uint256[](uniqueCount);
        for (uint256 i = 0; i < uniqueCount; i++) {
            result[i] = temp[i];
        }
        
        return result;
    }
    
    /**
     * @dev Removes duplicates from address array
     * Use Case: User list management, voting systems
     */
    function uniqueAddresses(address[] memory array) 
        internal pure returns (address[] memory) {
        if (array.length <= 1) return array;
        
        address[] memory temp = new address[](array.length);
        uint256 uniqueCount = 0;
        
        for (uint256 i = 0; i < array.length; i++) {
            bool isDuplicate = false;
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (temp[j] == array[i]) {
                    isDuplicate = true;
                    break;
                }
            }
            if (!isDuplicate) {
                temp[uniqueCount++] = array[i];
            }
        }
        
        address[] memory result = new address[](uniqueCount);
        for (uint256 i = 0; i < uniqueCount; i++) {
            result[i] = temp[i];
        }
        
        return result;
    }
    
    /**
     * @dev Sorts uint256 array in ascending order using quicksort
     * Use Case: Price sorting, ranking systems
     */
    function sort(uint256[] memory array) internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](array.length);
        for (uint256 i = 0; i < array.length; i++) {
            result[i] = array[i];
        }
        
        if (result.length > 1) {
            quickSort(result, 0, int256(result.length - 1));
        }
        
        return result;
    }
    
    /**
     * @dev Internal quicksort implementation
     * Use Case: Internal sorting algorithm
     */
    function quickSort(uint256[] memory arr, int256 left, int256 right) internal pure {
        if (left < right) {
            int256 pivotIndex = partition(arr, left, right);
            quickSort(arr, left, pivotIndex - 1);
            quickSort(arr, pivotIndex + 1, right);
        }
    }
    
    /**
     * @dev Partition function for quicksort
     * Use Case: Internal sorting helper
     */
    function partition(uint256[] memory arr, int256 left, int256 right) 
        internal pure returns (int256) {
        uint256 pivot = arr[uint256(right)];
        int256 i = left - 1;
        
        for (int256 j = left; j < right; j++) {
            if (arr[uint256(j)] <= pivot) {
                i++;
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
            }
        }
        
        (arr[uint256(i + 1)], arr[uint256(right)]) = (arr[uint256(right)], arr[uint256(i + 1)]);
        return i + 1;
    }
    
    /**
     * @dev Calculates sum of uint256 array
     * Use Case: Total value calculations, statistical analysis
     */
    function sum(uint256[] memory array) internal pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < array.length; i++) {
            total += array[i];
        }
        return total;
    }
    
    /**
     * @dev Finds maximum value in uint256 array
     * Use Case: Peak analysis, optimization problems
     */
    function max(uint256[] memory array) internal pure returns (uint256) {
        require(array.length > 0, "ArrayUtils: empty array");
        
        uint256 maximum = array[0];
        for (uint256 i = 1; i < array.length; i++) {
            if (array[i] > maximum) {
                maximum = array[i];
            }
        }
        return maximum;
    }
    
    /**
     * @dev Finds minimum value in uint256 array
     * Use Case: Floor analysis, risk assessment
     */
    function min(uint256[] memory array) internal pure returns (uint256) {
        require(array.length > 0, "ArrayUtils: empty array");
        
        uint256 minimum = array[0];
        for (uint256 i = 1; i < array.length; i++) {
            if (array[i] < minimum) {
                minimum = array[i];
            }
        }
        return minimum;
    }
    
    /**
     * @dev Reverses array order
     * Use Case: Data transformation, chronological ordering
     */
    function reverse(uint256[] memory array) internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](array.length);
        
        for (uint256 i = 0; i < array.length; i++) {
            result[i] = array[array.length - 1 - i];
        }
        
        return result;
    }
    
    /**
     * @dev Filters array based on minimum threshold
     * Use Case: Minimum balance filtering, quality control
     */
    function filterMin(uint256[] memory array, uint256 threshold) 
        internal pure returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count qualifying elements
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] >= threshold) {
                count++;
            }
        }
        
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] >= threshold) {
                result[index++] = array[i];
            }
        }
        
        return result;
    }
    
    /**
     * @dev Filters array based on maximum threshold
     * Use Case: Maximum exposure filtering, risk management
     */
    function filterMax(uint256[] memory array, uint256 threshold) 
        internal pure returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count qualifying elements
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] <= threshold) {
                count++;
            }
        }
        
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] <= threshold) {
                result[index++] = array[i];
            }
        }
        
        return result;
    }
    
    /**
     * @dev Concatenates two uint256 arrays
     * Use Case: Data merging, portfolio consolidation
     */
    function concat(uint256[] memory a, uint256[] memory b) 
        internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](a.length + b.length);
        
        for (uint256 i = 0; i < a.length; i++) {
            result[i] = a[i];
        }
        
        for (uint256 i = 0; i < b.length; i++) {
            result[a.length + i] = b[i];
        }
        
        return result;
    }
    
    /**
     * @dev Concatenates two address arrays
     * Use Case: User list merging, access control consolidation
     */
    function concatAddresses(address[] memory a, address[] memory b) 
        internal pure returns (address[] memory) {
        address[] memory result = new address[](a.length + b.length);
        
        for (uint256 i = 0; i < a.length; i++) {
            result[i] = a[i];
        }
        
        for (uint256 i = 0; i < b.length; i++) {
            result[a.length + i] = b[i];
        }
        
        return result;
    }
    
    /**
     * @dev Creates intersection of two uint256 arrays
     * Use Case: Common element finding, overlap analysis
     */
    function intersection(uint256[] memory a, uint256[] memory b) 
        internal pure returns (uint256[] memory) {
        uint256 count = 0;
        
        // Count common elements
        for (uint256 i = 0; i < a.length; i++) {
            if (contains(b, a[i])) {
                count++;
            }
        }
        
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < a.length; i++) {
            if (contains(b, a[i])) {
                result[index++] = a[i];
            }
        }
        
        return unique(result);
    }
    
    /**
     * @dev Creates union of two uint256 arrays (no duplicates)
     * Use Case: Data consolidation, comprehensive lists
     */
    function union(uint256[] memory a, uint256[] memory b) 
        internal pure returns (uint256[] memory) {
        return unique(concat(a, b));
    }
    
    /**
     * @dev Slice array from start to end index
     * Use Case: Data pagination, partial processing
     */
    function slice(uint256[] memory array, uint256 start, uint256 end) 
        internal pure returns (uint256[] memory) {
        require(start <= end && end <= array.length, "ArrayUtils: invalid slice indices");
        
        uint256[] memory result = new uint256[](end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = array[i];
        }
        
        return result;
    }
}