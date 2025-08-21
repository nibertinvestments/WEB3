const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("🚀 Basic Blockchain Infrastructure Test", function () {
  
  it("✅ Should connect to Hardhat network", async function () {
    const [deployer] = await ethers.getSigners();
    expect(deployer.address).to.be.properAddress;
    
    const balance = await deployer.getBalance();
    expect(balance.gt(0)).to.be.true;
  });
  
  it("✅ Should compile and access contract artifacts", async function () {
    // Try to get contract factory without deploying
    const NibertToken = await ethers.getContractFactory("NibertToken");
    expect(NibertToken).to.not.be.undefined;
  });
  
  it("✅ Should have correct network configuration", async function () {
    const network = await ethers.provider.getNetwork();
    expect(network.chainId).to.equal(31337);
  });
  
  it("✅ Should be able to mine blocks", async function () {
    const initialBlock = await ethers.provider.getBlockNumber();
    
    // Mine a block by making a transaction
    const [deployer] = await ethers.getSigners();
    await deployer.sendTransaction({
      to: deployer.address,
      value: 0
    });
    
    const newBlock = await ethers.provider.getBlockNumber();
    expect(newBlock).to.be.greaterThan(initialBlock);
  });
  
  it("✅ Environment should be configured properly", function () {
    expect(process.env.PRIVATE_KEY).to.be.a('string');
    expect(process.env.NIBERT_CHAIN_ID).to.be.a('string');
  });
  
});