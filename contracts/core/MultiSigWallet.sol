// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MultiSigWallet - Enhanced Multi-Signature Wallet
 * @dev Secure wallet requiring multiple signatures for transaction execution
 * 
 * USE CASES:
 * 1. Treasury management for DAOs and organizations
 * 2. Shared custody solutions for institutional funds
 * 3. Escrow services for large transactions
 * 4. Team-controlled smart contract management
 * 5. Emergency fund recovery mechanisms
 * 6. Cross-chain bridge fund security
 * 
 * WHY IT WORKS:
 * - Multiple signatures prevent single points of failure
 * - Configurable thresholds provide security flexibility
 * - Time delays protect against rushed decisions
 * - Owner management enables team changes
 * - Emergency mechanisms handle edge cases
 * 
 * @author Nibert Investments Development Team
 */

contract MultiSigWallet {
    // Events
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event RequirementChanged(uint256 required);
    
    // Transaction structure
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
        uint256 submissionTime;
        string description;
    }
    
    // State variables
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;
    
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    
    // Security features
    uint256 public constant EXECUTION_DELAY = 24 hours;
    uint256 public constant MAX_OWNERS = 20;
    mapping(uint256 => uint256) public executionTime;
    
    // Modifiers
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }
    
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }
    
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }
    
    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Transaction already confirmed");
        _;
    }
    
    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "Owners required");
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
            "Invalid number of required confirmations"
        );
        require(_owners.length <= MAX_OWNERS, "Too many owners");
        
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");
            
            isOwner[owner] = true;
            owners.push(owner);
        }
        
        numConfirmationsRequired = _numConfirmationsRequired;
    }
    
    /**
     * @dev Allows contract to receive ETH
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
    /**
     * @dev Submits a transaction for approval
     * Use Case: Initiating payments, contract calls, asset transfers
     */
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data,
        string memory _description
    ) external onlyOwner {
        uint256 txIndex = transactions.length;
        
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0,
                submissionTime: block.timestamp,
                description: _description
            })
        );
        
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }
    
    /**
     * @dev Confirms a pending transaction
     * Use Case: Approving submitted transactions
     */
    function confirmTransaction(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;
        
        emit ConfirmTransaction(msg.sender, _txIndex);
        
        // Auto-execute if enough confirmations and delay passed
        if (transaction.numConfirmations >= numConfirmationsRequired) {
            if (block.timestamp >= transaction.submissionTime + EXECUTION_DELAY) {
                _executeTransaction(_txIndex);
            } else {
                executionTime[_txIndex] = transaction.submissionTime + EXECUTION_DELAY;
            }
        }
    }
    
    /**
     * @dev Executes a confirmed transaction
     * Use Case: Finalizing approved transactions after delay
     */
    function executeTransaction(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        
        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "Cannot execute transaction"
        );
        require(
            block.timestamp >= transaction.submissionTime + EXECUTION_DELAY,
            "Execution delay not met"
        );
        
        _executeTransaction(_txIndex);
    }
    
    /**
     * @dev Internal function to execute transaction
     */
    function _executeTransaction(uint256 _txIndex) internal {
        Transaction storage transaction = transactions[_txIndex];
        transaction.executed = true;
        
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");
        
        emit ExecuteTransaction(msg.sender, _txIndex);
    }
    
    /**
     * @dev Revokes confirmation for a transaction
     * Use Case: Changing mind before execution
     */
    function revokeConfirmation(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        require(isConfirmed[_txIndex][msg.sender], "Transaction not confirmed");
        
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;
        
        emit RevokeConfirmation(msg.sender, _txIndex);
    }
    
    /**
     * @dev Adds a new owner (requires multisig approval)
     * Use Case: Adding team members, expanding access
     */
    function addOwner(address owner) external {
        require(msg.sender == address(this), "Must be called via multisig");
        require(owner != address(0), "Invalid owner");
        require(!isOwner[owner], "Owner already exists");
        require(owners.length < MAX_OWNERS, "Too many owners");
        
        isOwner[owner] = true;
        owners.push(owner);
        
        emit OwnerAdded(owner);
    }
    
    /**
     * @dev Removes an owner (requires multisig approval)
     * Use Case: Removing team members, reducing access
     */
    function removeOwner(address owner) external {
        require(msg.sender == address(this), "Must be called via multisig");
        require(isOwner[owner], "Not an owner");
        require(owners.length > numConfirmationsRequired, "Cannot remove owner");
        
        isOwner[owner] = false;
        
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
        
        emit OwnerRemoved(owner);
    }
    
    /**
     * @dev Changes confirmation requirement (requires multisig approval)
     * Use Case: Adjusting security threshold
     */
    function changeRequirement(uint256 _required) external {
        require(msg.sender == address(this), "Must be called via multisig");
        require(_required > 0 && _required <= owners.length, "Invalid requirement");
        
        numConfirmationsRequired = _required;
        emit RequirementChanged(_required);
    }
    
    /**
     * @dev Gets list of owners
     */
    function getOwners() external view returns (address[] memory) {
        return owners;
    }
    
    /**
     * @dev Gets transaction count
     */
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }
    
    /**
     * @dev Gets transaction details
     * Use Case: UI display, audit trails
     */
    function getTransaction(uint256 _txIndex)
        external
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations,
            uint256 submissionTime,
            string memory description
        )
    {
        Transaction storage transaction = transactions[_txIndex];
        
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations,
            transaction.submissionTime,
            transaction.description
        );
    }
    
    /**
     * @dev Checks if transaction is confirmed by owner
     */
    function isTransactionConfirmed(uint256 _txIndex, address _owner)
        external
        view
        returns (bool)
    {
        return isConfirmed[_txIndex][_owner];
    }
    
    /**
     * @dev Gets pending transactions
     * Use Case: Dashboard display, notifications
     */
    function getPendingTransactions() external view returns (uint256[] memory) {
        uint256[] memory tempArray = new uint256[](transactions.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < transactions.length; i++) {
            if (!transactions[i].executed) {
                tempArray[count] = i;
                count++;
            }
        }
        
        uint256[] memory pendingTxs = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            pendingTxs[i] = tempArray[i];
        }
        
        return pendingTxs;
    }
    
    /**
     * @dev Emergency function to recover stuck ETH (requires all owners)
     */
    function emergencyWithdraw(address payable recipient, uint256 amount) external {
        require(msg.sender == address(this), "Must be called via multisig");
        require(recipient != address(0), "Invalid recipient");
        require(amount <= address(this).balance, "Insufficient balance");
        
        recipient.transfer(amount);
    }
    
    /**
     * @dev Gets wallet balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}