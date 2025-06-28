// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title ERC20 Token for SimpleSwap DEX (using OpenZeppelin)
/// @author Robert Rondón
/// @notice This contract implements a simple ERC20 token using OpenZeppelin libraries.

contract ERC20Token is ERC20 {
    /// @notice Constructor that mints the initial supply to the deployer
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param initialSupply The total supply of the token (in wei)
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mint new tokens to a specific address
    /// @param to The address that will receive the minted tokens
    /// @param amount The amount of tokens to mint (in wei)
    /// @dev Anyone can call this function
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
