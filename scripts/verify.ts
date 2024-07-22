import hre from "hardhat";

async function main() {
  console.log("Verify Points Contract ......");
  const Points = "0x60F152d9aA873f58aC8dba88134DCCabb760f413";
  const initialOwner = "0x31003C2D5685c7D28D7174c3255307Eb9a0f3015";
  const cooldown = 2 * 60;
  const amount = BigInt(100);

  await hre.run("verify:verify", {
    address: Points,
    constructorArguments: [initialOwner, cooldown, amount],
  });

  console.log("Verify Fungame Contract ......");
  const Fungame = "0xDf5320d72285033beda9c587CffC248aE00a2f43";
  const startTime = 1721016000;
  const initSettings = {
    freeGuessPerDay: 3,
    fixedReward: 20,
    windowTime: 3600, //  1 hour per game
    lockoutTime: 900, //  15mins lockout
  };

  await hre.run("verify:verify", {
    address: Fungame,
    constructorArguments: [initialOwner, startTime, Points, initSettings],
  });

  console.log("\n===== DONE =====");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
