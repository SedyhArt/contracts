// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/CreepzSoulbound.sol";

contract CreepzSoulboundTest is Test {
    CreepzSoulbound nft;
    address owner = address(this);
    address user1 = address(0xBEEF);
    address user2 = address(0xCAFE);
    string constant uri = "ipfs://QmTemporarySoulboundPlaceholderHash";

    function setUp() public {
        nft = new CreepzSoulbound(uri);
    }

    function testOwnerCanMint() public {
        nft.mint(user1);
        assertEq(nft.balanceOf(user1), 1);
        assertTrue(nft.hasSoul(user1));
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.tokenURI(1), uri);
    }

    function testCannotMintTwiceToSameAddress() public {
        nft.mint(user1);
        vm.expectRevert("Already minted for this address");
        nft.mint(user1);
    }

    function testCannotTransferSoulbound() public {
        nft.mint(user1);
        vm.prank(user1);
        vm.expectRevert("Soulbound: token is non-transferable");
        nft.transferFrom(user1, user2, 1);
    }

    function testCannotSafeTransferSoulbound() public {
        nft.mint(user1);
        vm.prank(user1);
        vm.expectRevert("Soulbound: token is non-transferable");
        nft.safeTransferFrom(user1, user2, 1);
    }

    function testCannotApprove() public {
        nft.mint(user1);
        vm.prank(user1);
        vm.expectRevert("Soulbound: non-transferable");
        nft.approve(address(0x456), 1);
    }

    function testCannotSetApprovalForAll() public {
        vm.prank(user1);
        vm.expectRevert("Soulbound: non-transferable");
        nft.setApprovalForAll(address(0x456), true);
    }

    function testOnlyOwnerCanMint() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.mint(user2);
    }

    function testMultipleMints() public {
        nft.mint(user1);
        nft.mint(user2);

        assertEq(nft.balanceOf(user1), 1);
        assertEq(nft.balanceOf(user2), 1);
        assertTrue(nft.hasSoul(user1));
        assertTrue(nft.hasSoul(user2));
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user2);
    }

    function testSetBaseTokenURI() public {
        string memory newUri = "ipfs://QmNewHash";
        nft.setBaseTokenURI(newUri);
        assertEq(nft.getBaseTokenURI(), newUri);
    }

    function testOnlyOwnerCanSetBaseURI() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.setBaseTokenURI("ipfs://QmHackerHash");
    }

    function testTokenURIAfterBaseURIChange() public {
        nft.mint(user1);
        string memory newUri = "ipfs://QmNewHash";
        nft.setBaseTokenURI(newUri);

        assertEq(nft.tokenURI(1), uri);

        nft.mint(user2);
        assertEq(nft.tokenURI(2), newUri);
    }

    function testSupportsInterface() public {
        // ERC721
        assertTrue(nft.supportsInterface(0x80ac58cd));
        // ERC721Metadata
        assertTrue(nft.supportsInterface(0x5b5e139f));
        // ERC165
        assertTrue(nft.supportsInterface(0x01ffc9a7));
    }

    function testNameAndSymbol() public {
        assertEq(nft.name(), "creepz-playtest");
        assertEq(nft.symbol(), "CPT");
    }
}