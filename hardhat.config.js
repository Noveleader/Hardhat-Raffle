require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

/** @type import('hardhat/config').HardhatUserConfig */
const GOERLI_URL = process.env.GOERLI_RPC_URL
const PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY
const SEPOLIA_URL = process.env.SEPOLIA_RPC_URL
const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
            blockConfirmations: 1,
        },
        goerli: {
            chainId: 5,
            blockConfirmations: 6,
            url: GOERLI_URL,
            accounts: [PRIVATE_KEY],
        },
        sepolia: {
            chainId: 11155111,
            blockConfirmations: 6,
            url: SEPOLIA_URL,
            accounts: [SEPOLIA_PRIVATE_KEY],
        },
    },
    gasReporter: {
        enabled: false,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
    },
    solidity: "0.8.17",
    namedAccounts: {
        deployer: {
            default: 0,
        },
        player: {
            default: 1,
        },
    },
    mocha: {
        timeout: 300000, // 300 seconds max
        // If some event doesn't fire, the test will fail after this time
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },
}
