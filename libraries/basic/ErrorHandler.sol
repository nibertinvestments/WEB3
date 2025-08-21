// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ErrorHandler - Advanced Error Management Library
 * @dev Comprehensive error handling and recovery system
 * 
 * FEATURES:
 * - Custom error types with gas-efficient encoding
 * - Error recovery and fallback mechanisms
 * - Error logging and analytics
 * - Graceful degradation patterns
 * - Circuit breaker implementations
 * 
 * USE CASES:
 * 1. DeFi protocol error recovery and resilience
 * 2. Smart contract debugging and monitoring
 * 3. User-friendly error messaging
 * 4. System health monitoring and alerting
 * 5. Automated error response and mitigation
 * 6. Contract upgrade and migration safety
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library ErrorHandler {
    // Custom errors for gas efficiency
    error InvalidInput(string parameter, uint256 value);
    error InsufficientFunds(uint256 required, uint256 available);
    error Unauthorized(address caller, string permission);
    error ContractPaused(address contractAddr);
    error CircuitBreakerTripped(string reason);
    error OperationFailed(string operation, string reason);
    
    // Error severity levels
    enum Severity {
        INFO,
        WARNING,
        ERROR,
        CRITICAL
    }
    
    // Error tracking structure
    struct ErrorLog {
        Severity severity;
        string message;
        address source;
        uint256 timestamp;
        bytes32 errorHash;
    }
    
    // Events for error monitoring
    event ErrorLogged(
        Severity indexed severity,
        address indexed source,
        string message,
        uint256 timestamp
    );
    
    event ErrorRecovered(
        address indexed source,
        string operation,
        uint256 timestamp
    );
    
    event CircuitBreakerActivated(
        address indexed source,
        string reason,
        uint256 timestamp
    );
    
    /**
     * @dev Logs an error with specified severity
     * Use Case: Error tracking, debugging, monitoring
     */
    function logError(
        Severity severity,
        string memory message,
        address source
    ) internal {
        emit ErrorLogged(severity, source, message, block.timestamp);
    }
    
    /**
     * @dev Validates input parameters with custom error
     * Use Case: Input validation, parameter checking
     */
    function validateInput(
        bool condition,
        string memory parameter,
        uint256 value
    ) internal pure {
        if (!condition) {
            revert InvalidInput(parameter, value);
        }
    }
    
    /**
     * @dev Checks sufficient balance with detailed error
     * Use Case: Payment validation, balance checking
     */
    function requireSufficientFunds(
        uint256 required,
        uint256 available
    ) internal pure {
        if (available < required) {
            revert InsufficientFunds(required, available);
        }
    }
    
    /**
     * @dev Validates authorization with context
     * Use Case: Access control, permission checking
     */
    function requireAuthorization(
        bool authorized,
        address caller,
        string memory permission
    ) internal pure {
        if (!authorized) {
            revert Unauthorized(caller, permission);
        }
    }
    
    /**
     * @dev Checks if contract is paused
     * Use Case: Emergency stops, maintenance mode
     */
    function requireNotPaused(bool paused, address contractAddr) internal pure {
        if (paused) {
            revert ContractPaused(contractAddr);
        }
    }
    
    /**
     * @dev Implements circuit breaker pattern
     * Use Case: System protection, failure prevention
     */
    function checkCircuitBreaker(
        uint256 failureCount,
        uint256 threshold,
        string memory reason
    ) internal view {
        if (failureCount >= threshold) {
            emit CircuitBreakerActivated(address(this), reason, block.timestamp);
            revert CircuitBreakerTripped(reason);
        }
    }
    
    /**
     * @dev Safe external call with error handling
     * Use Case: External contract interaction safety
     */
    function safeCall(
        address target,
        bytes memory data,
        string memory operation
    ) internal returns (bool success, bytes memory result) {
        try target.call(data) returns (bytes memory returnData) {
            success = true;
            result = returnData;
            emit ErrorRecovered(target, operation, block.timestamp);
        } catch Error(string memory reason) {
            success = false;
            result = bytes(reason);
            logError(Severity.ERROR, reason, target);
        } catch (bytes memory lowLevelData) {
            success = false;
            result = lowLevelData;
            logError(Severity.ERROR, "Low-level call failed", target);
        }
    }
    
    /**
     * @dev Graceful operation with fallback
     * Use Case: Resilient system design, fallback mechanisms
     */
    function tryWithFallback(
        function() internal returns (bool) primaryOperation,
        function() internal returns (bool) fallbackOperation,
        string memory operationName
    ) internal returns (bool success) {
        try primaryOperation() returns (bool result) {
            return result;
        } catch {
            logError(Severity.WARNING, 
                string(abi.encodePacked("Primary operation failed: ", operationName)), 
                address(this)
            );
            
            try fallbackOperation() returns (bool fallbackResult) {
                emit ErrorRecovered(address(this), operationName, block.timestamp);
                return fallbackResult;
            } catch {
                logError(Severity.CRITICAL, 
                    string(abi.encodePacked("Fallback operation failed: ", operationName)), 
                    address(this)
                );
                return false;
            }
        }
    }
    
    /**
     * @dev Creates error signature for tracking
     * Use Case: Error categorization, analytics
     */
    function createErrorSignature(
        string memory errorType,
        address source,
        bytes memory errorData
    ) internal view returns (bytes32) {
        return keccak256(abi.encode(errorType, source, errorData, block.timestamp));
    }
    
    /**
     * @dev Formats error message with context
     * Use Case: User-friendly error reporting
     */
    function formatError(
        string memory operation,
        string memory reason,
        address source
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "Operation '", operation, 
            "' failed in contract ", 
            addressToString(source),
            ": ", reason
        ));
    }
    
    /**
     * @dev Converts address to string for error messages
     * Use Case: Error message formatting
     */
    function addressToString(address addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        
        return string(str);
    }
}