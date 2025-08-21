// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title NibertToken - ERC20 Token for Nibert Investments Ecosystem
 * @dev A comprehensive ERC20 token with advanced features including:
 *      - Minting and burning capabilities
 *      - Transfer restrictions for compliance
 *      - Pausable functionality for emergency stops
 *      - Role-based access control
 * 
 * USE CASES:
 * 1. Governance voting in Nibert Investments DAO
 * 2. Staking rewards distribution
 * 3. Platform fee discounts for token holders
 * 4. Liquidity mining incentives
 * 5. Revenue sharing through token burns
 * 
 * WHY IT WORKS:
 * - Follows OpenZeppelin standards for security
 * - Implements proven token mechanics
 * - Includes emergency controls for risk management
 * - Extensible design for future upgrades
 * 
 * @author Nibert Investments Development Team
 * @notice This contract implements a feature-rich ERC20 token
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract NibertToken is IERC20 {
    // Token metadata
    string public constant name = "Nibert Investment Token";
    string public constant symbol = "NIT";
    uint8 public constant decimals = 18;
    
    // Token economics
    uint256 private _totalSupply;
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10**decimals; // 100M tokens
    
    // State variables
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isBlacklisted;
    
    // Access control
    address public owner;
    address public minter;
    bool public paused;
    
    // Events
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Pause();
    event Unpause();
    event BlacklistUpdated(address indexed account, bool status);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "NIT: caller is not the owner");
        _;
    }
    
    modifier onlyMinter() {
        require(msg.sender == minter || msg.sender == owner, "NIT: caller is not authorized to mint");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "NIT: token transfer while paused");
        _;
    }
    
    modifier notBlacklisted(address account) {
        require(!isBlacklisted[account], "NIT: account is blacklisted");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        minter = msg.sender;
        
        // Initial mint to deployer (10% of max supply)
        uint256 initialSupply = 10_000_000 * 10**decimals;
        _totalSupply = initialSupply;
        _balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }
    
    /**
     * @dev Returns the total token supply
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev Returns the token balance of an account
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev Transfers tokens from caller to recipient
     * Use Case: Standard token transfers, payments, rewards distribution
     */
    function transfer(address to, uint256 amount) 
        public 
        override 
        whenNotPaused 
        notBlacklisted(msg.sender) 
        notBlacklisted(to) 
        returns (bool) 
    {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    /**
     * @dev Returns the allowance amount
     */
    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }
    
    /**
     * @dev Approves spender to transfer tokens on behalf of caller
     * Use Case: DEX trading, staking contracts, automated payments
     */
    function approve(address spender, uint256 amount) 
        public 
        override 
        whenNotPaused 
        notBlacklisted(msg.sender) 
        returns (bool) 
    {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @dev Transfers tokens from one account to another using allowance
     * Use Case: DEX swaps, automated payments, contract interactions
     */
    function transferFrom(address from, address to, uint256 amount) 
        public 
        override 
        whenNotPaused 
        notBlacklisted(from) 
        notBlacklisted(to) 
        returns (bool) 
    {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "NIT: transfer amount exceeds allowance");
        
        _transfer(from, to, amount);
        _approve(from, msg.sender, currentAllowance - amount);
        
        return true;
    }
    
    /**
     * @dev Mints new tokens to specified address
     * Use Case: Staking rewards, liquidity mining, ecosystem growth incentives
     */
    function mint(address to, uint256 amount) external onlyMinter notBlacklisted(to) {
        require(to != address(0), "NIT: mint to the zero address");
        require(_totalSupply + amount <= MAX_SUPPLY, "NIT: minting would exceed max supply");
        
        _totalSupply += amount;
        _balances[to] += amount;
        
        emit Transfer(address(0), to, amount);
        emit Mint(to, amount);
    }
    
    /**
     * @dev Burns tokens from caller's balance
     * Use Case: Revenue sharing, deflationary mechanisms, protocol buybacks
     */
    function burn(uint256 amount) external whenNotPaused {
        require(_balances[msg.sender] >= amount, "NIT: burn amount exceeds balance");
        
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        
        emit Transfer(msg.sender, address(0), amount);
        emit Burn(msg.sender, amount);
    }
    
    /**
     * @dev Pauses all token transfers (emergency function)
     * Use Case: Security incidents, major protocol upgrades, regulatory requirements
     */
    function pause() external onlyOwner {
        paused = true;
        emit Pause();
    }
    
    /**
     * @dev Unpauses token transfers
     */
    function unpause() external onlyOwner {
        paused = false;
        emit Unpause();
    }
    
    /**
     * @dev Updates blacklist status for an account
     * Use Case: Compliance requirements, sanctioned addresses, malicious actors
     */
    function updateBlacklist(address account, bool status) external onlyOwner {
        isBlacklisted[account] = status;
        emit BlacklistUpdated(account, status);
    }
    
    /**
     * @dev Sets the authorized minter address
     * Use Case: Changing minting permissions, protocol upgrades
     */
    function setMinter(address newMinter) external onlyOwner {
        require(newMinter != address(0), "NIT: new minter is the zero address");
        minter = newMinter;
    }
    
    /**
     * @dev Transfers ownership of the contract
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "NIT: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    /**
     * @dev Internal transfer function
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "NIT: transfer from the zero address");
        require(to != address(0), "NIT: transfer to the zero address");
        require(_balances[from] >= amount, "NIT: transfer amount exceeds balance");
        
        _balances[from] -= amount;
        _balances[to] += amount;
        
        emit Transfer(from, to, amount);
    }
    
    /**
     * @dev Internal approve function
     */
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "NIT: approve from the zero address");
        require(spender != address(0), "NIT: approve to the zero address");
        
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }
}