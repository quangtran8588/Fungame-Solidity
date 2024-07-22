import { ethers } from "hardhat";
import { fetchTickerPrice, Response } from "./fetchTickerPrice";

const symbol = process.env.SYMBOL as string;
const RETRY_DELAY_MS = 30000; //  fetch ticker price re-try
const LOOP_DELAY_MS = 60000;

// Function to fetch price with retries
async function fetchPriceWithRetries(
  symbol: string,
  retries: number,
  delay: number,
): Promise<string | undefined> {
  console.log("\nFetch Ticker price .....");
  for (let i = 0; i < retries; i++) {
    console.log(`Attempt ${i + 1} .....`);

    const result: Response = await fetchTickerPrice(symbol);

    if (result.error) {
      console.error(
        `Fetch price attempt ${i + 1} failed:`,
        result.error.message,
      );
      await new Promise((res) => setTimeout(res, delay));
    } else return result.ticker?.price;
  }
  return undefined;
}

async function main() {
  const provider = ethers.provider;
  const [Deployer] = await ethers.getSigners();

  console.log("Deployer account:", Deployer.address);
  console.log(
    "Account balance:",
    (await provider.getBalance(Deployer.address)).toString(),
  );

  //  Create Fungame contract instance
  const FunGame = "0x0A7c4C6ff5f218231B0A5e7Ac98Ab44D5B64B798";
  const fungame = await ethers.getContractAt("Fungame", FunGame, Deployer);

  //  Get startGame and settings
  const startGame = await fungame.START_TIME();
  const settings = await fungame.settings();

  while (true) {
    const currentGameId = await fungame.currentGame();
    console.log(`\nUpdate Game ${currentGameId} result .....`);

    if (currentGameId !== BigInt(0)) {
      const waitTime = Number(
        startGame +
          currentGameId * settings.windowTime -
          BigInt(Math.floor(Date.now() / 1000)),
      );
      if (waitTime > 0) {
        console.log(`Waiting for ${waitTime} seconds...`);
        await new Promise((res) => setTimeout(res, waitTime * 1000));
      }
    }
    const tickerPrice = await fetchPriceWithRetries(symbol, 3, RETRY_DELAY_MS);
    if (tickerPrice === undefined)
      throw new Error("Unable to fetch Ticker price after 3 attempts");

    const price: string = parseFloat(tickerPrice).toFixed(2);
    const tx = await fungame.callResult(ethers.parseUnits(price, 2));
    console.log("Tx Hash: ", tx.hash);
    await tx.wait();

    console.log(`\nUpdate Game ${currentGameId} result completed`);

    // Delay before next iteration
    await new Promise((res) => setTimeout(res, LOOP_DELAY_MS));
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
