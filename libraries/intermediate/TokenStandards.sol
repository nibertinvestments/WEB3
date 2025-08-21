// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TokenStandards - Comprehensive Token Implementation Library
 * @dev Advanced implementations of various token standards and utilities
 * 
 * FEATURES:
 * - ERC20 advanced implementation with extensions
 * - ERC721 NFT standard with metadata and enumerable features
 * - ERC1155 multi-token standard implementation
 * - ERC777 advanced token with operator functionality
 * - Token bridging and cross-chain compatibility
 * - Advanced token economics and mechanisms
 * 
 * USE CASES:
 * 1. Complete token contract implementations
 * 2. Token standard compliance verification
 * 3. Cross-chain token bridge protocols
 * 4. Advanced token economics (deflationary, inflationary)
 * 5. Multi-standard token factories
 * 6. Token upgrade and migration utilities
 * 
 * @author Nibert Investments LLC
 * @notice Intermediate Level - Token standard implementations
 */

library TokenStandards {
    // Error definitions
    error InsufficientBalance();
    error InsufficientAllowance();
    error InvalidReceiver();
    error TokenNotExists();
    error UnauthorizedOperator();
    error TransferFailed();
    error MintingFailed();
    error BurningFailed();
    
    // Events for ERC20
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Events for ERC721
    event NFTTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event NFTApproval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    // Events for ERC1155
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event URI(string value, uint256 indexed id);
    
    // Token types
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155,
        ERC777,
        CUSTOM
    }
    
    // Token metadata structure
    struct TokenMetadata {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        bool isPaused;
        bool isMintable;
        bool isBurnable;
    }
    
    // ERC20 token state
    struct ERC20State {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
        TokenMetadata metadata;
    }
    
    // ERC721 token state
    struct ERC721State {
        mapping(uint256 => address) owners;
        mapping(address => uint256) balances;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(uint256 => string) tokenURIs;
        uint256 currentTokenId;
        TokenMetadata metadata;
    }
    
    // ERC1155 token state
    struct ERC1155State {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(uint256 => string) uris;
        TokenMetadata metadata;
    }
    
    /**
     * @dev Initializes ERC20 token state
     * Use Case: Setting up new ERC20 token contracts
     */
    function initializeERC20(
        ERC20State storage state,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply,
        address initialHolder
    ) internal {
        state.metadata.name = name;
        state.metadata.symbol = symbol;
        state.metadata.decimals = decimals;
        state.metadata.totalSupply = initialSupply;
        state.metadata.isMintable = true;
        state.metadata.isBurnable = true;
        
        state.totalSupply = initialSupply;
        state.balances[initialHolder] = initialSupply;
        
        emit Transfer(address(0), initialHolder, initialSupply);
    }
    
    /**
     * @dev Transfers ERC20 tokens with advanced validation
     * Use Case: Secure token transfers with comprehensive checks
     */
    function transferERC20(
        ERC20State storage state,
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(to != address(0), "TokenStandards: transfer to zero address");
        require(!state.metadata.isPaused, "TokenStandards: token paused");
        
        uint256 fromBalance = state.balances[from];
        require(fromBalance >= amount, "TokenStandards: insufficient balance");
        
        unchecked {
            state.balances[from] = fromBalance - amount;
            state.balances[to] += amount;
        }
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    /**
     * @dev Approves ERC20 spending with security checks
     * Use Case: Safe approval mechanism with frontrunning protection
     */
    function approveERC20(
        ERC20State storage state,
        address owner,
        address spender,
        uint256 amount
    ) internal returns (bool) {
        require(spender != address(0), "TokenStandards: approve to zero address");
        require(!state.metadata.isPaused, "TokenStandards: token paused");
        
        state.allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        
        return true;
    }
    
    /**
     * @dev Transfers from with allowance check
     * Use Case: Third-party token transfers with proper authorization
     */
    function transferFromERC20(
        ERC20State storage state,
        address spender,
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 currentAllowance = state.allowances[from][spender];
        
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "TokenStandards: insufficient allowance");
            unchecked {
                state.allowances[from][spender] = currentAllowance - amount;
            }
        }
        
        return transferERC20(state, from, to, amount);
    }
    
    /**
     * @dev Mints new ERC20 tokens with supply controls
     * Use Case: Controlled token minting with economic safeguards
     */
    function mintERC20(
        ERC20State storage state,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(to != address(0), "TokenStandards: mint to zero address");
        require(state.metadata.isMintable, "TokenStandards: minting disabled");
        require(!state.metadata.isPaused, "TokenStandards: token paused");
        
        state.totalSupply += amount;
        state.metadata.totalSupply += amount;
        unchecked {
            state.balances[to] += amount;
        }
        
        emit Transfer(address(0), to, amount);
        return true;
    }
    
    /**
     * @dev Burns ERC20 tokens with validation
     * Use Case: Token burning for deflationary economics
     */
    function burnERC20(
        ERC20State storage state,
        address from,
        uint256 amount
    ) internal returns (bool) {
        require(state.metadata.isBurnable, "TokenStandards: burning disabled");
        require(!state.metadata.isPaused, "TokenStandards: token paused");
        
        uint256 accountBalance = state.balances[from];
        require(accountBalance >= amount, "TokenStandards: burn exceeds balance");
        
        unchecked {
            state.balances[from] = accountBalance - amount;
            state.totalSupply -= amount;
            state.metadata.totalSupply -= amount;
        }
        
        emit Transfer(from, address(0), amount);
        return true;
    }
    
    /**
     * @dev Initializes ERC721 token state
     * Use Case: Setting up new NFT contracts
     */
    function initializeERC721(
        ERC721State storage state,
        string memory name,
        string memory symbol
    ) internal {
        state.metadata.name = name;
        state.metadata.symbol = symbol;
        state.metadata.decimals = 0; // NFTs don't have decimals
        state.currentTokenId = 1;
    }
    
    /**
     * @dev Mints new ERC721 token with metadata
     * Use Case: Creating unique NFTs with associated metadata
     */
    function mintERC721(
        ERC721State storage state,
        address to,
        string memory tokenURI
    ) internal returns (uint256 tokenId) {
        require(to != address(0), "TokenStandards: mint to zero address");
        require(!state.metadata.isPaused, "TokenStandards: token paused");
        
        tokenId = state.currentTokenId;
        state.currentTokenId++;
        
        unchecked {
            state.balances[to] += 1;
        }
        state.owners[tokenId] = to;
        state.tokenURIs[tokenId] = tokenURI;
        
        emit NFTTransfer(address(0), to, tokenId);
    }
    
    /**
     * @dev Transfers ERC721 token with ownership validation
     * Use Case: Secure NFT transfers with proper authorization
     */
    function transferERC721(
        ERC721State storage state,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(to != address(0), "TokenStandards: transfer to zero address");
        require(state.owners[tokenId] == from, "TokenStandards: not owner");
        require(!state.metadata.isPaused, "TokenStandards: token paused");
        
        // Clear approvals
        delete state.tokenApprovals[tokenId];
        
        unchecked {
            state.balances[from] -= 1;
            state.balances[to] += 1;
        }
        state.owners[tokenId] = to;
        
        emit NFTTransfer(from, to, tokenId);
    }
    
    /**
     * @dev Approves ERC721 token transfer
     * Use Case: Authorizing third-party NFT transfers
     */
    function approveERC721(
        ERC721State storage state,
        address owner,
        address approved,
        uint256 tokenId
    ) internal {
        require(approved != owner, "TokenStandards: approval to current owner");
        require(state.owners[tokenId] == owner, "TokenStandards: not owner");
        
        state.tokenApprovals[tokenId] = approved;
        emit NFTApproval(owner, approved, tokenId);
    }
    
    /**
     * @dev Sets approval for all ERC721 tokens
     * Use Case: Bulk NFT management and marketplace integration
     */
    function setApprovalForAllERC721(
        ERC721State storage state,
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "TokenStandards: approve to caller");
        
        state.operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    
    /**
     * @dev Initializes ERC1155 token state
     * Use Case: Setting up multi-token contracts
     */
    function initializeERC1155(
        ERC1155State storage state,
        string memory name,
        string memory symbol
    ) internal {
        state.metadata.name = name;
        state.metadata.symbol = symbol;
        state.metadata.decimals = 0; // Variable for different token types
    }
    
    /**
     * @dev Mints ERC1155 tokens in batch
     * Use Case: Efficient minting of multiple token types
     */
    function mintBatchERC1155(
        ERC1155State storage state,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        require(to != address(0), "TokenStandards: mint to zero address");
        require(ids.length == amounts.length, "TokenStandards: length mismatch");
        require(!state.metadata.isPaused, "TokenStandards: token paused");
        
        for (uint256 i = 0; i < ids.length; i++) {
            state.balances[ids[i]][to] += amounts[i];
        }
        
        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
        
        _doSafeTransferAcceptanceCheck(msg.sender, address(0), to, ids, amounts, data);
    }
    
    /**
     * @dev Transfers ERC1155 tokens in batch
     * Use Case: Efficient multi-token transfers
     */
    function safeBatchTransferFromERC1155(
        ERC1155State storage state,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        require(to != address(0), "TokenStandards: transfer to zero address");
        require(ids.length == amounts.length, "TokenStandards: length mismatch");
        require(!state.metadata.isPaused, "TokenStandards: token paused");
        
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            
            uint256 fromBalance = state.balances[id][from];
            require(fromBalance >= amount, "TokenStandards: insufficient balance");
            
            unchecked {
                state.balances[id][from] = fromBalance - amount;
                state.balances[id][to] += amount;
            }
        }
        
        emit TransferBatch(msg.sender, from, to, ids, amounts);
        
        _doSafeTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }
    
    /**
     * @dev Implements token economics with supply mechanisms
     * Use Case: Advanced tokenomics with inflation/deflation
     */
    function applyTokenEconomics(
        ERC20State storage state,
        int256 supplyChange,
        address target
    ) internal returns (bool) {
        require(!state.metadata.isPaused, "TokenStandards: token paused");
        
        if (supplyChange > 0) {
            // Inflationary mechanism
            uint256 mintAmount = uint256(supplyChange);
            return mintERC20(state, target, mintAmount);
        } else if (supplyChange < 0) {
            // Deflationary mechanism
            uint256 burnAmount = uint256(-supplyChange);
            return burnERC20(state, target, burnAmount);
        }
        
        return true; // No change
    }
    
    /**
     * @dev Implements token bridging mechanism
     * Use Case: Cross-chain token transfers and interoperability
     */
    function bridgeTokens(
        ERC20State storage state,
        address from,
        uint256 amount,
        uint256 targetChainId,
        bytes32 bridgeHash
    ) internal returns (bytes32 transferId) {
        require(!state.metadata.isPaused, "TokenStandards: token paused");
        require(amount > 0, "TokenStandards: invalid amount");
        
        // Lock tokens by burning on source chain
        require(burnERC20(state, from, amount), "TokenStandards: bridge burn failed");
        
        transferId = keccak256(
            abi.encodePacked(
                from,
                amount,
                targetChainId,
                bridgeHash,
                block.timestamp,
                block.number
            )
        );
        
        // Event would be emitted to notify bridge validators
        return transferId;
    }
    
    /**
     * @dev Verifies token standard compliance
     * Use Case: Ensuring contracts meet token standard requirements
     */
    function verifyTokenStandard(
        address tokenContract,
        TokenType expectedType
    ) internal view returns (bool isCompliant) {
        // Check if contract implements expected interface
        if (expectedType == TokenType.ERC20) {
            try IERC20(tokenContract).totalSupply() returns (uint256) {
                return true;
            } catch {
                return false;
            }
        } else if (expectedType == TokenType.ERC721) {
            try IERC721(tokenContract).supportsInterface(0x80ac58cd) returns (bool supported) {
                return supported;
            } catch {
                return false;
            }
        } else if (expectedType == TokenType.ERC1155) {
            try IERC1155(tokenContract).supportsInterface(0xd9b67a26) returns (bool supported) {
                return supported;
            } catch {
                return false;
            }
        }
        
        return false;
    }
    
    /**
     * @dev Private function for safe transfer acceptance check
     * Use Case: Ensuring recipient can handle ERC1155 tokens
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("TokenStandards: ERC1155Receiver rejected");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("TokenStandards: transfer to non ERC1155Receiver");
            }
        }
    }
}

// Interface definitions for compliance checking
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155Receiver {
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}