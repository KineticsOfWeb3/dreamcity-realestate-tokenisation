// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RealEstateToken is ERC20, Ownable {
    struct TokenLock {
        uint256 lockTimestamp;
        uint256 lockExpiry;
    }

    mapping(address => mapping(uint256 => TokenLock)) public tokenLocks; // Maps an address to a token ID and its lock details

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Mint function to create new tokens, only by the owner (admin)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Burn function to destroy tokens (optional, for case of market corrections or refunds)
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    // Set the lock details for tokens (lock period)
    function setLockDetails(
        address account,
        uint256 tokenId,
        uint256 lockPeriod
    ) external onlyOwner {
        TokenLock storage lock = tokenLocks[account][tokenId];
        lock.lockTimestamp = block.timestamp;
        lock.lockExpiry = block.timestamp + lockPeriod;
    }

    // Verify lock status
    function canTransfer(
        address account,
        uint256 tokenId
    ) external view returns (bool) {
        TokenLock storage lock = tokenLocks[account][tokenId];
        return block.timestamp >= lock.lockExpiry;
    }
};
