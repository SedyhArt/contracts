// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract CreepzSoulbound is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId = 1;
    string private _baseTokenURI;

    mapping(address => bool) public hasSoul;

    constructor(string memory baseURI)
    ERC721("creepz-playtest", "CPT")
    Ownable(msg.sender)
    {
        _baseTokenURI = baseURI;
    }

    function mint(address to) external onlyOwner {
        require(!hasSoul[to], "Already minted for this address");

        uint256 tokenId = _nextTokenId;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _baseTokenURI);

        hasSoul[to] = true;
        _nextTokenId++;
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);

        require(from == address(0) || to == address(0), "Soulbound: token is non-transferable");

        return super._update(to, tokenId, auth);
    }

    function approve(address, uint256) public pure override(ERC721, IERC721) {
        revert("Soulbound: non-transferable");
    }

    function setApprovalForAll(address, bool) public pure override(ERC721, IERC721) {
        revert("Soulbound: non-transferable");
    }

    function setBaseTokenURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getBaseTokenURI() external view returns (string memory) {
        return _baseTokenURI;
    }
}