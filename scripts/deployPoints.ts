import { ethers } from "hardhat";
import { Points, Points__factory } from "../typechain-types";

async function main() {
  const provider = ethers.provider;
  const [Deployer] = await ethers.getSigners();

  console.log("Deployer account:", Deployer.address);
  console.log(
    "Account balance:",
    (await provider.getBalance(Deployer.address)).toString(),
  );

  //  Deploy Points contract
  console.log("\nDeploy Points Contract .........");
  const initialOwner = Deployer.address;
  const cooldown = 2 * 60; //  2mins
  const amount = BigInt(100);

  const Points = (await ethers.getContractFactory(
    "Points",
    Deployer,
  )) as Points__factory;
  const points: Points = await Points.deploy(initialOwner, cooldown, amount);
  console.log("Tx Hash: %s", points.deploymentTransaction()?.hash);
  await points.deploymentTransaction()?.wait();

  console.log("Points Contract: ", await points.getAddress());

  console.log("\n===== DONE =====");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
