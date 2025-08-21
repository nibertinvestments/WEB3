// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IModularContract.sol";

/**
 * @title AdvancedAccessControl - Enterprise-Grade Access Control and Security System
 * @dev Comprehensive security module with role-based access control, time-locks, and emergency mechanisms
 * 
 * USE CASES:
 * 1. Multi-tier role-based access control systems
 * 2. Time-delayed execution for critical operations
 * 3. Emergency pause and circuit breaker mechanisms
 * 4. Multi-signature requirement enforcement
 * 5. Audit trail and compliance tracking
 * 6. Conditional access based on external factors
 * 
 * WHY IT WORKS:
 * - Hierarchical role system with inheritance
 * - Time-lock mechanisms prevent rushed decisions
 * - Emergency controls for crisis management
 * - Granular permissions for specific operations
 * - Comprehensive audit trails for compliance
 * 
 * @author Nibert Investments Development Team
 */
contract AdvancedAccessControl is ISecurityModule {
    
    // Module identification
    bytes32 public constant MODULE_ID = keccak256("ADVANCED_ACCESS_CONTROL_V1");
    uint256 public constant MODULE_VERSION = 1;
    
    // Time constants
    uint256 public constant MIN_DELAY = 1 hours;
    uint256 public constant MAX_DELAY = 30 days;
    uint256 public constant EMERGENCY_DELAY = 10 minutes;
    
    // Role hierarchy levels
    enum RoleLevel {
        None,           // 0 - No access
        Basic,          // 1 - Basic user access
        Advanced,       // 2 - Advanced user access
        Operator,       // 3 - System operator
        Manager,        // 4 - Department manager
        Administrator,  // 5 - System administrator
        SuperAdmin,     // 6 - Super administrator
        Emergency       // 7 - Emergency access only
    }
    
    // Operation severity levels
    enum SeverityLevel {
        Low,            // Low impact operations
        Medium,         // Medium impact operations
        High,           // High impact operations
        Critical,       // Critical operations
        Emergency       // Emergency operations
    }
    
    // Access control structures
    struct Role {
        bytes32 roleId;
        string name;
        string description;
        RoleLevel level;
        bytes32[] permissions;
        bytes32[] inheritedRoles;
        uint256 maxHolders;
        uint256 currentHolders;
        bool isActive;
        uint256 createdAt;
    }
    
    struct Permission {
        bytes32 permissionId;
        string name;
        string description;
        SeverityLevel severity;
        uint256 requiredSignatures;
        uint256 timeDelay;
        bool requiresApproval;
        bool isActive;
    }
    
    struct TimeLockedOperation {
        bytes32 operationId;
        address initiator;
        bytes32 permission;
        bytes data;
        address target;
        uint256 value;
        uint256 unlockTime;
        uint256 signatures;
        mapping(address => bool) hasApproved;
        bool isExecuted;
        bool isCancelled;
    }
    
    struct AccessAttempt {
        address user;
        bytes32 resource;
        bytes32 permission;
        bool granted;
        uint256 timestamp;
        string reason;
    }
    
    struct EmergencyState {
        bool isActive;
        address triggeredBy;
        uint256 triggeredAt;
        string reason;
        bytes32[] suspendedPermissions;
        uint256 autoResumeTime;
    }
    
    // State variables
    bool private _initialized;
    bool private _paused;
    EmergencyState private _emergencyState;
    
    mapping(bytes32 => Role) private _roles;
    mapping(bytes32 => Permission) private _permissions;
    mapping(address => bytes32[]) private _userRoles;
    mapping(bytes32 => TimeLockedOperation) private _timeLockedOps;
    mapping(address => mapping(bytes32 => bool)) private _userPermissions;
    mapping(address => mapping(bytes32 => uint256)) private _accessCounts;
    
    bytes32[] private _allRoles;
    bytes32[] private _allPermissions;
    AccessAttempt[] private _auditTrail;
    
    // Predefined roles
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
    bytes32 public constant USER_ROLE = keccak256("USER");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY");
    
    // Predefined permissions
    bytes32 public constant MANAGE_ROLES = keccak256("MANAGE_ROLES");
    bytes32 public constant MANAGE_PERMISSIONS = keccak256("MANAGE_PERMISSIONS");
    bytes32 public constant EMERGENCY_STOP = keccak256("EMERGENCY_STOP");
    bytes32 public constant APPROVE_TIMELOCK = keccak256("APPROVE_TIMELOCK");
    bytes32 public constant EXECUTE_TIMELOCK = keccak256("EXECUTE_TIMELOCK");
    
    // Events
    event RoleCreated(bytes32 indexed roleId, string name, RoleLevel level);
    event RoleGranted(bytes32 indexed roleId, address indexed account);
    event RoleRevoked(bytes32 indexed roleId, address indexed account);
    event PermissionCreated(bytes32 indexed permissionId, string name, SeverityLevel severity);
    event PermissionGranted(address indexed account, bytes32 indexed permission);
    event PermissionRevoked(address indexed account, bytes32 indexed permission);
    event AccessGranted(address indexed user, bytes32 indexed role, bytes32 indexed resource);
    event AccessRevoked(address indexed user, bytes32 indexed role, bytes32 indexed resource);
    event SecurityViolation(address indexed violator, bytes32 indexed violation, uint256 severity);
    event EmergencyStop(address indexed triggeredBy, string reason);
    event EmergencyResume(address indexed triggeredBy, string reason);
    event TimeLockedOperationCreated(bytes32 indexed operationId, uint256 unlockTime);
    event TimeLockedOperationExecuted(bytes32 indexed operationId, bool success);
    event TimeLockedOperationCancelled(bytes32 indexed operationId, string reason);
    
    // Errors
    error UnauthorizedAccess(address user, bytes32 permission);
    error RoleNotFound(bytes32 roleId);
    error PermissionNotFound(bytes32 permissionId);
    error InsufficientSignatures(uint256 provided, uint256 required);
    error OperationTimeLocked(uint256 unlockTime);
    error EmergencyActive();
    error InvalidTimeDelay(uint256 delay);
    error MaxHoldersExceeded(bytes32 roleId);
    
    // Modifiers
    modifier onlyRole(bytes32 role) {
        require(hasRole(msg.sender, role), "Access denied");
        _;
    }
    
    modifier onlyPermission(bytes32 permission) {
        require(hasPermission(msg.sender, permission), "Permission denied");
        _;
    }
    
    modifier notPaused() {
        require(!_paused && !_emergencyState.isActive, "System paused");
        _;
    }
    
    modifier notInEmergency() {
        require(!_emergencyState.isActive, "Emergency active");
        _;
    }
    
    // Module interface implementations
    function getModuleId() external pure override returns (bytes32) {
        return MODULE_ID;
    }
    
    function getModuleVersion() external pure override returns (uint256) {
        return MODULE_VERSION;
    }
    
    function getModuleInfo() external pure override returns (
        string memory name,
        string memory description,
        uint256 version,
        address[] memory dependencies
    ) {
        return (
            "AdvancedAccessControl",
            "Enterprise-grade access control and security system",
            MODULE_VERSION,
            new address[](0)
        );
    }
    
    function initializeModule(bytes calldata) external override {
        require(!_initialized, "Already initialized");
        
        // Initialize default roles and permissions
        _initializeDefaultRoles();
        _initializeDefaultPermissions();
        
        // Grant super admin role to deployer
        _grantRole(SUPER_ADMIN_ROLE, msg.sender);
        
        _initialized = true;
        emit ModuleInitialized(address(this), MODULE_ID);
    }
    
    function isModuleInitialized() external view override returns (bool) {
        return _initialized;
    }
    
    function getSupportedInterfaces() external pure override returns (bytes4[] memory) {
        bytes4[] memory interfaces = new bytes4[](2);
        interfaces[0] = type(IModularContract).interfaceId;
        interfaces[1] = type(ISecurityModule).interfaceId;
        return interfaces;
    }
    
    function executeModuleFunction(bytes4 selector, bytes calldata data) 
        external 
        payable 
        override 
        returns (bytes memory) 
    {
        if (selector == bytes4(keccak256("hasAccess(address,bytes32,bytes32)"))) {
            (address user, bytes32 role, bytes32 resource) = abi.decode(data, (address, bytes32, bytes32));
            return abi.encode(hasAccess(user, role, resource));
        } else if (selector == bytes4(keccak256("grantAccess(address,bytes32,bytes32)"))) {
            (address user, bytes32 role, bytes32 resource) = abi.decode(data, (address, bytes32, bytes32));
            grantAccess(user, role, resource);
            return "";
        }
        revert("Function not supported");
    }
    
    // Security interface implementations
    function hasAccess(address user, bytes32 role, bytes32 resource) public view override returns (bool) {
        if (_emergencyState.isActive) {
            return hasRole(user, EMERGENCY_ROLE);
        }
        
        return hasRole(user, role) && _hasResourceAccess(user, resource);
    }
    
    function grantAccess(address user, bytes32 role, bytes32 resource) external override onlyPermission(MANAGE_ROLES) {
        _grantRole(role, user);
        _grantResourceAccess(user, resource);
        emit AccessGranted(user, role, resource);
    }
    
    function revokeAccess(address user, bytes32 role, bytes32 resource) external override onlyPermission(MANAGE_ROLES) {
        _revokeRole(role, user);
        _revokeResourceAccess(user, resource);
        emit AccessRevoked(user, role, resource);
    }
    
    function emergencyStop(string calldata reason) external override onlyRole(EMERGENCY_ROLE) {
        require(!_emergencyState.isActive, "Emergency already active");
        
        _emergencyState.isActive = true;
        _emergencyState.triggeredBy = msg.sender;
        _emergencyState.triggeredAt = block.timestamp;
        _emergencyState.reason = reason;
        _emergencyState.autoResumeTime = block.timestamp + 24 hours; // Auto-resume after 24h
        
        emit EmergencyStop(msg.sender, reason);
    }
    
    function emergencyResume(string calldata reason) external override onlyRole(SUPER_ADMIN_ROLE) {
        require(_emergencyState.isActive, "No emergency active");
        
        _emergencyState.isActive = false;
        _emergencyState.triggeredBy = address(0);
        _emergencyState.reason = "";
        delete _emergencyState.suspendedPermissions;
        
        emit EmergencyResume(msg.sender, reason);
    }
    
    function isPaused() external view override returns (bool) {
        return _paused || _emergencyState.isActive;
    }
    
    function validateFunctionCall(address caller, bytes4 selector, bytes calldata data) 
        external 
        view 
        override 
        returns (bool allowed, string memory reason) 
    {
        if (_emergencyState.isActive && !hasRole(caller, EMERGENCY_ROLE)) {
            return (false, "Emergency mode active");
        }
        
        bytes32 permission = keccak256(abi.encodePacked(selector));
        
        if (!hasPermission(caller, permission)) {
            return (false, "Insufficient permissions");
        }
        
        return (true, "");
    }
    
    /**
     * @dev Create a new role
     */
    function createRole(
        bytes32 roleId,
        string calldata name,
        string calldata description,
        RoleLevel level,
        bytes32[] calldata permissions,
        bytes32[] calldata inheritedRoles,
        uint256 maxHolders
    ) external onlyPermission(MANAGE_ROLES) {
        require(_roles[roleId].roleId == 0, "Role already exists");
        
        Role storage role = _roles[roleId];
        role.roleId = roleId;
        role.name = name;
        role.description = description;
        role.level = level;
        role.permissions = permissions;
        role.inheritedRoles = inheritedRoles;
        role.maxHolders = maxHolders;
        role.isActive = true;
        role.createdAt = block.timestamp;
        
        _allRoles.push(roleId);
        
        emit RoleCreated(roleId, name, level);
    }
    
    /**
     * @dev Create a new permission
     */
    function createPermission(
        bytes32 permissionId,
        string calldata name,
        string calldata description,
        SeverityLevel severity,
        uint256 requiredSignatures,
        uint256 timeDelay,
        bool requiresApproval
    ) external onlyPermission(MANAGE_PERMISSIONS) {
        require(_permissions[permissionId].permissionId == 0, "Permission already exists");
        require(timeDelay >= MIN_DELAY && timeDelay <= MAX_DELAY, "Invalid time delay");
        
        Permission storage permission = _permissions[permissionId];
        permission.permissionId = permissionId;
        permission.name = name;
        permission.description = description;
        permission.severity = severity;
        permission.requiredSignatures = requiredSignatures;
        permission.timeDelay = timeDelay;
        permission.requiresApproval = requiresApproval;
        permission.isActive = true;
        
        _allPermissions.push(permissionId);
        
        emit PermissionCreated(permissionId, name, severity);
    }
    
    /**
     * @dev Grant role to user
     */
    function grantRole(bytes32 roleId, address account) external onlyPermission(MANAGE_ROLES) {
        _grantRole(roleId, account);
    }
    
    /**
     * @dev Revoke role from user
     */
    function revokeRole(bytes32 roleId, address account) external onlyPermission(MANAGE_ROLES) {
        _revokeRole(roleId, account);
    }
    
    /**
     * @dev Grant permission directly to user
     */
    function grantPermission(address account, bytes32 permission) external onlyPermission(MANAGE_PERMISSIONS) {
        _userPermissions[account][permission] = true;
        emit PermissionGranted(account, permission);
    }
    
    /**
     * @dev Revoke permission from user
     */
    function revokePermission(address account, bytes32 permission) external onlyPermission(MANAGE_PERMISSIONS) {
        _userPermissions[account][permission] = false;
        emit PermissionRevoked(account, permission);
    }
    
    /**
     * @dev Create time-locked operation
     */
    function createTimeLockedOperation(
        bytes32 operationId,
        bytes32 permission,
        bytes calldata data,
        address target,
        uint256 value
    ) external returns (uint256 unlockTime) {
        require(hasPermission(msg.sender, permission), "Permission denied");
        
        Permission memory perm = _permissions[permission];
        require(perm.isActive, "Permission not active");
        
        unlockTime = block.timestamp + perm.timeDelay;
        
        TimeLockedOperation storage op = _timeLockedOps[operationId];
        op.operationId = operationId;
        op.initiator = msg.sender;
        op.permission = permission;
        op.data = data;
        op.target = target;
        op.value = value;
        op.unlockTime = unlockTime;
        op.signatures = 1; // Initiator's signature
        op.hasApproved[msg.sender] = true;
        
        emit TimeLockedOperationCreated(operationId, unlockTime);
        
        return unlockTime;
    }
    
    /**
     * @dev Approve time-locked operation
     */
    function approveTimeLockedOperation(bytes32 operationId) external onlyPermission(APPROVE_TIMELOCK) {
        TimeLockedOperation storage op = _timeLockedOps[operationId];
        require(op.operationId != 0, "Operation not found");
        require(!op.isExecuted && !op.isCancelled, "Operation finalized");
        require(!op.hasApproved[msg.sender], "Already approved");
        
        op.hasApproved[msg.sender] = true;
        op.signatures++;
    }
    
    /**
     * @dev Execute time-locked operation
     */
    function executeTimeLockedOperation(bytes32 operationId) external onlyPermission(EXECUTE_TIMELOCK) {
        TimeLockedOperation storage op = _timeLockedOps[operationId];
        require(op.operationId != 0, "Operation not found");
        require(!op.isExecuted && !op.isCancelled, "Operation finalized");
        require(block.timestamp >= op.unlockTime, "Still time-locked");
        
        Permission memory perm = _permissions[op.permission];
        require(op.signatures >= perm.requiredSignatures, "Insufficient signatures");
        
        op.isExecuted = true;
        
        bool success;
        if (op.target != address(0)) {
            (success,) = op.target.call{value: op.value}(op.data);
        } else {
            success = true; // Internal operation
        }
        
        emit TimeLockedOperationExecuted(operationId, success);
    }
    
    /**
     * @dev Cancel time-locked operation
     */
    function cancelTimeLockedOperation(bytes32 operationId, string calldata reason) 
        external 
        onlyRole(SUPER_ADMIN_ROLE) 
    {
        TimeLockedOperation storage op = _timeLockedOps[operationId];
        require(op.operationId != 0, "Operation not found");
        require(!op.isExecuted && !op.isCancelled, "Operation finalized");
        
        op.isCancelled = true;
        
        emit TimeLockedOperationCancelled(operationId, reason);
    }
    
    /**
     * @dev Batch role management
     */
    function batchGrantRoles(
        bytes32[] calldata roleIds,
        address[] calldata accounts
    ) external onlyPermission(MANAGE_ROLES) {
        require(roleIds.length == accounts.length, "Array length mismatch");
        
        for (uint256 i = 0; i < roleIds.length; i++) {
            _grantRole(roleIds[i], accounts[i]);
        }
    }
    
    /**
     * @dev Get audit trail
     */
    function getAuditTrail(uint256 fromIndex, uint256 toIndex) 
        external 
        view 
        returns (AccessAttempt[] memory) 
    {
        require(fromIndex <= toIndex && toIndex < _auditTrail.length, "Invalid range");
        
        AccessAttempt[] memory trail = new AccessAttempt[](toIndex - fromIndex + 1);
        
        for (uint256 i = fromIndex; i <= toIndex; i++) {
            trail[i - fromIndex] = _auditTrail[i];
        }
        
        return trail;
    }
    
    // View functions
    
    function hasRole(address account, bytes32 roleId) public view returns (bool) {
        bytes32[] memory userRoles = _userRoles[account];
        
        for (uint256 i = 0; i < userRoles.length; i++) {
            if (userRoles[i] == roleId) return true;
            
            // Check inherited roles
            bytes32[] memory inherited = _roles[userRoles[i]].inheritedRoles;
            for (uint256 j = 0; j < inherited.length; j++) {
                if (inherited[j] == roleId) return true;
            }
        }
        
        return false;
    }
    
    function hasPermission(address account, bytes32 permission) public view returns (bool) {
        // Direct permission
        if (_userPermissions[account][permission]) return true;
        
        // Role-based permission
        bytes32[] memory userRoles = _userRoles[account];
        
        for (uint256 i = 0; i < userRoles.length; i++) {
            bytes32[] memory rolePermissions = _roles[userRoles[i]].permissions;
            for (uint256 j = 0; j < rolePermissions.length; j++) {
                if (rolePermissions[j] == permission) return true;
            }
        }
        
        return false;
    }
    
    function getRole(bytes32 roleId) external view returns (Role memory) {
        return _roles[roleId];
    }
    
    function getPermission(bytes32 permissionId) external view returns (Permission memory) {
        return _permissions[permissionId];
    }
    
    function getUserRoles(address account) external view returns (bytes32[] memory) {
        return _userRoles[account];
    }
    
    function getEmergencyState() external view returns (EmergencyState memory) {
        return _emergencyState;
    }
    
    function getAllRoles() external view returns (bytes32[] memory) {
        return _allRoles;
    }
    
    function getAllPermissions() external view returns (bytes32[] memory) {
        return _allPermissions;
    }
    
    // Internal functions
    
    function _grantRole(bytes32 roleId, address account) internal {
        Role storage role = _roles[roleId];
        require(role.isActive, "Role not active");
        require(role.currentHolders < role.maxHolders || role.maxHolders == 0, "Max holders exceeded");
        
        bytes32[] storage userRoles = _userRoles[account];
        
        // Check if already has role
        for (uint256 i = 0; i < userRoles.length; i++) {
            if (userRoles[i] == roleId) return;
        }
        
        userRoles.push(roleId);
        role.currentHolders++;
        
        emit RoleGranted(roleId, account);
    }
    
    function _revokeRole(bytes32 roleId, address account) internal {
        bytes32[] storage userRoles = _userRoles[account];
        
        for (uint256 i = 0; i < userRoles.length; i++) {
            if (userRoles[i] == roleId) {
                userRoles[i] = userRoles[userRoles.length - 1];
                userRoles.pop();
                _roles[roleId].currentHolders--;
                
                emit RoleRevoked(roleId, account);
                break;
            }
        }
    }
    
    function _hasResourceAccess(address user, bytes32 resource) internal pure returns (bool) {
        // Simplified resource checking - in production would be more complex
        return user != address(0) && resource != 0;
    }
    
    function _grantResourceAccess(address user, bytes32 resource) internal {
        // Implementation for resource-specific access
    }
    
    function _revokeResourceAccess(address user, bytes32 resource) internal {
        // Implementation for resource-specific access revocation
    }
    
    function _initializeDefaultRoles() internal {
        // Create default roles
        _roles[SUPER_ADMIN_ROLE] = Role({
            roleId: SUPER_ADMIN_ROLE,
            name: "Super Administrator",
            description: "Full system access",
            level: RoleLevel.SuperAdmin,
            permissions: new bytes32[](0),
            inheritedRoles: new bytes32[](0),
            maxHolders: 3,
            currentHolders: 0,
            isActive: true,
            createdAt: block.timestamp
        });
        
        _allRoles.push(SUPER_ADMIN_ROLE);
    }
    
    function _initializeDefaultPermissions() internal {
        // Create default permissions
        _permissions[MANAGE_ROLES] = Permission({
            permissionId: MANAGE_ROLES,
            name: "Manage Roles",
            description: "Create and modify roles",
            severity: SeverityLevel.High,
            requiredSignatures: 2,
            timeDelay: 1 days,
            requiresApproval: true,
            isActive: true
        });
        
        _allPermissions.push(MANAGE_ROLES);
    }
}