// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./RealEstateToken.sol"; // Import the RealEstateToken contract

contract InvestmentManager is Ownable {
    struct Investment {
        uint256 amount;
        uint256 timestamp;
        uint256 profitAccrued;
        bool active;
    }

    IERC20 public realEstateToken;
    uint256 public lotPriceUSD = 100000; // $100,000 per lot
    uint256 public profitPercentage = 30; // 30% profit after 24 months
    uint256 public penaltyPercentage = 10; // 10% penalty for early withdrawal
    uint256 public investmentPeriod = 730 days; // 24 months
    address public treasury;
    AggregatorV3Interface public priceFeed;

    mapping(address => Investment) public investments;

    event Invested(address indexed investor, uint256 amount);
    event Withdrawn(address indexed investor, uint256 amount, bool early);

    constructor(
        IERC20 _realEstateToken,
        address _priceFeed,
        address _treasury
    ) {
        realEstateToken = _realEstateToken;
        priceFeed = AggregatorV3Interface(_priceFeed);
        treasury = _treasury;
    }

    // Get the ETH to USD price from Chainlink
    function getEthUsdPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) / 1e8; // Convert price to a more readable format
    }

    // Allow investors to invest in the tokenized property (RealEstateToken)
    function invest(uint256 tokenAmount) external {
        require(tokenAmount > 0, "Investment must be greater than zero");
        require(
            realEstateToken.balanceOf(msg.sender) >= tokenAmount,
            "Insufficient token balance"
        );

        realEstateToken.transferFrom(msg.sender, address(this), tokenAmount);

        investments[msg.sender] = Investment({
            amount: tokenAmount,
            timestamp: block.timestamp,
            profitAccrued: 0,
            active: true
        });

        emit Invested(msg.sender, tokenAmount);
    }

    // Allow investors to withdraw their investment with profit after 24 months or with penalties
    function withdraw() external {
        Investment storage investment = investments[msg.sender];
        require(investment.active, "No active investment");

        uint256 elapsedTime = block.timestamp - investment.timestamp;
        uint256 payout;

        if (elapsedTime >= investmentPeriod) {
            // Full payout after 24 months with profit
            payout =
                investment.amount +
                (investment.amount * profitPercentage) /
                100;
        } else {
            // Early withdrawal with penalty
            uint256 penalty = (investment.amount * penaltyPercentage) / 100;
            payout = investment.amount - penalty;
        }

        investment.active = false;
        realEstateToken.transfer(msg.sender, payout);

        emit Withdrawn(msg.sender, payout, elapsedTime < investmentPeriod);
    }

    // Helper function to calculate profit dynamically
    function calculateProfit(
        uint256 amount,
        uint256 elapsedTime
    ) public view returns (uint256) {
        uint256 profit;
        if (elapsedTime >= investmentPeriod) {
            profit = (amount * profitPercentage) / 100;
        }
        return profit;
    }

    // Update lot price based on current ETH to USD conversion rate
    function updateLotPrice(uint256 _lotPriceUSD) external onlyOwner {
        lotPriceUSD = _lotPriceUSD;
    }

    // Admin function to withdraw any funds from the contract
    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Admin function to withdraw tokens from the contract
    function withdrawTokens(uint256 amount) external onlyOwner {
        realEstateToken.transfer(owner(), amount);
    }
}
