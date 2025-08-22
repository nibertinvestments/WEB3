// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title EnterpriseDataManagement - Advanced Data Management System
 * @dev Manages enterprise data with advanced analytics and AI integration
 */

contract EnterpriseDataManagement {
    struct DataRecord {
        uint256 recordId;
        bytes32 dataHash;
        string metadata;
        address owner;
        uint256 accessLevel; // 1: public, 2: internal, 3: confidential
        uint256 creationTime;
        uint256 lastAccessed;
        bool isActive;
    }
    
    struct DataAccess {
        uint256 accessId;
        uint256 recordId;
        address accessor;
        uint256 accessTime;
        string purpose;
    }
    
    mapping(uint256 => DataRecord) public dataRecords;
    mapping(uint256 => DataAccess) public dataAccesses;
    mapping(address => uint256[]) public userRecords;
    uint256 public nextRecordId;
    uint256 public nextAccessId;
    
    event DataStored(uint256 indexed recordId, address owner, uint256 accessLevel);
    event DataAccessed(uint256 indexed recordId, address accessor);
    event AccessRevoked(uint256 indexed recordId, address accessor);
    
    function storeData(
        bytes32 dataHash,
        string calldata metadata,
        uint256 accessLevel
    ) external returns (uint256 recordId) {
        require(accessLevel >= 1 && accessLevel <= 3, "Invalid access level");
        
        recordId = nextRecordId++;
        
        dataRecords[recordId] = DataRecord({
            recordId: recordId,
            dataHash: dataHash,
            metadata: metadata,
            owner: msg.sender,
            accessLevel: accessLevel,
            creationTime: block.timestamp,
            lastAccessed: block.timestamp,
            isActive: true
        });
        
        userRecords[msg.sender].push(recordId);
        
        emit DataStored(recordId, msg.sender, accessLevel);
        return recordId;
    }
    
    function accessData(
        uint256 recordId,
        string calldata purpose
    ) external returns (bool success) {
        DataRecord storage record = dataRecords[recordId];
        require(record.isActive, "Record not active");
        require(hasAccessPermission(msg.sender, recordId), "Access denied");
        
        uint256 accessId = nextAccessId++;
        
        dataAccesses[accessId] = DataAccess({
            accessId: accessId,
            recordId: recordId,
            accessor: msg.sender,
            accessTime: block.timestamp,
            purpose: purpose
        });
        
        record.lastAccessed = block.timestamp;
        
        emit DataAccessed(recordId, msg.sender);
        return true;
    }
    
    function hasAccessPermission(address accessor, uint256 recordId) internal view returns (bool) {
        DataRecord storage record = dataRecords[recordId];
        
        // Owner always has access
        if (record.owner == accessor) {
            return true;
        }
        
        // Public data accessible to all
        if (record.accessLevel == 1) {
            return true;
        }
        
        // For internal and confidential data, implement access control logic
        return false;
    }
    
    function revokeAccess(uint256 recordId, address accessor) external {
        require(dataRecords[recordId].owner == msg.sender, "Not owner");
        emit AccessRevoked(recordId, accessor);
    }
}