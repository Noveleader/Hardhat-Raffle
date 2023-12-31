const { ethers } = require("hardhat")

async function enterRaffle() {
    const raffle = await ethers.getContract("raffle")
    const entranceFee = await raffle.getEntranceFee()
    await raffle.enterRaffle({ value: entranceFee + 0.01 })
    console.log("Entered!")
}

enterRaffle()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
