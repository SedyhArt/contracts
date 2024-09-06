// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "forge-std/console.sol";
import "./Network-config.sol";

contract EthBetting {
    uint32 public bettingStartTimestamp;
    uint32 public bettingEndTimestamp;
    int public startedPrice;
    AggregatorV3Interface internal priceFeed;

    struct BettingPrediction {
        uint256 changedInPercent;
        bool increase;
    }

    BettingPrediction public currentBetting;

    constructor(bool isMainnet) {
        NetworkConfig.EthUsdConfig memory config = NetworkConfig.GetEthUsdConfig();
        address aggregatorAddress = isMainnet ? config.mainnet : config.sepolia;
        priceFeed = AggregatorV3Interface(aggregatorAddress);
    }

    function startBetting(uint256 _changedPercent, bool _increase) payable public {
        address(this).transfer(msg.value);
        currentBetting.changedInPercent = _changedPercent;
        currentBetting.increase = _increase;
        startedPrice = getLatestPrice();
    }

    function getLatestPrice() public view returns (int) {
        (,int price,,,
        ) = priceFeed.latestRoundData();
        console.log(price);
        return price;
    }
}