// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MerkleTree - Advanced Merkle Tree Implementation
 * @dev Comprehensive cryptographic proof system for data integrity
 * 
 * FEATURES:
 * - Dynamic Merkle tree construction and updates
 * - Efficient proof generation and verification
 * - Multi-proof batch verification
 * - Sparse Merkle tree support
 * - Incremental tree updates
 * 
 * USE CASES:
 * 1. Airdrop and whitelist verification systems
 * 2. State commitment and rollup verification
 * 3. Data integrity proofs for off-chain storage
 * 4. Zero-knowledge proof system foundations
 * 5. Scalable voting and governance systems
 * 6. Cross-chain bridge verification
 * 
 * @author Nibert Investments LLC
 * @notice Confidential and Proprietary Technology
 */

library MerkleTree {
    struct Tree {
        bytes32 root;
        uint256 height;
        mapping(uint256 => bytes32) nodes;
        uint256 leafCount;
        bool isFinalized;
    }
    
    struct Proof {
        bytes32[] siblings;
        uint256[] positions;
        bytes32 leaf;
        uint256 index;
    }
    
    /**
     * @dev Initializes a new Merkle tree
     * Use Case: Setting up verification systems
     */
    function initialize(Tree storage tree, uint256 expectedHeight) internal {
        tree.height = expectedHeight;
        tree.leafCount = 0;
        tree.isFinalized = false;
    }
    
    /**
     * @dev Adds a leaf to the tree
     * Use Case: Building whitelist, adding eligible addresses
     */
    function addLeaf(Tree storage tree, bytes32 leaf) internal returns (uint256 index) {
        require(!tree.isFinalized, "MerkleTree: tree is finalized");
        
        index = tree.leafCount;
        tree.nodes[index] = leaf;
        tree.leafCount++;
        
        return index;
    }
    
    /**
     * @dev Finalizes the tree and computes the root
     * Use Case: Completing tree construction
     */
    function finalize(Tree storage tree) internal {
        require(!tree.isFinalized, "MerkleTree: already finalized");
        require(tree.leafCount > 0, "MerkleTree: no leaves");
        
        uint256 currentLevel = 0;
        uint256 currentCount = tree.leafCount;
        
        while (currentCount > 1) {
            uint256 nextCount = (currentCount + 1) / 2;
            
            for (uint256 i = 0; i < nextCount; i++) {
                uint256 leftIndex = _getNodeIndex(currentLevel, i * 2);
                uint256 rightIndex = _getNodeIndex(currentLevel, i * 2 + 1);
                
                bytes32 leftHash = tree.nodes[leftIndex];
                bytes32 rightHash = (i * 2 + 1 < currentCount) ? 
                    tree.nodes[rightIndex] : leftHash;
                
                uint256 parentIndex = _getNodeIndex(currentLevel + 1, i);
                tree.nodes[parentIndex] = keccak256(abi.encodePacked(leftHash, rightHash));
            }
            
            currentLevel++;
            currentCount = nextCount;
        }
        
        tree.root = tree.nodes[_getNodeIndex(currentLevel, 0)];
        tree.isFinalized = true;
    }
    
    /**
     * @dev Generates a proof for a given leaf
     * Use Case: Creating verification proofs for users
     */
    function generateProof(Tree storage tree, uint256 leafIndex) 
        internal view returns (Proof memory proof) {
        require(tree.isFinalized, "MerkleTree: tree not finalized");
        require(leafIndex < tree.leafCount, "MerkleTree: invalid leaf index");
        
        proof.leaf = tree.nodes[leafIndex];
        proof.index = leafIndex;
        
        uint256 maxSiblings = tree.height;
        proof.siblings = new bytes32[](maxSiblings);
        proof.positions = new uint256[](maxSiblings);
        
        uint256 siblingCount = 0;
        uint256 currentIndex = leafIndex;
        uint256 currentLevel = 0;
        
        while (currentLevel < tree.height && currentIndex > 0) {
            uint256 siblingIndex;
            if (currentIndex % 2 == 0) {
                // Current node is left child
                siblingIndex = currentIndex + 1;
                proof.positions[siblingCount] = 1; // Right sibling
            } else {
                // Current node is right child
                siblingIndex = currentIndex - 1;
                proof.positions[siblingCount] = 0; // Left sibling
            }
            
            uint256 siblingNodeIndex = _getNodeIndex(currentLevel, siblingIndex);
            proof.siblings[siblingCount] = tree.nodes[siblingNodeIndex];
            
            currentIndex = currentIndex / 2;
            currentLevel++;
            siblingCount++;
        }
        
        // Resize arrays to actual length
        bytes32[] memory actualSiblings = new bytes32[](siblingCount);
        uint256[] memory actualPositions = new uint256[](siblingCount);
        
        for (uint256 i = 0; i < siblingCount; i++) {
            actualSiblings[i] = proof.siblings[i];
            actualPositions[i] = proof.positions[i];
        }
        
        proof.siblings = actualSiblings;
        proof.positions = actualPositions;
    }
    
    /**
     * @dev Verifies a Merkle proof
     * Use Case: Validating user eligibility, whitelist verification
     */
    function verifyProof(
        bytes32 root,
        Proof memory proof
    ) internal pure returns (bool) {
        bytes32 computedHash = proof.leaf;
        
        for (uint256 i = 0; i < proof.siblings.length; i++) {
            bytes32 sibling = proof.siblings[i];
            
            if (proof.positions[i] == 0) {
                // Sibling is left
                computedHash = keccak256(abi.encodePacked(sibling, computedHash));
            } else {
                // Sibling is right
                computedHash = keccak256(abi.encodePacked(computedHash, sibling));
            }
        }
        
        return computedHash == root;
    }
    
    /**
     * @dev Verifies multiple proofs in batch
     * Use Case: Efficient batch verification for airdrops
     */
    function verifyMultiProof(
        bytes32 root,
        Proof[] memory proofs
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < proofs.length; i++) {
            if (!verifyProof(root, proofs[i])) {
                return false;
            }
        }
        return true;
    }
    
    /**
     * @dev Updates a leaf in the tree and recomputes affected nodes
     * Use Case: Dynamic whitelist updates, state transitions
     */
    function updateLeaf(Tree storage tree, uint256 leafIndex, bytes32 newLeaf) internal {
        require(tree.isFinalized, "MerkleTree: tree not finalized");
        require(leafIndex < tree.leafCount, "MerkleTree: invalid leaf index");
        
        // Update the leaf
        tree.nodes[leafIndex] = newLeaf;
        
        // Recompute path to root
        uint256 currentIndex = leafIndex;
        uint256 currentLevel = 0;
        
        while (currentLevel < tree.height) {
            uint256 parentIndex = currentIndex / 2;
            uint256 leftChildIndex = _getNodeIndex(currentLevel, parentIndex * 2);
            uint256 rightChildIndex = _getNodeIndex(currentLevel, parentIndex * 2 + 1);
            
            bytes32 leftHash = tree.nodes[leftChildIndex];
            bytes32 rightHash = tree.nodes[rightChildIndex];
            
            uint256 parentNodeIndex = _getNodeIndex(currentLevel + 1, parentIndex);
            tree.nodes[parentNodeIndex] = keccak256(abi.encodePacked(leftHash, rightHash));
            
            if (parentIndex == 0) break;
            
            currentIndex = parentIndex;
            currentLevel++;
        }
        
        // Update root
        tree.root = tree.nodes[_getNodeIndex(currentLevel, 0)];
    }
    
    /**
     * @dev Computes Merkle root from array of leaves
     * Use Case: Quick root calculation for small datasets
     */
    function computeRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        require(leaves.length > 0, "MerkleTree: empty leaves array");
        
        if (leaves.length == 1) {
            return leaves[0];
        }
        
        bytes32[] memory currentLevel = leaves;
        
        while (currentLevel.length > 1) {
            uint256 nextLevelLength = (currentLevel.length + 1) / 2;
            bytes32[] memory nextLevel = new bytes32[](nextLevelLength);
            
            for (uint256 i = 0; i < nextLevelLength; i++) {
                bytes32 left = currentLevel[i * 2];
                bytes32 right = (i * 2 + 1 < currentLevel.length) ? 
                    currentLevel[i * 2 + 1] : left;
                
                nextLevel[i] = keccak256(abi.encodePacked(left, right));
            }
            
            currentLevel = nextLevel;
        }
        
        return currentLevel[0];
    }
    
    /**
     * @dev Creates a sparse Merkle tree proof
     * Use Case: Efficient proofs for sparse datasets
     */
    function generateSparseProof(
        mapping(uint256 => bytes32) storage leaves,
        uint256 leafIndex,
        uint256 treeHeight
    ) internal view returns (bytes32[] memory proof) {
        proof = new bytes32[](treeHeight);
        uint256 currentIndex = leafIndex;
        
        for (uint256 level = 0; level < treeHeight; level++) {
            uint256 siblingIndex = currentIndex ^ 1; // XOR with 1 to get sibling
            proof[level] = leaves[siblingIndex];
            currentIndex = currentIndex / 2;
        }
    }
    
    /**
     * @dev Verifies a sparse Merkle tree proof
     * Use Case: Validating sparse tree membership
     */
    function verifySparseProof(
        bytes32 root,
        bytes32 leaf,
        uint256 leafIndex,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        uint256 currentIndex = leafIndex;
        
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 sibling = proof[i];
            
            if (currentIndex % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, sibling));
            } else {
                computedHash = keccak256(abi.encodePacked(sibling, computedHash));
            }
            
            currentIndex = currentIndex / 2;
        }
        
        return computedHash == root;
    }
    
    /**
     * @dev Internal function to calculate node index
     * Use Case: Tree traversal and indexing
     */
    function _getNodeIndex(uint256 level, uint256 position) private pure returns (uint256) {
        return (1 << level) + position;
    }
    
    /**
     * @dev Gets the tree root
     * Use Case: External root access
     */
    function getRoot(Tree storage tree) internal view returns (bytes32) {
        require(tree.isFinalized, "MerkleTree: tree not finalized");
        return tree.root;
    }
    
    /**
     * @dev Checks if tree is finalized
     * Use Case: Status checking
     */
    function isFinalized(Tree storage tree) internal view returns (bool) {
        return tree.isFinalized;
    }
    
    /**
     * @dev Gets leaf count
     * Use Case: Tree size information
     */
    function getLeafCount(Tree storage tree) internal view returns (uint256) {
        return tree.leafCount;
    }
}