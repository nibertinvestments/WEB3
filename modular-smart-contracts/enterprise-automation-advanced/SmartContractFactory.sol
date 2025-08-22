// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SmartContractFactory - Automated Contract Deployment Platform
 * @dev Factory for creating and managing smart contracts with templates
 */

contract SmartContractFactory {
    struct ContractTemplate {
        uint256 templateId;
        string name;
        bytes bytecode;
        address creator;
        uint256 deploymentCost;
        bool isActive;
    }
    
    struct DeployedContract {
        uint256 contractId;
        uint256 templateId;
        address contractAddress;
        address deployer;
        uint256 deploymentTime;
        bytes constructorArgs;
    }
    
    mapping(uint256 => ContractTemplate) public templates;
    mapping(uint256 => DeployedContract) public deployedContracts;
    uint256 public nextTemplateId;
    uint256 public nextContractId;
    
    event TemplateCreated(uint256 indexed templateId, string name);
    event ContractDeployed(uint256 indexed contractId, address contractAddress);
    
    function createTemplate(
        string calldata name,
        bytes calldata bytecode,
        uint256 deploymentCost
    ) external returns (uint256 templateId) {
        templateId = nextTemplateId++;
        
        templates[templateId] = ContractTemplate({
            templateId: templateId,
            name: name,
            bytecode: bytecode,
            creator: msg.sender,
            deploymentCost: deploymentCost,
            isActive: true
        });
        
        emit TemplateCreated(templateId, name);
        return templateId;
    }
    
    function deployContract(
        uint256 templateId,
        bytes calldata constructorArgs
    ) external payable returns (uint256 contractId, address contractAddress) {
        ContractTemplate storage template = templates[templateId];
        require(template.isActive, "Template not active");
        require(msg.value >= template.deploymentCost, "Insufficient payment");
        
        contractId = nextContractId++;
        
        // Deploy contract using CREATE2 for deterministic addresses
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, contractId));
        bytes memory creationCode = abi.encodePacked(template.bytecode, constructorArgs);
        
        assembly {
            contractAddress := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        require(contractAddress != address(0), "Deployment failed");
        
        deployedContracts[contractId] = DeployedContract({
            contractId: contractId,
            templateId: templateId,
            contractAddress: contractAddress,
            deployer: msg.sender,
            deploymentTime: block.timestamp,
            constructorArgs: constructorArgs
        });
        
        emit ContractDeployed(contractId, contractAddress);
        return (contractId, contractAddress);
    }
}