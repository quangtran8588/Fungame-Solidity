import { ethers } from "hardhat";
import { Fungame, Fungame__factory } from "../typechain-types";

async function main() {
  const provider = ethers.provider;
  const [Deployer] = await ethers.getSigners();

  console.log("Deployer account:", Deployer.address);
  console.log(
    "Account balance:",
    (await provider.getBalance(Deployer.address)).toString(),
  );

  //  Deploy Fungame contract
  console.log("\nDeploy Fungame Contract .........");
  const initialOwner = Deployer.address;
  const startTime = 1721116500; // replace by your starting time
  const Points = "";
  const initSettings = {
    freeGuessPerDay: 3,
    fixedReward: 20,
    windowTime: 3600, //  1 hour per game
    lockoutTime: 900, //  15 minutes lockout time
  };

  const Fungame = (await ethers.getContractFactory(
    "Fungame",
    Deployer,
  )) as Fungame__factory;
  const fungame: Fungame = await Fungame.deploy(
    initialOwner,
    startTime,
    Points,
    initSettings,
  );
  console.log("Tx Hash: %s", fungame.deploymentTransaction()?.hash);
  await fungame.deploymentTransaction()?.wait();

  console.log("Fungame Contract: ", await fungame.getAddress());

  //  Set Deployed as Operator contract
  console.log("\nSet Operator of Fun Game contract .........");
  let tx = await fungame.setOperator(await Deployer.getAddress(), true);
  console.log("Tx Hash: ", tx.hash);
  await tx.wait();

  //  Set Deployed as Operator contract
  console.log("\nSet Operator of Points contract .........");
  const points = await ethers.getContractAt("Points", Points, Deployer);
  tx = await points.setOperator(await fungame.getAddress(), true);
  console.log("Tx Hash: ", tx.hash);
  await tx.wait();

  console.log("\n===== DONE =====");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
