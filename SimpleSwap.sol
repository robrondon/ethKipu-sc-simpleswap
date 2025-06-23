// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LPToken} from "./LPToken.sol";

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
    event LiquidityAdded(
        address indexed tokenA,
        address indexed tokenB,
        address indexed to,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    event LiquidityRemoved(
        address indexed tokenA,
        address indexed tokenB,
        address indexed to,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    event SwappedTokens(
        address indexed tokenA,
        address indexed tokenB,
        address indexed to,
        uint256[] amounts
    );

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
        // Basic validations
        require(deadline >= block.timestamp, "SimpleSwap: Expired deadline");
        require(to != address(0), "SimpleSwap: Invalid recipient address");
        require(
            amountADesired > 0,
            "SimpleSwap: Desired A amount must be greater than zero"
        );
        require(
            amountBDesired > 0,
            "SimpleSwap: Desired B amount must be greater than zero"
        );
        require(
            amountAMin <= amountADesired,
            "SimpleSwap: Minumum A amount exceeds desired A amount"
        );
        require(
            amountBMin <= amountBDesired,
            "SimpleSwap: Minumum B amount exceeds desired B amount"
        );

        // Calculate optimal amounts
        (
            uint256 optimalAmountA,
            uint256 optimalAmountB
        ) = _calculateOptimalLiquidityAmounts(
                tokenA,
                tokenB,
                amountADesired,
                amountBDesired,
                amountAMin,
                amountBMin
            );

        // Must transfer tokens from user
        IERC20(tokenA).transferFrom(msg.sender, address(this), optimalAmountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), optimalAmountB);

        // Calculate and asign liquidity by reserves
        amountA = optimalAmountA;
        amountB = optimalAmountB;

        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        Reserve memory reserve = reserves[token0][token1];

        uint256 amount0 = tokenA == token0 ? amountA : amountB;
        uint256 amount1 = tokenA == token0 ? amountB : amountA;

        if (reserve.totalLiquidity == 0) {
            // Simple calculation instead of using uniswap sqrt
            liquidity = (amount0 * amount1) / 1e18;
        } else {
            uint256 liquidity0 = (amount0 * reserve.totalLiquidity) /
                reserve.reserveA;
            uint256 liquidity1 = (amount1 * reserve.totalLiquidity) /
                reserve.reserveB;
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        }

        // Mint liquidity tokens to user
        address lpTokenAddress = _getOrCreateLPToken(tokenA, tokenB);
        LPToken lpToken = LPToken(lpTokenAddress);

        lpToken.mint(to, liquidity);

        // Update Reserves
        reserves[token0][token1].reserveA += amount0;
        reserves[token0][token1].reserveB += amount1;
        reserves[token0][token1].totalLiquidity += liquidity;

        emit LiquidityAdded(tokenA, tokenB, to, amountA, amountB, liquidity);
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
        require(deadline >= block.timestamp, "SimpleSwap: Expired deadline");
        require(to != address(0), "SimpleSwap: Invalid recipient address");
        require(
            liquidity > 0,
            "SimpleSwap: Liquidity must be greater than zero"
        );

        (address token0, address token1) = _sortTokens(tokenA, tokenB);

        address lpTokenAddress = lpTokens[token0][token1];
        require(
            lpTokenAddress != address(0),
            "SimpleSwap: Pool does not exist"
        );

        Reserve memory reserve = reserves[token0][token1];
        require(
            reserve.totalLiquidity >= liquidity,
            "SimpleSwap: There is not enough liquidity"
        );

        // Calculate token values to return
        uint256 amount0 = (liquidity * reserve.reserveA) /
            reserve.totalLiquidity;
        uint256 amount1 = (liquidity * reserve.reserveB) /
            reserve.totalLiquidity;

        amountA = tokenA == token0 ? amount0 : amount1;
        amountB = tokenA == token0 ? amount1 : amount0;

        require(amountA >= amountAMin, "SimpleSwap: Insufficient amount A");
        require(amountB >= amountBMin, "SimpleSwap: Insufficient amount B");

        // Must burn liquidity tokens
        LPToken lpToken = LPToken(lpTokenAddress);
        lpToken.burn(msg.sender, liquidity);

        // Transfer tokens
        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);

        // Update Reserves
        reserves[token0][token1].reserveA -= amount0;
        reserves[token0][token1].reserveB -= amount1;
        reserves[token0][token1].totalLiquidity -= liquidity;

        emit LiquidityRemoved(tokenA, tokenB, to, amountA, amountB, liquidity);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(deadline >= block.timestamp, "SimpleSwap: Expired deadline");
        require(to != address(0), "SimpleSwap: Invalid recipient address");
        require(
            amountIn > 0,
            "SimpleSwap: Amount in must be greater than zero"
        );

        (address token0, address token1) = _sortTokens(path[0], path[1]);

        address lpTokenAddress = lpTokens[token0][token1];
        require(
            lpTokenAddress != address(0),
            "SimpleSwap: Pool does not exist"
        );

        Reserve memory reserve = reserves[token0][token1];

        uint256 reserveA = path[0] == token0
            ? reserve.reserveA
            : reserve.reserveB;
        uint256 reserveB = path[0] == token0
            ? reserve.reserveB
            : reserve.reserveA;

        // Calculate exchange from reservations
        uint256 amountOut = _getAmountOut(amountIn, reserveA, reserveB);

        require(
            amountOut >= amountOutMin,
            "SimpleSwap: The available amountOut is not enough"
        );

        // Transfer entry tokens from user to contract
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        // Transfer out tokens from contract to user
        IERC20(path[1]).transfer(to, amountOut);

        if (path[0] == token0) {
            reserves[token0][token1].reserveA += amountIn;
            reserves[token0][token1].reserveB -= amountOut;
        } else {
            reserves[token0][token1].reserveA -= amountOut;
            reserves[token0][token1].reserveB += amountIn;
        }

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        emit SwappedTokens(path[0], path[1], to, amounts);
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
        require(
            amountIn > 0,
            "SimpleSwap: Amount in must be greater than zero"
        );
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
        require(tokenA != tokenB, "SimpleSwap: Identical tokens");
        require(
            tokenA != address(0) && tokenB != address(0),
            "SimpleSwap: Invalid token address"
        );
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }

    function _createLPToken(
        address tokenA,
        address tokenB
    ) internal returns (address) {
        string memory name = "SimpleSwap LP Token";
        string memory symbol = "SLP";

        LPToken lpToken = new LPToken(name, symbol, address(this));
        lpTokens[tokenA][tokenB] = address(lpToken);

        return address(lpToken);
    }

    function _getOrCreateLPToken(
        address tokenA,
        address tokenB
    ) internal returns (address) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);

        if (lpTokens[token0][token1] != address(0)) {
            return lpTokens[token0][token1];
        }

        return _createLPToken(token0, token1);
    }

    function _calculateOptimalLiquidityAmounts(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 optimalAmountA, uint256 optimalAmountB) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        Reserve memory reserve = reserves[token0][token1];

        // New Pool
        if (reserve.reserveA == 0 && reserve.reserveB == 0) {
            return (amountADesired, amountBDesired);
        }

        // Existing pool
        // Need to define which reserve belongs to each token
        uint256 reserveA = tokenA == token0
            ? reserve.reserveA
            : reserve.reserveB;
        uint256 reserveB = tokenA == token0
            ? reserve.reserveB
            : reserve.reserveA;

        // Calculate how much tokenB is needed to match tokenA
        uint256 amountBOptimal = _calculateTokensEquivalent(
            amountADesired,
            reserve.reserveA,
            reserve.reserveB
        );

        // If there is enough tokenB provided use all amountADesired
        if (amountBOptimal <= amountBDesired) {
            require(
                amountBOptimal >= amountBMin,
                "SimpleSwap: It doesn't fit the minimum required"
            );
            return (amountADesired, amountBOptimal);
        } else {
            // If not, must calculate how much tokenA is needed to match tokenB
            uint256 amountAOptimal = _calculateTokensEquivalent(
                amountBDesired,
                reserve.reserveB,
                reserve.reserveA
            );
            require(
                amountAOptimal <= amountADesired,
                "SimpleSwap: Calculated optimal amount A exceeds desired amount"
            );
            require(
                amountAOptimal >= amountAMin,
                "SimpleSwap: It doesn't fit the minimum required"
            );
            return (amountAOptimal, amountBDesired);
        }
    }

    function _calculateTokensEquivalent(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "SimpleSwap: Amount in must be greater than zero");
        require(
            reserveA > 0 && reserveB > 0,
            "SimpleSwap: No liquidity for this pair"
        );

        amountB = (amountA * reserveB) / reserveA;
    }
}
