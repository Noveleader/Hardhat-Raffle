const { developmentChains } = require("../helper-hardhat-config")
const BASE_FEE = ethers.utils.parseEther("0.25") //0.25 is the premium. It costs 0.25 link to get a random function run
const GAS_PRICE_LINK = 1e9 //link per gas// calculated value based on the gas price of the chain.

//Eth price : $1 billion
// Chainlink Nodes pay the gas fees to give us randomness & do external execution
// So the price of requests change based on the price of gas
// Chainlink nodes are incentivized to run the nodes on the cheapest chains
module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const args = [BASE_FEE, GAS_PRICE_LINK]
    if (developmentChains.includes(network.name)) {
        log("Local Network detected! Deploying mocks")
        // deploy mock contracts for vrfcoordinator
        await deploy("VRFCoordinatorV2Mock", {
            from: deployer,
            log: true,
            args: args,
        })
        log("Mocks Deployed!")
        log("-----------------------------------------------------")
    }
}
module.exports.tags = ["all", "mocks"]
