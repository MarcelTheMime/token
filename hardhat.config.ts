import * as dotenv from "dotenv"

import type { HardhatUserConfig } from "hardhat/config"
import "@nomiclabs/hardhat-waffle"
import "@nomiclabs/hardhat-ethers"
import "@nomiclabs/hardhat-etherscan"
import "@typechain/hardhat"
import "hardhat-deploy"
import "solidity-coverage"
import "hardhat-gas-reporter"
import "hardhat-contract-sizer"
import "@appliedblockchain/chainlink-plugins-fund-link"
import "./tasks"

dotenv.config()


const PRIVATE_KEY = process.env.PRIVATE_KEY;
const bscScann = process.env.BSC_SCANN;

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    bsctestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
      saveDeployments: false,
      chainId: 97,
    }
  },
  etherscan: {
    apiKey: {
      bscTestnet: bscScann,
      bsc: bscScann
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    // coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
      1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
    feeCollector: {
      default: 1,
    },
  },
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    }
  },
  mocha: {
    timeout: 200000, // 200 seconds max for running tests
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
}

export default config
