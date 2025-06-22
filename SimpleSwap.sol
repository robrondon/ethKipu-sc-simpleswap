// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SimpleSwap Smart Contract
 * @author Robert Rondón
 * @notice This contract implements a swap system with the possibility to add and remove liquidity replicating Uniswap functionality
 */
contract SimpleSwap {
    // ============================================================================
    // STRUCTS
    // ============================================================================
    /// @notice Struct for storing token reserves in a pool
    struct Reserve {
        uint256 reserveA; // Reserve of first token
        uint256 reserveB; // Reserve of second token
        uint256 totalLiquidity; // Total LP tokens minted for this pool
    }

    // ============================================================================
    // STATE VARIABLES
    // ============================================================================

    // Reserves for each token pair
    mapping(address => mapping(address => Reserve)) public reserves;

    // LP token addresses for each token pair
    mapping(address => mapping(address => address)) public lpTokens;

    // ============================================================================
    // EVENTS
    // ============================================================================
    event AddedLiquidity(address token, uint256 amount);
    event RemovedLiquidity(address token, uint256 amount);
    event SwappedTokens(address tokenA, address tokenB, uint256 amount);

    // ============================================================================
    // MAIN FUNCTIONS
    // ============================================================================
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        // Must transfer tokens to user
        // Calculate and asign liquidity by reserves
        // Mint liquidity tokens to user
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        // Must burn liquidity tokens
        // Calculate and return tokens A & B
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        // Transfer entry tokens from user to contract
        // Calculate exchange from reservations
        // Transfer out tokens from contract to user
    }

    function getPrice(
        address tokenA,
        address tokenB
    ) external view returns (uint256 price) {
        // Obtain both tokens reserves
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        Reserve memory reserve = reserves[token0][token1];

        require(
            reserve.reserveA > 0 && reserve.reserveB > 0,
            "SimpleSwap: No liquidity for this pair"
        );

        // Calculate and return price
        if (tokenA == token0) {
            price = (reserve.reserveB * 1e18) / reserve.reserveA;
        } else {
            price = (reserve.reserveA * 1e18) / reserve.reserveB;
        }
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut) {
        amountOut = _getAmountOut(amountIn, reserveIn, reserveOut);
        return amountOut;
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Amount in must be greater than zero");
        require(
            reserveIn > 0 && reserveOut > 0,
            "SimpleSwap: No liquidity for this pair"
        );

        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }

    function _sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Identical tokens");
        require(
            tokenA != address(0) && tokenB != address(0),
            "Invalid token address"
        );
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }
}
