# BAEBIEZ Mainnet Deploy Steps

## Contract Status

- Collection max supply: `4444`
- Tokens already minted on prior launchpad: `919`
- First token minted by this contract: `920`
- Remaining supply before new mints/airdrops: `3525`
- Starting phase after deploy: `CLOSED`
- GTD: `31 APE`, max `20` per wallet
- FCFS: `31 APE`, max `20` per wallet
- Public: `99 APE`, max `50` per wallet

## Option A: Deploy With Hardhat

1. Create a local `.env` file from `.env.example`.
2. Put the deployer wallet private key in `.env`.
3. Make sure the deployer wallet has enough APE for gas on ApeChain.
4. Run:

```bash
npm run compile
npm test
npm run deploy:apechain
```

5. Copy the deployed contract address.
6. Put that address into `index.html` as `CONTRACT_ADDRESS`.
7. Keep `MINT_LOCKED=true` until you are ready to open minting.
8. Deploy the site:

```bash
vercel deploy --prod --yes
```

## Option B: Deploy With Remix

1. Open `contracts/BAEBIEZ.sol` in Remix.
2. Compile with Solidity `0.8.28`.
3. Use Injected Provider/MetaMask on ApeChain.
4. Deploy `BAEBIEZ`.
5. Copy the deployed contract address.
6. Put that address into `index.html` as `CONTRACT_ADDRESS`.
7. Deploy the site with Vercel.

## Before Opening Phases

- Set GTD Merkle root.
- Set FCFS Merkle root.
- Confirm airdrop recipient/quantity batches.
- Keep the site locked until the contract address and allowlist proof flow are ready.
