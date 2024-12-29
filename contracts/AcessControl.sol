// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AccessControlManager is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event AdminAdded(address indexed account);
    event InvestorAdded(address indexed account);
    event ManagerAdded(address indexed account);
    event RoleRevoked(address indexed account);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // Grant the deployer admin role
    }

    // Add Admin
    function addAdmin(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "Account cannot be zero address");
        grantRole(ADMIN_ROLE, account);
        emit AdminAdded(account);
    }

    // Add Investor
    function addInvestor(address account) external onlyRole(ADMIN_ROLE) {
        require(account != address(0), "Account cannot be zero address");
        grantRole(INVESTOR_ROLE, account);
        emit InvestorAdded(account);
    }

    // Add Manager
    function addManager(address account) external onlyRole(ADMIN_ROLE) {
        require(account != address(0), "Account cannot be zero address");
        grantRole(MANAGER_ROLE, account);
        emit ManagerAdded(account);
    }

    // Revoke Investor Role
    function revokeInvestorRole(address account) external onlyRole(ADMIN_ROLE) {
        revokeRole(INVESTOR_ROLE, account);
        emit RoleRevoked(account);
    }

    // Revoke Manager Role
    function revokeManagerRole(address account) external onlyRole(ADMIN_ROLE) {
        revokeRole(MANAGER_ROLE, account);
        emit RoleRevoked(account);
    }

    // Revoke all roles from an account (if necessary)
    function revokeRoleFor(address account) external onlyRole(ADMIN_ROLE) {
        revokeRole(INVESTOR_ROLE, account);
        revokeRole(MANAGER_ROLE, account);
        emit RoleRevoked(account);
    }
}
