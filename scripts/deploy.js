const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Starting Nibert Investments Blockchain Infrastructure Deployment");
  console.log("===============================================================");
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("🔑 Deploying contracts with account:", deployer.address);
  console.log("💰 Account balance:", ethers.utils.formatEther(await deployer.getBalance()), "ETH");
  
  // Deploy contracts in order
  const deployments = {};
  
  try {
    // 1. Deploy NibertToken (foundational token)
    console.log("\n📍 1. Deploying NibertToken...");
    const NibertToken = await ethers.getContractFactory("NibertToken");
    const nibertToken = await NibertToken.deploy();
    await nibertToken.deployed();
    deployments.NibertToken = nibertToken.address;
    console.log("✅ NibertToken deployed to:", nibertToken.address);
    
    // 2. Deploy MultiSigWallet (governance infrastructure)
    console.log("\n📍 2. Deploying MultiSigWallet...");
    const MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
    const owners = [deployer.address]; // In production, use multiple owners
    const requiredConfirmations = 1; // In production, use higher threshold
    const multiSigWallet = await MultiSigWallet.deploy(owners, requiredConfirmations);
    await multiSigWallet.deployed();
    deployments.MultiSigWallet = multiSigWallet.address;
    console.log("✅ MultiSigWallet deployed to:", multiSigWallet.address);
    
    // 3. Deploy PriceOracle (price feed infrastructure)
    console.log("\n📍 3. Deploying PriceOracle...");
    const PriceOracle = await ethers.getContractFactory("PriceOracle");
    const priceOracle = await PriceOracle.deploy();
    await priceOracle.deployed();
    deployments.PriceOracle = priceOracle.address;
    console.log("✅ PriceOracle deployed to:", priceOracle.address);
    
    // 4. Deploy LiquidityPool (DeFi infrastructure)
    console.log("\n📍 4. Deploying LiquidityPool...");
    const LiquidityPool = await ethers.getContractFactory("LiquidityPool");
    const liquidityPool = await LiquidityPool.deploy(
      nibertToken.address,
      nibertToken.address, // Using same token for simplicity in demo
      ethers.utils.parseEther("1000") // Initial liquidity
    );
    await liquidityPool.deployed();
    deployments.LiquidityPool = liquidityPool.address;
    console.log("✅ LiquidityPool deployed to:", liquidityPool.address);
    
    // 5. Deploy StakingRewards (staking infrastructure)
    console.log("\n📍 5. Deploying StakingRewards...");
    const StakingRewards = await ethers.getContractFactory("StakingRewards");
    const stakingRewards = await StakingRewards.deploy(
      nibertToken.address, // Staking token
      nibertToken.address  // Reward token
    );
    await stakingRewards.deployed();
    deployments.StakingRewards = stakingRewards.address;
    console.log("✅ StakingRewards deployed to:", stakingRewards.address);
    
    // 6. Deploy NibertDAO (governance)
    console.log("\n📍 6. Deploying NibertDAO...");
    const NibertDAO = await ethers.getContractFactory("NibertDAO");
    const nibertDAO = await NibertDAO.deploy(nibertToken.address);
    await nibertDAO.deployed();
    deployments.NibertDAO = nibertDAO.address;
    console.log("✅ NibertDAO deployed to:", nibertDAO.address);
    
    // 7. Deploy YieldFarm (farming infrastructure)
    console.log("\n📍 7. Deploying YieldFarm...");
    const YieldFarm = await ethers.getContractFactory("YieldFarm");
    const yieldFarm = await YieldFarm.deploy(
      nibertToken.address, // Staking token
      nibertToken.address, // Reward token
      ethers.utils.parseEther("0.1") // Reward rate per block
    );
    await yieldFarm.deployed();
    deployments.YieldFarm = yieldFarm.address;
    console.log("✅ YieldFarm deployed to:", yieldFarm.address);
    
    // 8. Deploy VestingContract (token distribution)
    console.log("\n📍 8. Deploying VestingContract...");
    const VestingContract = await ethers.getContractFactory("VestingContract");
    const vestingContract = await VestingContract.deploy(nibertToken.address);
    await vestingContract.deployed();
    deployments.VestingContract = vestingContract.address;
    console.log("✅ VestingContract deployed to:", vestingContract.address);
    
    // 9. Deploy InsurancePool (risk management)
    console.log("\n📍 9. Deploying InsurancePool...");
    const InsurancePool = await ethers.getContractFactory("InsurancePool");
    const insurancePool = await InsurancePool.deploy(
      nibertToken.address,
      ethers.utils.parseEther("1") // Minimum coverage amount
    );
    await insurancePool.deployed();
    deployments.InsurancePool = insurancePool.address;
    console.log("✅ InsurancePool deployed to:", insurancePool.address);
    
    // 10. Deploy NFTMarketplace (marketplace infrastructure)
    console.log("\n📍 10. Deploying NFTMarketplace...");
    const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    const nftMarketplace = await NFTMarketplace.deploy(
      250 // 2.5% marketplace fee
    );
    await nftMarketplace.deployed();
    deployments.NFTMarketplace = nftMarketplace.address;
    console.log("✅ NFTMarketplace deployed to:", nftMarketplace.address);
    
    // Summary
    console.log("\n🎉 DEPLOYMENT COMPLETE!");
    console.log("=======================");
    console.log("📊 Deployment Summary:");
    Object.entries(deployments).forEach(([name, address]) => {
      console.log(`   ${name}: ${address}`);
    });
    
    console.log("\n🔧 Next Steps:");
    console.log("1. Verify contracts on blockchain explorer");
    console.log("2. Set up initial governance parameters");
    console.log("3. Configure oracle price feeds");
    console.log("4. Add initial liquidity to pools");
    console.log("5. Test all contract interactions");
    
    // Save deployment addresses to file
    const fs = require('fs');
    fs.writeFileSync(
      'deployment-addresses.json',
      JSON.stringify(deployments, null, 2)
    );
    console.log("\n💾 Deployment addresses saved to: deployment-addresses.json");
    
  } catch (error) {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });