// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IModularContract - Base Interface for Modular Smart Contracts
 * @dev Standard interface enabling seamless contract composition and interoperability
 * 
 * USE CASES:
 * 1. Contract composition and inheritance
 * 2. Inter-contract communication protocols
 * 3. Upgradeable contract architectures
 * 4. Cross-system integration patterns
 * 5. Standardized error handling and events
 * 6. Gas optimization through modularity
 * 
 * WHY IT WORKS:
 * - Standardized interfaces enable predictable behavior
 * - Event-driven architecture supports loose coupling
 * - Modular design reduces deployment costs
 * - Interface segregation improves maintainability
 * - Composability enables rapid development
 * 
 * @author Nibert Investments Development Team
 */

interface IModularContract {
    
    /**
     * @dev Standard events for modular contract lifecycle
     */
    event ModuleInitialized(address indexed module, bytes32 indexed moduleId);
    event ModuleUpgraded(address indexed oldModule, address indexed newModule, bytes32 indexed moduleId);
    event ModuleDeactivated(address indexed module, bytes32 indexed moduleId);
    event CrossModuleCommunication(address indexed from, address indexed to, bytes4 indexed selector, bytes data);
    
    /**
     * @dev Standard errors for modular contracts
     */
    error ModuleNotFound(bytes32 moduleId);
    error ModuleAlreadyExists(bytes32 moduleId);
    error UnauthorizedModuleAccess(address caller, bytes32 moduleId);
    error ModuleExecutionFailed(bytes32 moduleId, bytes reason);
    error InvalidModuleInterface(address module);
    
    /**
     * @dev Returns the module identifier
     */
    function getModuleId() external pure returns (bytes32);
    
    /**
     * @dev Returns the module version
     */
    function getModuleVersion() external pure returns (uint256);
    
    /**
     * @dev Returns module metadata
     */
    function getModuleInfo() external pure returns (
        string memory name,
        string memory description,
        uint256 version,
        address[] memory dependencies
    );
    
    /**
     * @dev Initializes the module with parameters
     */
    function initializeModule(bytes calldata initData) external;
    
    /**
     * @dev Checks if module is properly initialized
     */
    function isModuleInitialized() external view returns (bool);
    
    /**
     * @dev Returns supported interfaces
     */
    function getSupportedInterfaces() external pure returns (bytes4[] memory);
    
    /**
     * @dev Execute module-specific function
     */
    function executeModuleFunction(bytes4 selector, bytes calldata data) 
        external 
        payable 
        returns (bytes memory);
}

/**
 * @title IComposableContract - Interface for Contract Composition
 * @dev Enables contracts to be composed together into larger systems
 */
interface IComposableContract is IModularContract {
    
    /**
     * @dev Events for composition lifecycle
     */
    event ModuleAdded(bytes32 indexed moduleId, address indexed moduleAddress);
    event ModuleRemoved(bytes32 indexed moduleId, address indexed moduleAddress);
    event CompositionUpdated(bytes32[] moduleIds, address[] moduleAddresses);
    
    /**
     * @dev Add a module to the composition
     */
    function addModule(bytes32 moduleId, address moduleAddress, bytes calldata initData) external;
    
    /**
     * @dev Remove a module from the composition
     */
    function removeModule(bytes32 moduleId) external;
    
    /**
     * @dev Get module address by ID
     */
    function getModule(bytes32 moduleId) external view returns (address);
    
    /**
     * @dev Get all active modules
     */
    function getActiveModules() external view returns (bytes32[] memory moduleIds, address[] memory moduleAddresses);
    
    /**
     * @dev Execute function on specific module
     */
    function executeOnModule(bytes32 moduleId, bytes4 selector, bytes calldata data) 
        external 
        payable 
        returns (bytes memory);
    
    /**
     * @dev Batch execute across multiple modules
     */
    function batchExecute(
        bytes32[] calldata moduleIds,
        bytes4[] calldata selectors,
        bytes[] calldata dataArray
    ) external payable returns (bytes[] memory results);
}

/**
 * @title IUpgradeableModule - Interface for Upgradeable Modules
 * @dev Enables safe module upgrades while preserving state
 */
interface IUpgradeableModule is IModularContract {
    
    /**
     * @dev Events for upgrade lifecycle
     */
    event UpgradeProposed(address indexed newImplementation, uint256 upgradeDelay);
    event UpgradeExecuted(address indexed oldImplementation, address indexed newImplementation);
    event UpgradeCancelled(address indexed proposedImplementation);
    
    /**
     * @dev Propose an upgrade to new implementation
     */
    function proposeUpgrade(address newImplementation, uint256 upgradeDelay) external;
    
    /**
     * @dev Execute a previously proposed upgrade
     */
    function executeUpgrade() external;
    
    /**
     * @dev Cancel a pending upgrade
     */
    function cancelUpgrade() external;
    
    /**
     * @dev Get upgrade information
     */
    function getUpgradeInfo() external view returns (
        address pendingImplementation,
        uint256 upgradeTimestamp,
        bool upgradeReady
    );
    
    /**
     * @dev Migrate state from old implementation
     */
    function migrateState(bytes calldata migrationData) external;
}

/**
 * @title ICrossChainModule - Interface for Cross-Chain Operations
 * @dev Enables modules to operate across multiple blockchains
 */
interface ICrossChainModule is IModularContract {
    
    /**
     * @dev Events for cross-chain operations
     */
    event CrossChainMessage(uint256 indexed destChainId, bytes32 indexed messageId, bytes message);
    event CrossChainResponse(uint256 indexed srcChainId, bytes32 indexed messageId, bytes response);
    event BridgeUpdated(uint256 indexed chainId, address indexed bridgeAddress);
    
    /**
     * @dev Send message to module on another chain
     */
    function sendCrossChainMessage(
        uint256 destChainId,
        bytes32 destModuleId,
        bytes calldata message
    ) external payable returns (bytes32 messageId);
    
    /**
     * @dev Handle incoming cross-chain message
     */
    function handleCrossChainMessage(
        uint256 srcChainId,
        bytes32 srcModuleId,
        bytes32 messageId,
        bytes calldata message
    ) external;
    
    /**
     * @dev Get supported chains
     */
    function getSupportedChains() external view returns (uint256[] memory chainIds);
    
    /**
     * @dev Get bridge address for specific chain
     */
    function getBridgeAddress(uint256 chainId) external view returns (address);
}

/**
 * @title ISecurityModule - Interface for Security and Access Control
 * @dev Provides standardized security features for modular contracts
 */
interface ISecurityModule is IModularContract {
    
    /**
     * @dev Security events
     */
    event AccessGranted(address indexed user, bytes32 indexed role, bytes32 indexed resource);
    event AccessRevoked(address indexed user, bytes32 indexed role, bytes32 indexed resource);
    event SecurityViolation(address indexed violator, bytes32 indexed violation, uint256 severity);
    event EmergencyStop(address indexed triggeredBy, string reason);
    event EmergencyResume(address indexed triggeredBy, string reason);
    
    /**
     * @dev Check if user has access to resource
     */
    function hasAccess(address user, bytes32 role, bytes32 resource) external view returns (bool);
    
    /**
     * @dev Grant access to user for specific role/resource
     */
    function grantAccess(address user, bytes32 role, bytes32 resource) external;
    
    /**
     * @dev Revoke access from user
     */
    function revokeAccess(address user, bytes32 role, bytes32 resource) external;
    
    /**
     * @dev Trigger emergency stop
     */
    function emergencyStop(string calldata reason) external;
    
    /**
     * @dev Resume from emergency stop
     */
    function emergencyResume(string calldata reason) external;
    
    /**
     * @dev Check if contract is paused
     */
    function isPaused() external view returns (bool);
    
    /**
     * @dev Validate function call for security
     */
    function validateFunctionCall(address caller, bytes4 selector, bytes calldata data) 
        external 
        view 
        returns (bool allowed, string memory reason);
}

/**
 * @title IGovernanceModule - Interface for Governance Operations
 * @dev Enables decentralized governance within modular contracts
 */
interface IGovernanceModule is IModularContract {
    
    /**
     * @dev Governance events
     */
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 indexed category);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, bool success, bytes result);
    event QuorumUpdated(uint256 oldQuorum, uint256 newQuorum);
    
    /**
     * @dev Create a governance proposal
     */
    function createProposal(
        bytes32 category,
        string calldata description,
        bytes calldata executionData
    ) external returns (uint256 proposalId);
    
    /**
     * @dev Cast vote on proposal
     */
    function castVote(uint256 proposalId, bool support) external;
    
    /**
     * @dev Execute passed proposal
     */
    function executeProposal(uint256 proposalId) external;
    
    /**
     * @dev Get voting power of address
     */
    function getVotingPower(address voter) external view returns (uint256);
    
    /**
     * @dev Get proposal status
     */
    function getProposalStatus(uint256 proposalId) external view returns (
        bool active,
        bool passed,
        bool executed,
        uint256 forVotes,
        uint256 againstVotes
    );
}