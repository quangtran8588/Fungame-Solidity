# Fungame

The `Fungame` is written using Solidity. It contains two contracts:

- `Points`: a record-keeping contract (not using ERC-20)
- `Fungame`: a guessing game contract.
  - Players submit their guess for a pair (either UP or DOWN).
  - The contract manages infinite mini-games.
  - Each game has:
    - `windowTime`: Time period per game (in seconds).
    - `lockoutTime`: Time period which guessing submission is not allowed (in seconds).
  - Game settings can be configurable:
    - `freeGuessPerDay`: a number of allowance guessing per day (per `account`).
    - `fixedReward`: a reward per correct guessing.

Note:

- The `Fungame` comes with Front-end to interact with contracts (Full DApp). You can take a look at this repo: [https://github.com/quangtran8588/Fungame-FE](https://github.com/quangtran8588/Fungame-FE).
- It requires a lightweight service (AWS Lambda) to fetch pair price from Exchange Market (e.g. Binance), then update to the `Fungame` smart contract and finalize a result of one mini-game.

### Prerequisites:

- NodeJS: `v20.14.0` or newer [Download link](https://nodejs.org/en/download/package-manager)

### Running an experiment:

- Install dependencies

```bash
yarn
```

- Create `.env` file:

```bash
touch .env && open .env
```

- Copy the following content into a newly created `.env`:

```bash
# API Key on Base Scan Explorer
BASE_API_KEY=<YOUR_API_KEY>

# Base Testnet Provider
BASE_TESTNET_RPC=<YOUR_RPC>

# Deployer (Testnet) Private Key
TESTNET_DEPLOYER=<YOUR_PRIVATE_KEY>

PRICE_TICKER_API="https://api.binance.com/api/v3/ticker/price"
SYMBOL="BTCUSDT"
```

- Deploy `Points` contract:

```bash
yarn base_test scripts/deployPoints.ts
```

- Deploy `Fungame` contract:

```bash
//  Note: Take a look at `deployFungame.ts` and replace by your settings
//  - Points: replace by your deployed Points contract address
//  - startTime: replace by your `START_TIME`
//  - initSettings: replace by your customized settings

yarn base_test scripts/deployFungame.ts
```
