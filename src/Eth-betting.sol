pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";



contract EthBetting {
    // Structs
    struct Bet {
        uint256 id;
        address creatorAddress;
        address challengerAddress;
        address winner;
        uint256 stakeAmount;
        bool predictionDirection;
        uint256 predictionPercentage;
        int startPrice;
        int endPrice;
        uint256 startTime;
        uint256 endTime;
        BetStatus status;
        bool paid;
    }

    error BettingIsAlreadyStarted();
    error InsufficientStake();
    error InvalidPredictionPercentage();
    error BetNotPending();
    error BetNotActive();
    error BetIsStillActive();
    error BetIsAlreadyFinished();
    error BetEndTimeHasNotComeYet();
    error AddressUnableToSendEth();
    error NotAuthorized();
    error BetIsAlreadyPaid();

    // Enums
    enum BetStatus { Active, PendingForTheChallenger, Finished }

    // State variables
    AggregatorV3Interface internal priceFeed;
    uint256 public constant PLATFORM_COMMISSION_PERCENT = 10;
    uint256 public nextBetId;
    uint256 public totalCommission;
    address public owner;

    // Mappings
    mapping(uint256 => Bet) private betStorage;

    // Events
    event BetCreated(uint256 indexed betId, address indexed creator, uint256 stakeAmount);
    event BetJoined(uint256 indexed betId, address indexed challenger);
    event BetFinished(uint256 indexed betId, address indexed winner);
    event CommissionCollected(uint256 amount);
    event Withdraw(address winner, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotAuthorized();
        _;
    }

    constructor(address _priceFeedAddress) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        owner = msg.sender;
    }

    // External functions
    function createBet(bool predictionDirection, uint256 predictionPercentage) external payable returns(uint256) {
        if (msg.value == 0) revert InsufficientStake();
        if (predictionPercentage == 0) revert InvalidPredictionPercentage();

        int currentPrice = getLatestPrice();
        uint256 betId = nextBetId++;

        betStorage[betId] = Bet({
            id: betId,
            creatorAddress: msg.sender,
            challengerAddress: address(0),
            winner: address(0),
            stakeAmount: msg.value,
            predictionDirection: predictionDirection,
            predictionPercentage: predictionPercentage,
            startPrice: currentPrice,
            endPrice: 0,
            startTime: block.timestamp,
            endTime: 0,
            status: BetStatus.PendingForTheChallenger,
            paid: false
        });

        emit BetCreated(betId, msg.sender, msg.value);
        return betId;
    }

    function joinBet(uint256 betId) external payable {
        Bet storage bet = betStorage[betId];
        if (bet.status != BetStatus.PendingForTheChallenger) revert BetNotPending();
        if (msg.value < bet.stakeAmount) revert InsufficientStake();

        // Bet will end in 7 days
        bet.endTime = block.timestamp + 7 * 24 * 60 * 60;

        bet.challengerAddress = msg.sender;
        bet.status = BetStatus.Active;

        uint256 commission = (bet.stakeAmount * 2 * PLATFORM_COMMISSION_PERCENT) / 100;
        totalCommission += commission;
        bet.stakeAmount = bet.stakeAmount * 2 - commission;

        emit BetJoined(betId, msg.sender);
        emit CommissionCollected(commission);
    }

    function finishBet(uint256 betId) external payable {
        Bet storage bet = betStorage[betId];

        if (bet.status == BetStatus.Finished) revert BetIsAlreadyFinished();
        if (bet.status != BetStatus.Active) revert BetNotActive();
        if (bet.endTime >= block.timestamp) revert BetEndTimeHasNotComeYet();

        int currentPrice = getLatestPrice();
        bet.endPrice = currentPrice;

        // true if price has increased
        bool changedDirection = bet.endPrice > bet.startPrice;
        uint256 pricePercentChanged = calcPriceChangePercent(bet.startPrice, bet.endPrice);
        address winner = changedDirection == bet.predictionDirection && pricePercentChanged >= bet.predictionPercentage ? bet.creatorAddress : bet.challengerAddress;

        bet.status = BetStatus.Finished;
        bet.winner = winner;

        emit BetFinished(betId, winner);
    }

    function withdraw(uint256 betId) public {
        Bet storage bet = betStorage[betId];
        if (bet.status != BetStatus.Finished) revert BetIsStillActive();
        if (msg.sender != bet.winner) revert NotAuthorized();
        if (bet.paid) revert BetIsAlreadyPaid();

        uint256 amount = bet.stakeAmount;
        bet.paid = true;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    function withdrawCommission() external onlyOwner {
        uint256 commission = totalCommission;
        totalCommission = 0;
        (bool success, ) = owner.call{value: commission}("");
        require(success, "Commission transfer failed");
    }


    function calcPriceChangePercent(int startPrice, int endPrice) public returns (uint256) {
        int priceChange = endPrice - startPrice;
        uint256 absolutePriceChange = uint256(priceChange < 0 ? -priceChange : priceChange);
        uint256 pricePercentChanged = (absolutePriceChange * 100) / uint256(startPrice);
        return pricePercentChanged;
    }

    function getLatestPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price;
    }

    function getBet(uint256 betId) external view returns (Bet memory) {
        return betStorage[betId];
    }

//    function getCreatingBetById(uint256 betId) public view returns (Bet memory) {
//        return creatingBet[betId];
//    }
//
//    function getActiveBetById(uint256 betId) public view returns (Bet memory) {
//        return activeBet[betId];
//    }
//
//    function getFinishedBetById(uint256 betId) public view returns (Bet memory) {
//        return finishedBet[betId];
//    }
}