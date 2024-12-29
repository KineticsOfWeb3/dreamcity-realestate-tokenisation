// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Treasury is Ownable {
    AggregatorV3Interface public priceFeedETHUSD;
    AggregatorV3Interface public priceFeedUSDNGN;

    event ConversionETHToUSD(uint256 ethAmount, uint256 usdAmount);
    event ConversionUSDToNGN(uint256 usdAmount, uint256 ngnAmount);

    constructor(address _priceFeedETHUSD, address _priceFeedUSDNGN) {
        priceFeedETHUSD = AggregatorV3Interface(_priceFeedETHUSD);
        priceFeedUSDNGN = AggregatorV3Interface(_priceFeedUSDNGN);
    }

    // Get the current ETH to USD price from Chainlink price feed
    function getEthToUsd() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedETHUSD.latestRoundData();
        require(price > 0, "Invalid ETH to USD price data");
        return uint256(price) / 1e8; // Normalize to 18 decimals
    }

    // Get the current USD to NGN price from Chainlink price feed
    function getUsdToNgn() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedUSDNGN.latestRoundData();
        require(price > 0, "Invalid USD to NGN price data");
        return uint256(price) / 1e8; // Normalize to 18 decimals
    }

    // Convert ETH to USD
    function convertETHToUSD(uint256 ethAmount) public view returns (uint256) {
        uint256 ethToUsdPrice = getEthToUsd();
        uint256 usdAmount = ethAmount * ethToUsdPrice;
        emit ConversionETHToUSD(ethAmount, usdAmount);
        return usdAmount;
    }

    // Convert USD to NGN
    function convertUSDToNGN(uint256 usdAmount) public view returns (uint256) {
        uint256 usdToNgnPrice = getUsdToNgn();
        uint256 ngnAmount = usdAmount * usdToNgnPrice;
        emit ConversionUSDToNGN(usdAmount, ngnAmount);
        return ngnAmount;
    }

    // Admin function to update the price feed addresses if necessary
    function updatePriceFeeds(
        address _priceFeedETHUSD,
        address _priceFeedUSDNGN
    ) external onlyOwner {
        priceFeedETHUSD = AggregatorV3Interface(_priceFeedETHUSD);
        priceFeedUSDNGN = AggregatorV3Interface(_priceFeedUSDNGN);
    }
}
