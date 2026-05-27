const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying BAEBIEZ with:", deployer.address);
  console.log("Network:", hre.network.name);

  const BAEBIEZ = await hre.ethers.getContractFactory("BAEBIEZ");
  const baebiez = await BAEBIEZ.deploy();
  await baebiez.waitForDeployment();

  const address = await baebiez.getAddress();
  console.log("BAEBIEZ deployed to:", address);
  console.log("First new token ID:", (await baebiez.START_TOKEN_ID()).toString());
  console.log("Prior minted:", (await baebiez.PRIOR_MINTED()).toString());
  console.log("Total minted shown to site:", (await baebiez.totalMinted()).toString());
  console.log("Remaining supply:", (await baebiez.totalRemaining()).toString());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
