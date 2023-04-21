// Raffle
// Enter the lottery (paying some amount)
// Pick a winner randmoly (verifiable random)
// Winner to be selected after every x minutes -> completely automated
// Chainlink Oracle -> Randomness, automated execution (Chainlink keeper)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

// Error codes
error Raffle__NotEnoughETHEntered();
error Raffle_TransferFailed();

contract Raffle is VRFConsumerBaseV2 {
    // State variables
    uint256 private immutable i_entranceFee; //cuz we don't need to change it
    address payable[] private s_players; //payable because we want these players' addresses to be payable in case they win the lottery
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callBackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3; //caps and underscore for constant variables
    uint16 private constant NUM_WORDS = 1; //we want 1 random number

    // Lottery Variables
    address private s_recentWinner;

    // Events
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callBackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        // we add constructor for VRFConsumerBaseV2 also as required
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;
    }

    function enterRaffle() public payable {
        if(msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        s_players.push(payable(msg.sender)); //wrapping to make the address payable
        // Emit an event when we update a dynamic array or mapping
        // Nmaed events with the function name reversed
        emit RaffleEnter(msg.sender);
    }

    function requestRandomWinner() external {
        // Request the random number
        // Once we get it, do something with it
        // 2 transaction process
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //keyHash / Gaslane
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callBackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    // we are naming it with words but it is actually for numbers (multiple numbers)
    // this overrides the function in the VRFConsumerBaseV2 contract. the VRFConsumerBaseV2 contract already expects to be overriden and the declaration is virtual there
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) 
        internal 
        override
    {
        uint256 indexOfWinner = randomWords[0]%s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success)
        if(!success) {
            revert Raffle_TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }


    //pure functions/view functions
    function getEntranceFee() public view returns(uint256) {
        return i_entranceFee;
    }
    function getPlayer(uint256 index) public view returns(address payable) {
        return s_players[index];
    }
    function getRecentWinner(address) public view returns(address) {
        return s_recentWinner;
    }

}