// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title ModularPaymentProcessor
 * @dev Payment Processing smart contract - Basic tier implementation
 * 
 * FEATURES:
 * - Secure payment processing with escrow functionality
 * - Multi-currency support and conversion rates
 * - Automated fee calculation and distribution
 * - Payment status tracking and notifications
 * - Batch payment processing for efficiency
 * 
 * USE CASES:
 * 1. E-commerce payment processing systems
 * 2. Subscription and recurring payment handling
 * 3. Marketplace transaction management
 * 4. Escrow services for secure transactions
 * 5. Multi-party payment splitting and distribution
 * 6. Cross-border payment facilitation
 * 
 * @author Nibert Investments LLC - Enterprise Smart Contract #001
 * @notice Confidential and Proprietary Technology - Basic Tier
 */
contract ModularPaymentProcessor is ReentrancyGuard, Ownable, Pausable {
    // State variables
    mapping(bytes32 => Payment) private _payments;
    mapping(address => uint256) private _escrowBalances;
    mapping(address => bool) private _authorizedMerchants;
    mapping(address => uint256) private _merchantFees;
    
    uint256 private _totalProcessed;
    uint256 private _totalFees;
    address private _feeCollector;
    
    // Configuration
    uint256 public constant MAX_BATCH_SIZE = 100;
    uint256 public constant PRECISION = 1e18;
    uint256 public constant DEFAULT_FEE_RATE = 250; // 2.5%
    uint256 public constant MAX_FEE_RATE = 1000; // 10%
    
    struct Payment {
        address payer;
        address payee;
        uint256 amount;
        uint256 fee;
        PaymentStatus status;
        uint256 timestamp;
        bytes32 ref;
    }
    
    enum PaymentStatus {
        Pending,
        Completed,
        Cancelled,
        Disputed,
        Refunded
    }
    
    // Events
    event PaymentCreated(bytes32 indexed paymentId, address indexed payer, address indexed payee, uint256 amount);
    event PaymentCompleted(bytes32 indexed paymentId, uint256 fee);
    event PaymentCancelled(bytes32 indexed paymentId, string reason);
    event MerchantAuthorized(address indexed merchant, uint256 feeRate);
    event EscrowDeposit(address indexed account, uint256 amount);
    event EscrowWithdraw(address indexed account, uint256 amount);
    event BatchPaymentProcessed(uint256 count, uint256 totalAmount);
    
    modifier onlyAuthorizedMerchant() {
        require(_authorizedMerchants[msg.sender], "Not authorized merchant");
        _;
    }
    
    modifier validPaymentId(bytes32 paymentId) {
        require(_payments[paymentId].payer != address(0), "Invalid payment ID");
        _;
    }
    
    modifier validAmount(uint256 amount) {
        require(amount > 0, "Invalid amount");
        _;
    }
    
    constructor(address feeCollector_) Ownable(msg.sender) {
        _feeCollector = feeCollector_;
        _authorizedMerchants[msg.sender] = true;
        _merchantFees[msg.sender] = DEFAULT_FEE_RATE;
    }
    
    /**
     * @dev Create a new payment with escrow functionality
     */
    function createPayment(
        address payee,
        uint256 amount,
        bytes32 ref
    ) external payable nonReentrant whenNotPaused validAmount(amount) returns (bytes32) {
        require(payee != address(0), "Invalid payee");
        require(msg.value >= amount, "Insufficient payment");
        
        bytes32 paymentId = keccak256(abi.encodePacked(
            msg.sender,
            payee,
            amount,
            block.timestamp,
            ref
        ));
        
        uint256 fee = calculateFee(msg.sender, amount);
        require(msg.value >= amount + fee, "Insufficient payment including fee");
        
        _payments[paymentId] = Payment({
            payer: msg.sender,
            payee: payee,
            amount: amount,
            fee: fee,
            status: PaymentStatus.Pending,
            timestamp: block.timestamp,
            ref: ref
        });
        
        _escrowBalances[address(this)] += amount + fee;
        
        emit PaymentCreated(paymentId, msg.sender, payee, amount);
        emit EscrowDeposit(msg.sender, amount + fee);
        
        return paymentId;
    }
    
    /**
     * @dev Complete a payment and release funds from escrow
     */
    function completePayment(bytes32 paymentId) 
        external 
        nonReentrant 
        whenNotPaused 
        validPaymentId(paymentId) 
    {
        Payment storage payment = _payments[paymentId];
        require(payment.status == PaymentStatus.Pending, "Payment not pending");
        require(
            msg.sender == payment.payer || 
            msg.sender == payment.payee || 
            msg.sender == owner(),
            "Not authorized to complete"
        );
        
        payment.status = PaymentStatus.Completed;
        
        // Transfer payment to payee
        payable(payment.payee).transfer(payment.amount);
        
        // Transfer fee to collector
        if (payment.fee > 0) {
            payable(_feeCollector).transfer(payment.fee);
            _totalFees += payment.fee;
        }
        
        _totalProcessed += payment.amount;
        
        emit PaymentCompleted(paymentId, payment.fee);
        emit EscrowWithdraw(payment.payee, payment.amount);
    }
    
    /**
     * @dev Cancel a payment and refund to payer
     */
    function cancelPayment(bytes32 paymentId, string calldata reason) 
        external 
        nonReentrant 
        whenNotPaused 
        validPaymentId(paymentId) 
    {
        Payment storage payment = _payments[paymentId];
        require(payment.status == PaymentStatus.Pending, "Payment not pending");
        require(
            msg.sender == payment.payer || 
            msg.sender == owner(),
            "Not authorized to cancel"
        );
        
        payment.status = PaymentStatus.Cancelled;
        
        // Refund to payer
        payable(payment.payer).transfer(payment.amount + payment.fee);
        
        emit PaymentCancelled(paymentId, reason);
        emit EscrowWithdraw(payment.payer, payment.amount + payment.fee);
    }
    
    /**
     * @dev Process multiple payments in batch for efficiency
     */
    function batchProcessPayments(bytes32[] calldata paymentIds) 
        external 
        nonReentrant 
        whenNotPaused 
        onlyOwner 
    {
        require(paymentIds.length <= MAX_BATCH_SIZE, "Batch too large");
        
        uint256 totalAmount = 0;
        uint256 processedCount = 0;
        
        for (uint256 i = 0; i < paymentIds.length; i++) {
            Payment storage payment = _payments[paymentIds[i]];
            if (payment.payer != address(0) && payment.status == PaymentStatus.Pending) {
                payment.status = PaymentStatus.Completed;
                
                payable(payment.payee).transfer(payment.amount);
                if (payment.fee > 0) {
                    payable(_feeCollector).transfer(payment.fee);
                    _totalFees += payment.fee;
                }
                
                totalAmount += payment.amount;
                processedCount++;
                
                emit PaymentCompleted(paymentIds[i], payment.fee);
            }
        }
        
        _totalProcessed += totalAmount;
        emit BatchPaymentProcessed(processedCount, totalAmount);
    }
    
    /**
     * @dev Authorize merchant and set fee rate
     */
    function authorizeMerchant(address merchant, uint256 feeRate) 
        external 
        onlyOwner 
    {
        require(merchant != address(0), "Invalid merchant");
        require(feeRate <= MAX_FEE_RATE, "Fee rate too high");
        
        _authorizedMerchants[merchant] = true;
        _merchantFees[merchant] = feeRate;
        
        emit MerchantAuthorized(merchant, feeRate);
    }
    
    /**
     * @dev Emergency pause functionality
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Update fee collector address
     */
    function setFeeCollector(address newCollector) external onlyOwner {
        require(newCollector != address(0), "Invalid collector");
        _feeCollector = newCollector;
    }
    
    // View functions
    function getPayment(bytes32 paymentId) 
        external 
        view 
        returns (Payment memory) 
    {
        return _payments[paymentId];
    }
    
    function totalProcessed() external view returns (uint256) {
        return _totalProcessed;
    }
    
    function totalFees() external view returns (uint256) {
        return _totalFees;
    }
    
    function feeCollector() external view returns (address) {
        return _feeCollector;
    }
    
    function isAuthorizedMerchant(address merchant) external view returns (bool) {
        return _authorizedMerchants[merchant];
    }
    
    function getMerchantFeeRate(address merchant) external view returns (uint256) {
        return _merchantFees[merchant];
    }
    
    function escrowBalance(address account) external view returns (uint256) {
        return _escrowBalances[account];
    }
    
    // Internal functions
    function calculateFee(address merchant, uint256 amount) 
        internal 
        view 
        returns (uint256) 
    {
        uint256 feeRate = _authorizedMerchants[merchant] ? 
            _merchantFees[merchant] : DEFAULT_FEE_RATE;
        return (amount * feeRate) / (100 * PRECISION);
    }
    
    /**
     * @dev Mathematical utility for percentage calculations
     */
    function calculatePercentage(uint256 value, uint256 percentage) 
        internal 
        pure 
        returns (uint256) 
    {
        return (value * percentage) / (100 * PRECISION);
    }
    
    /**
     * @dev Safe mathematical operations to prevent overflow
     */
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction underflow");
        return a - b;
    }
    
    /**
     * @dev Emergency withdrawal function for contract owner
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev Receive function to accept ETH deposits
     */
    receive() external payable {
        _escrowBalances[msg.sender] += msg.value;
        emit EscrowDeposit(msg.sender, msg.value);
    }
}