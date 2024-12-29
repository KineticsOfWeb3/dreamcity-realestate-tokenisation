// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RealEstateToken.sol";

contract PropertyNFT is ERC721, Ownable {
    uint256 public tokenIdCounter = 0;
    mapping(uint256 => string) private _propertyMetadata; // Stores metadata for each property
    mapping(uint256 => uint256) private _propertyLockExpiry; // Stores lock expiry for each NFT

    RealEstateToken public realEstateToken;

    constructor(
        string memory name,
        string memory symbol,
        address _realEstateToken
    ) ERC721(name, symbol) {
        realEstateToken = RealEstateToken(_realEstateToken);
    }

    // Mint new Property NFT with lock-in details
    function mint(
        address to,
        string memory metadata,
        uint256 lockPeriod
    ) external onlyOwner {
        uint256 tokenId = tokenIdCounter;
        _mint(to, tokenId);
        _propertyMetadata[tokenId] = metadata;
        _propertyLockExpiry[tokenId] = block.timestamp + lockPeriod; // Set lock expiry for this NFT
        tokenIdCounter++;
    }

    // Check if the NFT can be transferred
    function canTransfer(uint256 tokenId) external view returns (bool) {
        return block.timestamp >= _propertyLockExpiry[tokenId];
    }

    // Get property metadata (location, value, ownership history, etc.)
    function getPropertyMetadata(
        uint256 tokenId
    ) external view returns (string memory) {
        return _propertyMetadata[tokenId];
    }

    // Transfer property NFT only after lock-in period
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(canTransfer(tokenId), "Token is locked for transfer");
        super.transferFrom(from, to, tokenId);
    }
}
