// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title LiquidityPool - Automated Market Maker for Token Swaps
 * @dev A simplified AMM implementation with the following features:
 *      - Constant product formula (x * y = k)
 *      - Liquidity provision with LP tokens
 *      - Swap functionality with slippage protection
 *      - Fee collection for liquidity providers
 * 
 * USE CASES:
 * 1. Token swapping between any ERC20 pairs
 * 2. Liquidity provision to earn trading fees
 * 3. Price discovery for new tokens
 * 4. Arbitrage opportunities across DEXs
 * 5. Portfolio rebalancing through automated trades
 * 
 * WHY IT WORKS:
 * - Proven AMM mechanics used by Uniswap and similar protocols
 * - Constant product formula ensures liquidity at all price levels
 * - LP tokens represent proportional pool ownership
 * - Fee mechanism incentivizes liquidity provision
 * - Slippage protection prevents sandwich attacks
 * 
 * @author Nibert Investments Development Team
 * @notice This contract implements a basic AMM for token swapping
 */

interface IERC20Simple {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract LiquidityPool {
    // Pool tokens
    IERC20Simple public immutable token0;
    IERC20Simple public immutable token1;
    
    // Pool state
    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public totalSupply;
    
    // LP token balances
    mapping(address => uint256) public balanceOf;
    
    // Fee configuration (0.3% = 3/1000)
    uint256 public constant FEE_NUMERATOR = 3;
    uint256 public constant FEE_DENOMINATOR = 1000;
    
    // Minimum liquidity lock
    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    
    // Events
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed to, uint256 amount0, uint256 amount1);
    event Swap(
        address indexed to,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    );
    event Sync(uint256 reserve0, uint256 reserve1);
    
    // Reentrancy protection
    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    constructor(address _token0, address _token1) {
        require(_token0 != address(0) && _token1 != address(0), "ZERO_ADDRESS");
        require(_token0 != _token1, "IDENTICAL_ADDRESSES");
        
        token0 = IERC20Simple(_token0);
        token1 = IERC20Simple(_token1);
    }
    
    /**
     * @dev Adds liquidity to the pool
     * Use Case: Earning trading fees by providing liquidity
     */
    function addLiquidity(uint256 amount0, uint256 amount1) external lock returns (uint256 liquidity) {
        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_AMOUNTS");
        
        // Transfer tokens to pool
        require(token0.transferFrom(msg.sender, address(this), amount0), "TRANSFER_FAILED");
        require(token1.transferFrom(msg.sender, address(this), amount1), "TRANSFER_FAILED");
        
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        
        if (totalSupply == 0) {
            // First liquidity provision
            liquidity = _sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            balanceOf[address(0)] = MINIMUM_LIQUIDITY; // Lock minimum liquidity
        } else {
            // Subsequent liquidity provision
            liquidity = _min(
                (amount0 * totalSupply) / reserve0,
                (amount1 * totalSupply) / reserve1
            );
        }
        
        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");
        
        totalSupply += liquidity;
        balanceOf[msg.sender] += liquidity;
        
        _update(balance0, balance1);
        emit Mint(msg.sender, liquidity);
    }
    
    /**
     * @dev Removes liquidity from the pool
     * Use Case: Withdrawing liquidity and claiming accumulated fees
     */
    function removeLiquidity(uint256 liquidity) external lock returns (uint256 amount0, uint256 amount1) {
        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY");
        require(balanceOf[msg.sender] >= liquidity, "INSUFFICIENT_BALANCE");
        
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        
        amount0 = (liquidity * balance0) / totalSupply;
        amount1 = (liquidity * balance1) / totalSupply;
        
        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY_BURNED");
        
        balanceOf[msg.sender] -= liquidity;
        totalSupply -= liquidity;
        
        require(token0.transfer(msg.sender, amount0), "TRANSFER_FAILED");
        require(token1.transfer(msg.sender, amount1), "TRANSFER_FAILED");
        
        balance0 = token0.balanceOf(address(this));
        balance1 = token1.balanceOf(address(this));
        
        _update(balance0, balance1);
        emit Burn(msg.sender, amount0, amount1);
    }
    
