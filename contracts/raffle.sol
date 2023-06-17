//RAFFLE
//Enter the lottery (paying some amount)
// Pick a random winner (verifiably random)
// Winner to be selected every X minutes -> completely automated
// Chainlink Oracle -> Randomness, Automated Execution (Chainlink Keeper)

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughEth();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpKeepNotNeeded(uint256 cuurentBalance, uint256 numPlayers, uint256 raffleState);

/** @title A sample Raffle contract
 *  @author Ankush
 *  @notice This contract is for creating an untemperable decentralized smart contract
 *  @dev This implements Chainlink VRF v2 and Chainlink Keeper
 */

contract raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    } // uint256 0 = OPEN, 1 = CALCULATING

    /*State Variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionID;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /*Lottery Variables */
    address private s_recentWinner;
    //uint256 private s_state; // to pending, open closed, calculating - this can be difficult to keep track of
    // Here we introduce Enums - It can be used to create custome types with a finite set of 'constant values'
    RaffleState private s_rafflestate;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval; // immutable as it going to be constant, saving some gas

    /*Events*/
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2, //contract address
        uint256 _entranceFee,
        bytes32 gasLane,
        uint64 subscriptionID,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = _entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionID = subscriptionID;
        i_callbackGasLimit = callbackGasLimit;
        s_rafflestate = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    /*Functions */
    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth();
        }
        if (s_rafflestate != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        // Named events with the function name reveresed
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper node call
     * They look for the 'upkeepNeeded' function to return true
     * The folowing should be true in order to return true
     * 1. Our time interval should have passed
     * 2. Lottery should have atleast 1 player, and have some ETH
     * 3. Our subsciption is funded with link
     * 4. Lottery should be in 'open' state
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view override returns (bool upKeepNeeded, bytes memory /*performData*/) {
        bool isOpen = RaffleState.OPEN == s_rafflestate;
        // block.timestamp - last block timestamp >= interval How long we want to wait before lottery runs again
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);
        upKeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upKeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /*performData */) external override {
        //Request the random number
        // Once we get it, do something with it
        // 2 transaction process
        //taken from the website
        (bool upKeepNeeded, ) = checkUpkeep("0x0");
        if (!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_rafflestate)
            );
        }
        s_rafflestate = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //gas lane - A limit over how much you wanna spend on method call in wei.
            i_subscriptionID,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        ); // returns a uint256 request ID
        /** This is redundant, we can just use the emitted request ID from VRF coordinator */
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256,
        /*requestId*/ uint256[] memory randomWords
    ) internal override {
        // The random word is a uint256, a pretty long value (massive)
        // s_players size 10
        // random number 202
        // 202 % 10 = 2 use this index as a winner
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_rafflestate = RaffleState.OPEN; //reset the raffle state
        s_players = new address payable[](0); // reset the player's array
        s_lastTimeStamp = block.timestamp; // reset the last time stamp
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /**View and Pure functions */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_rafflestate;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    //maybe not needed
    function getStartingTimeStamp() public view returns (uint256) {
        return (s_lastTimeStamp - i_interval);
    }
}
