// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library NetworkConfig {
    struct EthUsdConfig {
        address mainnet;
        address sepolia;
    }

    function GetEthUsdConfig() internal pure returns (EthUsdConfig memory) {
        return EthUsdConfig({
            mainnet: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
            sepolia: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
    }
}