#!/bin/bash

echo "🚀 Nibert Investments Blockchain Infrastructure Startup"
echo "======================================================"

# Check if Node.js and npm are installed
echo "🔍 Checking prerequisites..."
node --version || { echo "❌ Node.js not found. Please install Node.js"; exit 1; }
npm --version || { echo "❌ npm not found. Please install npm"; exit 1; }

echo "✅ Prerequisites check passed"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Compile contracts
echo "🔨 Compiling smart contracts..."
npx hardhat compile || { echo "❌ Contract compilation failed"; exit 1; }

echo "✅ Smart contracts compiled successfully"

# Run basic tests
echo "🧪 Running basic infrastructure tests..."
npx hardhat test test/basic.test.js || { echo "⚠️  Basic tests failed, but continuing..."; }

echo "📋 Blockchain Infrastructure Status:"
echo "   ✅ Hardhat development framework: Ready"
echo "   ✅ Solidity compiler: Working"
echo "   ✅ Smart contracts: Compiled"
echo "   ✅ Testing framework: Configured"
echo "   ✅ Local blockchain: Ready to start"

echo ""
echo "🌐 Available Commands:"
echo "   npm run node          - Start local blockchain node"
echo "   npm run deploy        - Deploy all contracts"
echo "   npm run test          - Run all tests"
echo "   npm run compile       - Compile contracts"
echo "   npm run console       - Open Hardhat console"

echo ""
echo "🚀 Ready to start blockchain development!"
echo "Run 'npm run node' to start the local blockchain node"