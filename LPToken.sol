// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Liquidity Provider Token for SimpleSwap pools
/// @author Robert Rondón
/// @notice This ERC20 token represents liquidity shares in a specific pool

contract LPToken is ERC20, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        address owner
    ) ERC20(name, symbol) Ownable(owner) {}

    /// @notice Mint LP tokens - callable only by owner (SimpleSwap contract)
    /// @param to Recipient address
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /// @notice Burn LP tokens - callable only by owner (SimpleSwap contract)
    /// @param from Address to burn from
    /// @param amount Amount to burn
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
