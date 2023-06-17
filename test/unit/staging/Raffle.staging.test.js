const { assert, expect } = require("chai")
const { getNamedAccounts, deployments, ethers, network } = require("hardhat")
const { developmentChains, networkConfig } = require("../../../helper-hardhat-config")

// so here if the development chains have the network name means we are on testnet so we won't be doing staging tests
developmentChains.includes(network.name)
    ? describe.skip
    : describe("Raffle Staging Tests", function () {
          let raffle, raffleEntranceFee, deployer
          beforeEach(async function () {
              deployer = (await getNamedAccounts()).deployer
              raffle = await ethers.getContract("raffle", deployer)
              raffleEntranceFee = await raffle.getEntranceFee()
          })

          describe("fulfillRandomness", function () {
              it("works with live chainlink keepers and chainlink VRF, we get a random winner", async function () {
                  // enter the raffle
                  const startingTimeStamp = await raffle.getLatestTimeStamp()
                  const deployerAccount = await ethers.getSigners()
                  // setting up the listener
                  // just in case the blockchain moves really fast
                  console.log("Setting up Listener...")
                  await new Promise(async (resolve, reject) => {
                      raffle.once("WinnerPicked", async () => {
                          console.log("WinnerPicked event fired")
                          try {
                              const recentWinner = await raffle.getRecentWinner()
                              const raffleState = await raffle.getRaffleState()
                              const winnerEndingBalance = await accounts[0].getBalance()
                              const endingTimeStamp = await raffle.getLatestTimeStamp()
                              await expect(raffle.getPlayer(0)).to.be.reverted
                              assert.equal(recentWinner.toString(), accounts[0].address)
                              assert.equal(raffleState, 0)
                              assert.equal(
                                  winnerEndingBalance.toString(),
                                  winnerStartingBalance.add(raffleEntranceFee).toString()
                              )
                              assert(endingTimeStamp > startingTimeStamp)
                              resolve()
                          } catch (error) {
                              console.log(error)
                              reject(error)
                          }
                      })
                  })
                  // Then entering the raffle
                  console.log("Entering Raffle...")
                  const tx = await raffle.enterRaffle({ value: raffleEntranceFee })
                  await tx.wait(1)
                  console.log("Ok, time to wait...")
                  const winnerStartingBalance = await accounts[0].getBalance()
                  // this code won't complete until the listener has finished listening
                  // once a resolve or reject need to be executed in order to complete the promise
              })
          })
      })
