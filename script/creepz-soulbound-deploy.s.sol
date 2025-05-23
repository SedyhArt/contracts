// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/CreepzSoulbound.sol";

contract DeployCreepzSoulbound is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        string memory baseURI = "https://api.creepz.com/soulbound/metadata/";

        vm.startBroadcast(privateKey);

        CreepzSoulbound nft = new CreepzSoulbound(baseURI);

        console.log("=== DEPLOYMENT SUCCESS ===");
        console.log("Contract address:", address(nft));
        console.log("Owner:", nft.owner());
        console.log("Name:", nft.name());
        console.log("Symbol:", nft.symbol());
        console.log("Base URI:", nft.getBaseTokenURI());
        console.log("==========================");

        vm.stopBroadcast();
    }
}