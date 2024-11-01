const { ethers } = require("hardhat");

async function main() {
  const network = await ethers.provider.getNetwork();
  console.log(`Connected to network: ${network.name}`);
  console.log(`Network ID: ${network.chainId}`);

  const blockNumber = await ethers.provider.getBlockNumber();
  console.log(`Current Block Number: ${blockNumber}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