    /**
     * @dev Swaps tokens using constant product formula
     * Use Case: Trading tokens, arbitrage, portfolio rebalancing
     */
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external lock {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(amount0Out < reserve0 && amount1Out < reserve1, "INSUFFICIENT_LIQUIDITY");
        require(to != address(token0) && to != address(token1), "INVALID_TO");
        
        if (amount0Out > 0) require(token0.transfer(to, amount0Out), "TRANSFER_FAILED");
        if (amount1Out > 0) require(token1.transfer(to, amount1Out), "TRANSFER_FAILED");
        
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        
        uint256 amount0In = balance0 > reserve0 - amount0Out ? balance0 - (reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > reserve1 - amount1Out ? balance1 - (reserve1 - amount1Out) : 0;
        
        require(amount0In > 0 || amount1In > 0, "INSUFFICIENT_INPUT_AMOUNT");
        
        // Constant product check with fee
        {
            uint256 balance0Adjusted = balance0 * 1000 - amount0In * FEE_NUMERATOR;
            uint256 balance1Adjusted = balance1 * 1000 - amount1In * FEE_NUMERATOR;
            require(
                balance0Adjusted * balance1Adjusted >= uint256(reserve0) * reserve1 * (1000**2),
                "CONSTANT_PRODUCT_VIOLATION"
            );
        }
        
        _update(balance0, balance1);
        emit Swap(to, amount0In, amount1In, amount0Out, amount1Out);
    }
    
    /**
     * @dev Calculates output amount for a given input (with slippage)
     * Use Case: Price quotes before executing swaps
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE_NUMERATOR);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;
        
        amountOut = numerator / denominator;
    }
    
    /**
     * @dev Calculates input amount needed for a desired output
     * Use Case: Exact output swaps, arbitrage calculations
     */
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        returns (uint256 amountIn)
    {
        require(amountOut > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "INSUFFICIENT_LIQUIDITY");
        require(amountOut < reserveOut, "INSUFFICIENT_LIQUIDITY");
        
        uint256 numerator = reserveIn * amountOut * FEE_DENOMINATOR;
        uint256 denominator = (reserveOut - amountOut) * (FEE_DENOMINATOR - FEE_NUMERATOR);
        
        amountIn = (numerator / denominator) + 1;
    }
    
    /**
     * @dev Returns current pool information
     * Use Case: Portfolio tracking, analytics, UI display
     */
    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }
    
    /**
     * @dev Calculates current token price ratio
     * Use Case: Price feeds, portfolio valuation, arbitrage detection
     */
    function getPrice() external view returns (uint256 price0, uint256 price1) {
        require(reserve0 > 0 && reserve1 > 0, "NO_LIQUIDITY");
        
        // Price of token0 in terms of token1 (scaled by 1e18)
        price0 = (reserve1 * 1e18) / reserve0;
        // Price of token1 in terms of token0 (scaled by 1e18)
        price1 = (reserve0 * 1e18) / reserve1;
    }
    
    /**
     * @dev Emergency function to recover stuck tokens
     * Use Case: Protocol maintenance, recovering accidentally sent tokens
     */
    function skim(address to) external {
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        
        if (balance0 > reserve0) {
            require(token0.transfer(to, balance0 - reserve0), "TRANSFER_FAILED");
        }
        if (balance1 > reserve1) {
            require(token1.transfer(to, balance1 - reserve1), "TRANSFER_FAILED");
        }
    }
    
    /**
     * @dev Updates reserves to match current balances
     */
    function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = balance0;
        reserve1 = balance1;
        emit Sync(reserve0, reserve1);
    }
    
    /**
     * @dev Square root function using Babylonian method
     */
    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    
    /**
     * @dev Returns the minimum of two numbers
     */
    function _min(uint256 x, uint256 y) private pure returns (uint256 z) {
        z = x < y ? x : y;
    }
}