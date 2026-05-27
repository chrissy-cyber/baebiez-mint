require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const privateKey = process.env.PRIVATE_KEY || "";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      evmVersion: "cancun",
    },
  },
  networks: {
    apechain: {
      url: process.env.APECHAIN_RPC_URL || "https://rpc.apechain.com/http",
      chainId: 33139,
      accounts: privateKey ? [privateKey] : [],
    },
    apechainTestnet: {
      url: process.env.APECHAIN_TESTNET_RPC_URL ||
        "https://curtis.rpc.caldera.xyz/http",
      chainId: 33111,
      accounts: privateKey ? [privateKey] : [],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || "placeholder",
    customChains: [
      {
        network: "apechainTestnet",
        chainId: 33111,
        urls: {
          apiURL: "https://curtis.explorer.caldera.xyz/api",
          browserURL: "https://curtis.explorer.caldera.xyz"
        }
      },
      {
        network: "apechain",
        chainId: 33139,
        urls: {
          apiURL: "https://api.apescan.io/api",
          browserURL: "https://apescan.io"
        }
      }
    ]
  },
};
