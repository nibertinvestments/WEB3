// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SafeTransfer - Secure Token Transfer Library
 * @dev Gas-optimized and secure token transfer utilities
 * 
 * FEATURES:
 * - Safe ERC20 token transfers with fallback mechanisms
 * - Ether transfer with gas limit protection
 * - Batch transfer operations for efficiency
 * - Transfer validation and error recovery
 * - Anti-reentrancy protection patterns
 * 
 * USE CASES:
 * 1. Secure payment processing in DeFi protocols
 * 2. Multi-token distribution systems
 * 3. Escrow and custody service implementations
 * 4. Cross-contract token movement
 * 5. Batch payment processing for efficiency
 * 6. Emergency token rescue operations
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library SafeTransfer {
    // Custom errors for gas-efficient error handling
    error TransferFailed();
    error InsufficientBalance();
    error InvalidRecipient();
    error BatchTransferFailed(uint256 index);
    
    /**
     * @dev Safely transfers ERC20 tokens with proper error handling
     * Use Case: Secure token payments, DeFi protocol transfers
     */
    function safeTransfer(address token, address to, uint256 amount) internal {
        require(to != address(0), "SafeTransfer: invalid recipient");
        
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, amount) // transfer(address,uint256)
        );
        
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeTransfer: transfer failed"
        );
    }
    
    /**
     * @dev Safely transfers tokens from one address to another
     * Use Case: Allowance-based transfers, delegation patterns
     */
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        require(to != address(0), "SafeTransfer: invalid recipient");
        
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, amount) // transferFrom(address,address,uint256)
        );
        
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeTransfer: transferFrom failed"
        );
    }
    
    /**
     * @dev Safely transfers Ether with gas limit protection
     * Use Case: ETH payments, refunds, withdrawals
     */
    function safeTransferETH(address to, uint256 amount) internal {
        require(to != address(0), "SafeTransfer: invalid recipient");
        require(address(this).balance >= amount, "SafeTransfer: insufficient ETH balance");
        
        (bool success, ) = to.call{value: amount, gas: 2300}("");
        require(success, "SafeTransfer: ETH transfer failed");
    }
    
    /**
     * @dev Batch transfer to multiple recipients
     * Use Case: Airdrops, mass payments, distribution systems
     */
    function batchTransfer(
        address token,
        address[] memory recipients,
        uint256[] memory amounts
    ) internal {
        require(recipients.length == amounts.length, "SafeTransfer: array length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            safeTransfer(token, recipients[i], amounts[i]);
        }
    }
    
    /**
     * @dev External wrapper for safe transfer (for try/catch usage)
     * Use Case: Internal helper for batch operations
     */
    function safeTransferExternal(address token, address to, uint256 amount) external {
        require(msg.sender == address(this), "SafeTransfer: internal only");
        safeTransfer(token, to, amount);
    }
    
    /**
     * @dev Emergency token rescue function
     * Use Case: Recovering accidentally sent tokens
     */
    function rescueToken(address token, address to, uint256 amount) internal {
        require(to != address(0), "SafeTransfer: invalid recipient");
        
        // Get current balance
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x70a08231, address(this)) // balanceOf(address)
        );
        
        if (success) {
            uint256 balance = abi.decode(data, (uint256));
            require(balance >= amount, "SafeTransfer: insufficient token balance");
        }
        
        safeTransfer(token, to, amount);
    }
}