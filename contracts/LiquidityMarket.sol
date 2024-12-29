// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// No need for SafeMath with Solidity 0.8.x and above
// using SafeMath for uint256; be4 use dis uint256 result = a + b;  // No need for SafeMath anymore
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./RealEstateToken.sol";

interface IRealEstateToken {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function canTransfer(
        address account,
        uint256 tokenId
    ) external view returns (bool);
}

contract LiquidityMarket is Ownable {
    using SafeMath for uint256;

    // RealEstateToken contract address
    IRealEstateToken public realEstateToken;

    // Price discount for early withdrawal (in basis points, e.g., 1000 = 10% penalty for early withdrawal)
    uint256 public discountPenalty = 1000;

    struct Listing {
        address seller;
        uint256 amount;
        uint256 price;
        uint256 timestamp;
        uint256 tokenId; // Each listing corresponds to a specific tokenId
    }

    mapping(uint256 => Listing) public listings;
    uint256 public listingCount;

    event TokenListed(
        uint256 indexed listingId,
        address indexed seller,
        uint256 amount,
        uint256 price
    );
    event TokenSold(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 amount,
        uint256 price
    );
    event TokenDelisted(uint256 indexed listingId, address indexed seller);

    constructor(address _realEstateToken) {
        realEstateToken = IRealEstateToken(_realEstateToken);
    }

    // List tokens for sale
    function listTokens(
        uint256 amount,
        uint256 price,
        uint256 tokenId
    ) external {
        require(
            realEstateToken.balanceOf(msg.sender) >= amount,
            "Insufficient token balance"
        );
        require(amount > 0, "Amount must be greater than 0");
        require(price > 0, "Price must be greater than 0");
        require(
            realEstateToken.canTransfer(msg.sender, tokenId),
            "Token is locked for transfer"
        );

        realEstateToken.transferFrom(msg.sender, address(this), amount);

        listingCount++;
        listings[listingCount] = Listing({
            seller: msg.sender,
            amount: amount,
            price: price,
            timestamp: block.timestamp,
            tokenId: tokenId
        });

        emit TokenListed(listingCount, msg.sender, amount, price);
    }

    // Buy tokens listed on the market
    function buyTokens(uint256 listingId) external payable {
        Listing storage listing = listings[listingId];
        require(listing.seller != address(0), "Listing does not exist");
        require(msg.value == listing.price, "Incorrect price");

        uint256 penalty = 0;
        if (block.timestamp < listing.timestamp + 730 days) {
            // Apply penalty for early withdrawal (if lock-in period is less than 24 months)
            penalty = listing.price.mul(discountPenalty).div(10000);
        }

        uint256 finalPrice = listing.price.sub(penalty);

        // Ensure the buyer is paying the correct price after penalty
        require(msg.value >= finalPrice, "Insufficient payment");

        // Transfer the tokens to the buyer
        realEstateToken.transferFrom(address(this), msg.sender, listing.amount);

        // Transfer the funds to the seller
        payable(listing.seller).transfer(finalPrice);

        emit TokenSold(listingId, msg.sender, listing.amount, finalPrice);

        // Delete the listing after sale
        delete listings[listingId];
    }

    // Delist a token from the market
    function delistTokens(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.seller == msg.sender, "Only the seller can delist");
        require(listing.seller != address(0), "Listing does not exist");

        // Refund the tokens back to the seller
        realEstateToken.transfer(msg.sender, listing.amount);

        emit TokenDelisted(listingId, msg.sender);

        // Remove the listing
        delete listings[listingId];
    }

    // Update the discount penalty for early withdrawal
    function setDiscountPenalty(uint256 _discountPenalty) external onlyOwner {
        require(_discountPenalty <= 10000, "Penalty cannot exceed 100%");
        discountPenalty = _discountPenalty;
    }

    // Withdraw funds and tokens (emergency case)
    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        realEstateToken.transfer(owner(), amount);
    }
}
