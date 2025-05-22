//// SPDX-License-Identifier: MIT
//pragma solidity ^0.8.24;
//
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//
//contract CreepzSoulbound is ERC721URIStorage, Ownable {
//    uint256 private _nextTokenId = 1;
//    string private _baseTokenURI;
//
//    mapping(address => bool) public hasSoul;
//
//    constructor(string memory baseURI) ERC721("creepz-playtest", "CPT") {
//        _baseTokenURI = baseURI;
//    }
//
//    function mint(address to) external onlyOwner {
//        require(!hasSoul[to], "Already minted for this address");
//
//        uint256 tokenId = _nextTokenId;
//        _safeMint(to, tokenId);
//        _setTokenURI(tokenId, _baseTokenURI);
//        hasSoul[to] = true;
//
//        _nextTokenId++;
//    }
//
//    // Soulbound: запрет на transfer
//    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
//    internal
//    override
//    {
//        require(from == address(0) || to == address(0), "Soulbound: token is non-transferrable");
//        super._beforeTokenTransfer(from, to, tokenId, batchSize);
//    }
//
//    // Soulbound: запрет на approve
//    function approve(address, uint256) public pure override {
//        revert("Soulbound: non-transferable");
//    }
//
//    function setApprovalForAll(address, bool) public pure override {
//        revert("Soulbound: non-transferable");
//    }
//}
