/**
 * Main.js - Core Web3 Utilities and Blockchain Interaction Module
 * 
 * Purpose: Provides essential Web3 functionality including wallet management,
 * smart contract interaction, and blockchain utilities for Nibert Investments
 * 
 * Use Cases:
 * 1. Wallet connection and management
 * 2. Smart contract deployment and interaction  
 * 3. Transaction monitoring and analysis
 * 4. Token balance tracking
 * 5. DeFi protocol integration
 * 
 * @author Nibert Investments
 * @version 1.0.0
 * @license MIT
 */

// Core Web3 utility class for blockchain interactions
class Web3Utils {
    constructor() {
        this.networkConfig = {
            ethereum: {
                chainId: 1,
                name: 'Ethereum Mainnet',
                rpcUrl: 'https://eth-mainnet.g.alchemy.com/v2/your-api-key'
            },
            polygon: {
                chainId: 137,
                name: 'Polygon Mainnet', 
                rpcUrl: 'https://polygon-mainnet.g.alchemy.com/v2/your-api-key'
            },
            bsc: {
                chainId: 56,
                name: 'Binance Smart Chain',
                rpcUrl: 'https://bsc-dataseed.binance.org/'
            }
        };
        
        this.supportedTokens = [
            { symbol: 'ETH', name: 'Ethereum', decimals: 18 },
            { symbol: 'MATIC', name: 'Polygon', decimals: 18 },
            { symbol: 'BNB', name: 'Binance Coin', decimals: 18 },
            { symbol: 'USDC', name: 'USD Coin', decimals: 6 },
            { symbol: 'USDT', name: 'Tether USD', decimals: 6 }
        ];
    }

    /**
     * Validates an Ethereum address
     * Use Case: Input validation for wallet addresses and contract interactions
     */
    isValidAddress(address) {
        if (!address) return false;
        return /^0x[a-fA-F0-9]{40}$/.test(address);
    }

    /**
     * Formats token amounts with proper decimals
     * Use Case: Display token balances in user interfaces
     */
    formatTokenAmount(amount, decimals = 18) {
        if (!amount) return '0';
        const divisor = Math.pow(10, decimals);
        return (parseInt(amount) / divisor).toFixed(6);
    }

    /**
     * Generates a transaction hash for tracking
     * Use Case: Transaction monitoring and audit trails
     */
    generateTxHash() {
        return '0x' + Math.random().toString(16).substr(2, 64);
    }

    /**
     * Calculates gas fees for different network conditions
     * Use Case: Gas optimization for cost-effective transactions
     */
    calculateGasFee(gasLimit, gasPriceGwei) {
        const gasPrice = gasPriceGwei * 1e9; // Convert Gwei to Wei
        const totalCost = gasLimit * gasPrice;
        return this.formatTokenAmount(totalCost.toString(), 18);
    }

    /**
     * Portfolio tracker for multiple wallets
     * Use Case: Investment monitoring and performance analysis
     */
    async trackPortfolio(walletAddresses) {
        const portfolio = {
            totalValue: 0,
            wallets: [],
            lastUpdated: new Date().toISOString()
        };

        for (const address of walletAddresses) {
            if (this.isValidAddress(address)) {
                portfolio.wallets.push({
                    address: address,
                    balance: Math.random() * 10, // Mock balance
                    tokens: this.supportedTokens.map(token => ({
                        ...token,
                        balance: Math.random() * 1000
                    }))
                });
            }
        }

        return portfolio;
    }

    /**
     * Smart contract interaction helper
     * Use Case: Standardized contract calls across different protocols
     */
    async callContract(contractAddress, method, params = []) {
        if (!this.isValidAddress(contractAddress)) {
            throw new Error('Invalid contract address');
        }

        // Mock contract interaction
        return {
            txHash: this.generateTxHash(),
            status: 'success',
            gasUsed: Math.floor(Math.random() * 100000) + 21000,
            blockNumber: Math.floor(Math.random() * 1000000) + 18000000,
            result: `Called ${method} on ${contractAddress}`
        };
    }

    /**
     * DeFi yield farming calculator
     * Use Case: Investment strategy optimization
     */
    calculateYield(principal, apy, timeInDays) {
        const dailyRate = apy / 365 / 100;
        const compoundedAmount = principal * Math.pow(1 + dailyRate, timeInDays);
        return {
            principal: principal,
            yield: compoundedAmount - principal,
            totalAmount: compoundedAmount,
            apy: apy,
            timeInDays: timeInDays
        };
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = Web3Utils;
}

// Example usage and demonstration
if (require.main === module) {
    console.log('🚀 Web3 Utils - Nibert Investments');
    console.log('===================================');
    
    const web3Utils = new Web3Utils();
    
    // Demonstrate functionality
    console.log('\n📊 Portfolio Tracking Demo:');
    const mockWallets = ['0x742d35Cc6346C17c01b5f84Ff6043ECC2C79e0BB'];
    web3Utils.trackPortfolio(mockWallets).then(portfolio => {
        console.log('Portfolio Value:', JSON.stringify(portfolio, null, 2));
    });
    
    console.log('\n💰 Yield Calculation Demo:');
    const yieldCalc = web3Utils.calculateYield(1000, 12.5, 365);
    console.log('Yield Analysis:', yieldCalc);
    
    console.log('\n⛽ Gas Fee Demo:');
    const gasFee = web3Utils.calculateGasFee(21000, 20);
    console.log('Gas Fee (ETH):', gasFee);
    
    console.log('\n✅ Address Validation Demo:');
    console.log('Valid address:', web3Utils.isValidAddress('0x742d35Cc6346C17c01b5f84Ff6043ECC2C79e0BB'));
    console.log('Invalid address:', web3Utils.isValidAddress('invalid'));
}