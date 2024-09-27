pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Eth-betting.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";



contract EthBettingTest is Test {
    EthBetting public ethBetting;
    MockV3Aggregator public mockPriceFeed;
    address public creator = address(1);
    address public challenger = address(2);
    uint256 public constant INITIAL_BALANCE = 10 ether;
    uint256 public constant PLATFORM_COMMISSION_PERCENT = 10;
    address public owner = address(3);
    address public nonOwner = address(4);

    function setUp() public {
        vm.startPrank(owner);
        mockPriceFeed = new MockV3Aggregator(0, 2000 * 10**18);
        ethBetting = new EthBetting(address(mockPriceFeed));
        vm.deal(creator, INITIAL_BALANCE);
        vm.deal(challenger, INITIAL_BALANCE);
        vm.stopPrank();
    }

    function testGetLatestPrice() public {
        int price = ethBetting.getLatestPrice();
        console.log("Current ETH/USD price:", uint(price));
        assertGt(price, 0, "Price should be greater than 0");
    }

    function testCreateBet() public {

        vm.expectRevert(EthBetting.InsufficientStake.selector);
        _createBet(0 ether, true, 10);

        vm.expectRevert(EthBetting.InvalidPredictionPercentage.selector);
        _createBet(10 ether, true, 0);

        // Create bet
        _createBet(1 ether, true, 10);
        // Get the created bet
        EthBetting.Bet memory bet = ethBetting.getBet(0);

        // Assert bet details
        assertEq(bet.id, 0, "Bet ID should be 0");
        assertEq(bet.creatorAddress, address(this), "Creator address should match");
        assertEq(bet.stakeAmount, 1 ether, "Stake amount should match");
        assertEq(bet.predictionDirection, true, "Prediction direction should match");
        assertEq(bet.predictionPercentage, 10, "Prediction percentage should match");
        assertEq(uint(bet.status), uint(EthBetting.BetStatus.PendingForTheChallenger), "Bet status should be PendingForTheChallenger");

        // Logs
        console.log("Bet ID:", bet.id);
        console.log("Creator Address:", bet.creatorAddress);
        console.log("Stake Amount:", bet.stakeAmount);
        console.log("Prediction Direction:", bet.predictionDirection ? "Up" : "Down");
        console.log("Prediction Percentage:", bet.predictionPercentage);
        console.log("Start Price:", uint(bet.startPrice));
        console.log("Start Time:", bet.startTime);

    }

    function testJoinBet() public {
        vm.startPrank(creator);
        // Create bet with creator account
        uint256 betId = _createBet(1 ether, true, 10);
        vm.stopPrank();
        vm.startPrank(challenger);

        uint256 ethAmountToJoin = ethBetting.getBet(betId).stakeAmount;

        console.log("CREATOR ADDRESS BEFORE CHALLENGER JOIN: ", ethBetting.getBet(0).creatorAddress);

        vm.expectRevert(EthBetting.InsufficientStake.selector);
        ethBetting.joinBet{value: ethAmountToJoin / 2}(0);

        // Join the bet with challenger account
        ethBetting.joinBet{value: ethAmountToJoin}(0);

        vm.expectRevert(EthBetting.BetNotPending.selector);
        ethBetting.joinBet{value: ethAmountToJoin}(0);

        // Get the bet
        EthBetting.Bet memory bet = ethBetting.getBet(0);

        // Assert bet details
        console.log('BALANCE', address(ethBetting).balance);
        assertEq((bet.endTime - bet.startTime) / 60 / 60 / 24,  7, 'Bet must end in 7 days');
        assertEq(bet.creatorAddress, creator, "Creator should be equal to creator address");
        assertEq(bet.challengerAddress, challenger, "Challenger should be equal to challenger address");
        assertEq(uint(bet.status), uint(EthBetting.BetStatus.Active), "Bet status should be Active");
        assertEq(bet.stakeAmount + ethBetting.totalCommission(), 2 ether, "Stake amount plus commissions should be equal to 2 Eth");

        // Logs
        console.log("STAKE AMOUNT IN ETH", bet.stakeAmount);
        console.log("CHALLENGER ADDRESS", bet.challengerAddress);
        console.log("CREATOR ADDRESS", bet.creatorAddress);
        console.log("ADDRESSES: ", ethBetting.getBet(0).creatorAddress);

        vm.stopPrank();
    }

    function testCalcPercentPriceChange() public {
        console.log("CALC PERCENT", ethBetting.calcPriceChangePercent(100, 120));
        assertEq(ethBetting.calcPriceChangePercent(100, 120), 20);
        assertEq(ethBetting.calcPriceChangePercent(2200, 2530), 15);
    }


    function testFinishBet() public {
        vm.startPrank(creator);

        // Create bet with creator account
        uint256 betId = _createBet(1 ether, true, 10);
        vm.stopPrank();
        vm.startPrank(challenger);

        EthBetting.Bet memory bet = ethBetting.getBet(betId);

        uint256 ethAmountToJoin = bet.stakeAmount;

//         Try to finish bet before it was started
        vm.expectRevert(EthBetting.BetNotActive.selector);
        ethBetting.finishBet(betId);

//         Join the bet with challenger account
        ethBetting.joinBet{value: ethAmountToJoin}(0);

//         Try to finish bet before end time has come
        vm.expectRevert(EthBetting.BetEndTimeHasNotComeYet.selector);
        ethBetting.finishBet(betId);

        uint256 currentTimestamp = block.timestamp;

        vm.warp(currentTimestamp + 8 days);
        mockPriceFeed.updateAnswer(2100 * 10**18);

        // Finishing bet
        ethBetting.finishBet(betId);

        vm.expectRevert(EthBetting.BetIsAlreadyFinished.selector);
        ethBetting.finishBet(betId);

        EthBetting.Bet memory finishedBet = ethBetting.getBet(betId);

        assertEq(finishedBet.winner, challenger, 'Challenger address should be winner');
        assertEq(uint(finishedBet.status), uint(EthBetting.BetStatus.Finished), "Bet status should be Finish");

        console.log("WINNER", finishedBet.winner);
        console.log("WINNER BALANCE", finishedBet.winner.balance);
    }

    function testWithdraw() public {
        //Creating and finishing bet
        vm.startPrank(creator);
        uint256 betId = _createBet(1 ether, true, 10);
        vm.stopPrank();
        vm.startPrank(challenger);
        EthBetting.Bet memory bet = ethBetting.getBet(betId);
        uint256 ethAmountToJoin = bet.stakeAmount;
        ethBetting.joinBet{value: ethAmountToJoin}(0);
        uint256 currentTimestamp = block.timestamp;
        vm.warp(currentTimestamp + 8 days);
        mockPriceFeed.updateAnswer(2100 * 10**18);

        vm.expectRevert(EthBetting.BetIsStillActive.selector);
        ethBetting.withdraw(betId);

        ethBetting.finishBet(betId);
        vm.stopPrank();

        // Try withdraw with looser account
        vm.startPrank(creator);
        vm.expectRevert(EthBetting.NotAuthorized.selector);
        ethBetting.withdraw(betId);
        vm.stopPrank();

        uint256 winnerBalanceBeforeWithdraw = challenger.balance;
        uint256 contractBalanceBeforeWithdraw = address(ethBetting).balance;

        // Calculating gas cost
        uint256 gasBefore = gasleft();
        vm.startPrank(challenger);
        ethBetting.withdraw(betId);
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;
        uint256 gasCost = gasUsed * tx.gasprice;

        // Should be reverted because it's already paid
        vm.expectRevert(EthBetting.BetIsAlreadyPaid.selector);
        ethBetting.withdraw(betId);

        uint256 actualBalanceChange = challenger.balance - winnerBalanceBeforeWithdraw;
        uint256 expectedBalanceChange = contractBalanceBeforeWithdraw;

        console.log("Actual balance change:", actualBalanceChange);
        console.log("Expected balance change:", expectedBalanceChange);
        console.log("Gas cost:", gasCost);

        assertApproxEqRel(
            actualBalanceChange,
            expectedBalanceChange - gasCost,
            1e17,
            "Winner should collect prize minus gas costs (within 1% tolerance)"
        );
        vm.stopPrank();
    }

    function testWithdrawCommission() public {
        vm.startPrank(creator);
        uint256 betId = _createBet(1 ether, true, 10);
        vm.stopPrank();
        vm.startPrank(challenger);
        EthBetting.Bet memory bet = ethBetting.getBet(betId);
        uint256 ethAmountToJoin = bet.stakeAmount;
        ethBetting.joinBet{value: ethAmountToJoin}(0);
        uint256 currentTimestamp = block.timestamp;
        vm.warp(currentTimestamp + 8 days);
        mockPriceFeed.updateAnswer(2100 * 10**18);
        ethBetting.finishBet(betId);
        vm.stopPrank();

        vm.expectRevert(EthBetting.NotAuthorized.selector);
        ethBetting.withdrawCommission();

        vm.startPrank(owner);
        ethBetting.withdrawCommission();

        assertEq(ethBetting.totalCommission(), 0);
    }

    function testPriceChange() public {
        assertEq(ethBetting.getLatestPrice(), 2000 * 10**18);
        mockPriceFeed.updateAnswer(2200 * 10 ** 18);
        assertEq(ethBetting.getLatestPrice(), 2200 * 10**18);
    }

    function _createBet(uint256 _ethAmount, bool _predictionDirection, uint256 _predictionPercent ) private returns (uint256) {
        // Create a bet
        uint256 _betId = ethBetting.createBet{value: _ethAmount}(_predictionDirection, _predictionPercent);
        vm.stopPrank();
        return _betId;
    }
}


