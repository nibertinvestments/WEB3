const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Nibert Investments Blockchain Node Setup");
  console.log("===========================================");
  
  // Get network information
  const network = await ethers.provider.getNetwork();
  const [deployer] = await ethers.getSigners();
  
  console.log("📡 Network Information:");
  console.log(`   Chain ID: ${network.chainId}`);
  console.log(`   Network Name: ${network.name || 'localhost'}`);
  console.log(`   Deployer Address: ${deployer.address}`);
  console.log(`   Deployer Balance: ${ethers.utils.formatEther(await deployer.getBalance())} ETH`);
  
  console.log("\n🔧 Blockchain Configuration:");
  console.log(`   Gas Price: ${ethers.utils.formatUnits(await ethers.provider.getGasPrice(), 'gwei')} gwei`);
  console.log(`   Current Block: ${await ethers.provider.getBlockNumber()}`);
  
  console.log("\n✅ Blockchain node is ready for development!");
  console.log("\n🔗 Connection Details:");
  console.log("   RPC URL: http://127.0.0.1:8545");
  console.log("   Chain ID: 31337");
  console.log("   Currency: ETH");
  
  console.log("\n📋 Next Steps:");
  console.log("1. Run 'npm run deploy' to deploy smart contracts");
  console.log("2. Connect MetaMask to http://127.0.0.1:8545");
  console.log("3. Import the test private key for development");
  console.log("4. Start building your DApp!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });