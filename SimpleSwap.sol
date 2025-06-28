// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LPToken} from "./LPToken.sol";

/**
 * @title SimpleSwap Smart Contract
 * @author Robert Rondón
 * @notice This contract implements a swap system with the possibility to add and remove liquidity replicating Uniswap functionality
 * @dev Implements automated market maker (AMM) functionality with constant product formula (x * y = k)
 */
contract SimpleSwap {
    // ============================================================================
    // STRUCTS
    // ============================================================================

    /**
     * @notice Struct for storing token reserves in a pool
     * @param reserveA Reserve amount of the first token (token0)
     * @param reserveB Reserve amount of the second token (token1)
     * @param totalLiquidity Total LP tokens minted for this pool
     */
    struct Reserve {
        uint256 reserveA; // Reserve of first token
        uint256 reserveB; // Reserve of second token
        uint256 totalLiquidity; // Total LP tokens minted for this pool
    }

    /**
     * @notice Parameters for adding liquidity to a pool
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @param amountADesired Desired amount of tokenA to add
     * @param amountBDesired Desired amount of tokenB to add
     * @param amountAMin Minimum amount of tokenA to add (slippage protection)
     * @param amountBMin Minimum amount of tokenB to add (slippage protection)
     * @param to Address that will receive the LP tokens
     * @param deadline Unix timestamp after which the transaction will revert
     */
    struct AddLiquidityParams {
        address tokenA;
        address tokenB;
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 amountAMin;
        uint256 amountBMin;
        address to;
        uint256 deadline;
    }

    /**
     * @notice Parameters for removing liquidity from a pool
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @param liquidity Amount of LP tokens to burn
     * @param amountAMin Minimum amount of tokenA to receive (slippage protection)
     * @param amountBMin Minimum amount of tokenB to receive (slippage protection)
     * @param to Address that will receive the tokens
     * @param deadline Unix timestamp after which the transaction will revert
     */
    struct RemoveLiquidityParams {
        address tokenA;
        address tokenB;
        uint256 liquidity;
        uint256 amountAMin;
        uint256 amountBMin;
        address to;
        uint256 deadline;
    }

    /**
     * @notice Result data from liquidity operations
     * @param amountA Actual amount of tokenA used/received
     * @param amountB Actual amount of tokenB used/received
     * @param liquidity Amount of LP tokens minted/burned
     * @param token0 Address of token0 (lexicographically smaller)
     * @param token1 Address of token1 (lexicographically larger)
     */
    struct LiquidityResult {
        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;
        address token0;
        address token1;
    }

    /**
     * @notice Parameters for token swapping
     * @param amountIn Amount of input tokens to swap
     * @param amountOutMin Minimum amount of output tokens to receive (slippage protection)
     * @param path Array of token addresses representing the swap path
     * @param to Address that will receive the output tokens
     * @param deadline Unix timestamp after which the transaction will revert
     */
    struct SwapParams {
        uint256 amountIn;
        uint256 amountOutMin;
        address[] path;
        address to;
        uint256 deadline;
    }

    // ============================================================================
    // STATE VARIABLES
    // ============================================================================

    /// @notice Reserves for each token pair, indexed by token0 -> token1
    /// @dev Maps token0 address to token1 address to Reserve struct
    mapping(address => mapping(address => Reserve)) public reserves;

    /// @notice LP token addresses for each token pair
    /// @dev Maps token0 address to token1 address to LP token contract address
    mapping(address => mapping(address => address)) public lpTokens;

    // ============================================================================
    // EVENTS
    // ============================================================================

    /**
     * @notice Emitted when liquidity is added to a pool
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @param to Address that received the LP tokens
     * @param amountA Amount of tokenA added to the pool
     * @param amountB Amount of tokenB added to the pool
     * @param liquidity Amount of LP tokens minted
     */
    event LiquidityAdded(
        address indexed tokenA,
        address indexed tokenB,
        address indexed to,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    /**
     * @notice Emitted when liquidity is removed from a pool
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @param to Address that received the tokens
     * @param amountA Amount of tokenA removed from the pool
     * @param amountB Amount of tokenB removed from the pool
     * @param liquidity Amount of LP tokens burned
     */
    event LiquidityRemoved(
        address indexed tokenA,
        address indexed tokenB,
        address indexed to,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    /**
     * @notice Emitted when tokens are swapped
     * @param tokenA Address of the input token
     * @param tokenB Address of the output token
     * @param to Address that received the output tokens
     * @param amounts Array containing [amountIn, amountOut]
     */
    event SwappedTokens(
        address indexed tokenA,
        address indexed tokenB,
        address indexed to,
        uint256[] amounts
    );

    // ============================================================================
    // MAIN FUNCTIONS
    // ============================================================================

    /**
     * @notice Adds liquidity to a token pair pool
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @param amountADesired Desired amount of tokenA to add
     * @param amountBDesired Desired amount of tokenB to add
     * @param amountAMin Minimum amount of tokenA to add (slippage protection)
     * @param amountBMin Minimum amount of tokenB to add (slippage protection)
     * @param to Address that will receive the LP tokens
     * @param deadline Unix timestamp after which the transaction will revert
     * @return amountA Actual amount of tokenA added
     * @return amountB Actual amount of tokenB added
     * @return liquidity Amount of LP tokens minted
     * @dev Creates a new pool if it doesn't exist, otherwise adds to existing pool maintaining the current ratio
     */
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
        AddLiquidityParams memory params = AddLiquidityParams({
            tokenA: tokenA,
            tokenB: tokenB,
            amountADesired: amountADesired,
            amountBDesired: amountBDesired,
            amountAMin: amountAMin,
            amountBMin: amountBMin,
            to: to,
            deadline: deadline
        });

        return _addLiquidity(params);
    }

    /**
     * @notice Internal function to handle liquidity addition logic
     * @param params AddLiquidityParams struct containing all necessary parameters
     * @return amountA Actual amount of tokenA added
     * @return amountB Actual amount of tokenB added
     * @return liquidity Amount of LP tokens minted
     * @dev Validates parameters, calculates optimal amounts, transfers tokens, mints LP tokens, and updates reserves
     */
    function _addLiquidity(
        AddLiquidityParams memory params
    ) internal returns (uint256, uint256, uint256) {
        // Basic validations
        _validateAddLiquidityParams(params);
        // Calculate optimal amounts
        LiquidityResult memory result = _calculateAndPrepareLiquidity(params);

        // Must transfer tokens from user
        _transferTokensForLiquidity(params, result);

        // Mint liquidity tokens to user
        _mintLiquidityTokens(params.to, result);

        // Update Reserves
        _updateReservesAfterAdd(result);

        emit LiquidityAdded(
            params.tokenA,
            params.tokenB,
            params.to,
            result.amountA,
            result.amountB,
            result.liquidity
        );

        return (result.amountA, result.amountB, result.liquidity);
    }

    /**
     * @notice Removes liquidity from a token pair pool
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @param liquidity Amount of LP tokens to burn
     * @param amountAMin Minimum amount of tokenA to receive (slippage protection)
     * @param amountBMin Minimum amount of tokenB to receive (slippage protection)
     * @param to Address that will receive the tokens
     * @param deadline Unix timestamp after which the transaction will revert
     * @return amountA Amount of tokenA received
     * @return amountB Amount of tokenB received
     * @dev Burns LP tokens proportionally and returns underlying tokens to the user
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        RemoveLiquidityParams memory params = RemoveLiquidityParams({
            tokenA: tokenA,
            tokenB: tokenB,
            liquidity: liquidity,
            amountAMin: amountAMin,
            amountBMin: amountBMin,
            to: to,
            deadline: deadline
        });

        return _removeLiquidity(params);
    }

    /**
     * @notice Internal function to handle liquidity removal logic
     * @param params RemoveLiquidityParams struct containing all necessary parameters
     * @return amountA Amount of tokenA received
     * @return amountB Amount of tokenB received
     * @dev Validates parameters, calculates removal amounts, burns LP tokens, transfers tokens, and updates reserves
     */
    function _removeLiquidity(
        RemoveLiquidityParams memory params
    ) internal returns (uint256, uint256) {
        // Validate params
        _validateRemoveLiquidityParams(params);

        // Get pool info
        (
            address token0,
            address token1,
            address lpTokenAddress,
            Reserve memory reserve
        ) = _getPoolInfo(params.tokenA, params.tokenB);

        require(
            reserve.totalLiquidity >= params.liquidity,
            "SimpleSwap: There is not enough liquidity"
        );

        // Calculate removal amounts
        (uint256 amountA, uint256 amountB) = _calculateRemovalAmounts(
            params,
            reserve,
            token0
        );

        // Burn liquidity tokens and then transfer
        _burnAndTransferTokens(params, amountA, amountB, lpTokenAddress);

        // Update Reserves
        _updateReservesAfterRemoval(token0, token1, amountA, amountB, params);

        emit LiquidityRemoved(
            params.tokenA,
            params.tokenB,
            params.to,
            amountA,
            amountB,
            params.liquidity
        );

        return (amountA, amountB);
    }

    /**
     * @notice Swaps an exact amount of input tokens for output tokens
     * @param amountIn Amount of input tokens to swap
     * @param amountOutMin Minimum amount of output tokens to receive (slippage protection)
     * @param path Array of token addresses representing the swap path (currently supports only 2 tokens)
     * @param to Address that will receive the output tokens
     * @param deadline Unix timestamp after which the transaction will revert
     * @return amounts Array containing [amountIn, amountOut]
     * @dev Uses constant product formula to calculate output amount and execute the swap
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        SwapParams memory params = SwapParams({
            amountIn: amountIn,
            amountOutMin: amountOutMin,
            path: path,
            to: to,
            deadline: deadline
        });

        return _swapExactTokensForTokens(params);
    }

    /**
     * @notice Internal function to handle token swapping logic
     * @param params SwapParams struct containing all necessary parameters
     * @return amounts Array containing [amountIn, amountOut]
     * @dev Validates parameters, calculates output amount, executes transfers, and updates reserves
     */
    function _swapExactTokensForTokens(
        SwapParams memory params
    ) internal returns (uint256[] memory amounts) {
        // Validate Params
        _validateSwapParams(params);

        // Obtain pool info
        (
            address token0,
            address token1,
            ,
            Reserve memory reserve
        ) = _getPoolInfo(params.path[0], params.path[1]);

        // Get swap reserves
        (uint256 reserveIn, uint256 reserveOut) = _getSwapReserves(
            params.path[0],
            token0,
            reserve
        );

        // Calculate exchange from reservations
        uint256 amountOut = _getAmountOut(
            params.amountIn,
            reserveIn,
            reserveOut
        );
        require(
            amountOut >= params.amountOutMin,
            "SimpleSwap: The available amountOut is not enough"
        );

        // Execute swap trasfers
        _swapTransfers(params, amountOut);

        // Update reserves
        _updateReservesAfterSwap(params, amountOut, token0, token1);

        // Prepare amounts array
        amounts = new uint256[](2);
        amounts[0] = params.amountIn;
        amounts[1] = amountOut;

        emit SwappedTokens(params.path[0], params.path[1], params.to, amounts);
    }

    /**
     * @notice Gets the current price of tokenA in terms of tokenB
     * @param tokenA Address of the token to get price for
     * @param tokenB Address of the token to price against
     * @return price Price of tokenA in tokenB (scaled by 1e18)
     * @dev Returns how many tokenB units equal 1 tokenA unit, multiplied by 1e18 for precision
     */
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

        // Calculate price as: how much tokenB per tokenA
        // We need to return (amountB * 1e18) / amountA regardless of internal sorting

        uint256 reserveA; // Reserve of tokenA
        uint256 reserveB; // Reserve of tokenB

        if (tokenA == token0) {
            // tokenA is token0, tokenB is token1
            reserveA = reserve.reserveA;
            reserveB = reserve.reserveB;
        } else {
            // tokenA is token1, tokenB is token0
            reserveA = reserve.reserveB;
            reserveB = reserve.reserveA;
        }

        // Price = (tokenB reserve * 1e18) / tokenA reserve
        price = (reserveB * 1e18) / reserveA;
    }

    /**
     * @notice Calculates the amount of output tokens for a given input amount
     * @param amountIn Amount of input tokens
     * @param reserveIn Reserve of input token in the pool
     * @param reserveOut Reserve of output token in the pool
     * @return amountOut Amount of output tokens that would be received
     * @dev Uses constant product formula: amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut) {
        amountOut = _getAmountOut(amountIn, reserveIn, reserveOut);
        return amountOut;
    }

    // ============================================================================
    // INTERNAL FUNCTIONS
    // ============================================================================

    /**
     * @notice Internal function to calculate output amount for swaps
     * @param amountIn Amount of input tokens
     * @param reserveIn Reserve of input token in the pool
     * @param reserveOut Reserve of output token in the pool
     * @return amountOut Amount of output tokens
     * @dev Implements constant product formula without fees
     */
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

    /**
     * @notice Sorts two token addresses lexicographically
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return token0 Lexicographically smaller token address
     * @return token1 Lexicographically larger token address
     * @dev Ensures consistent ordering for pool identification
     */
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

    /**
     * @notice Creates a new LP token contract for a token pair
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return Address of the newly created LP token contract
     * @dev Deploys a new LPToken contract and stores its address
     */
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

    /**
     * @notice Gets or creates an LP token contract for a token pair
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return Address of the LP token contract
     * @dev Returns existing LP token address or creates a new one if none exists
     */
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

    /**
     * @notice Calculates optimal token amounts for liquidity provision
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param amountADesired Desired amount of tokenA
     * @param amountBDesired Desired amount of tokenB
     * @param amountAMin Minimum amount of tokenA
     * @param amountBMin Minimum amount of tokenB
     * @return optimalAmountA Optimal amount of tokenA to use
     * @return optimalAmountB Optimal amount of tokenB to use
     * @dev For new pools, uses desired amounts. For existing pools, calculates amounts maintaining current ratio
     */
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
            reserveA,
            reserveB
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
                reserveB,
                reserveA
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

    /**
     * @notice Calculates equivalent token amount based on current pool ratio
     * @param amountA Amount of tokenA
     * @param reserveA Reserve of tokenA in pool
     * @param reserveB Reserve of tokenB in pool
     * @return amountB Equivalent amount of tokenB
     * @dev Uses ratio: amountB = (amountA * reserveB) / reserveA
     */
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

    /**
     * @notice Updates pool reserves after liquidity addition
     * @param result LiquidityResult containing amounts and token addresses
     * @dev Increases reserves and total liquidity for the pool
     */
    function _updateReservesAfterAdd(LiquidityResult memory result) internal {
        uint256 amount0 = result.amountA;
        uint256 amount1 = result.amountB;

        if (result.token0 != address(0)) {
            reserves[result.token0][result.token1].reserveA += amount0;
            reserves[result.token0][result.token1].reserveB += amount1;
            reserves[result.token0][result.token1].totalLiquidity += result
                .liquidity;
        }
    }

    /**
     * @notice Transfers tokens from user for liquidity provision
     * @param params AddLiquidityParams containing token addresses
     * @param result LiquidityResult containing actual amounts to transfer
     * @dev Uses transferFrom to move tokens from msg.sender to contract
     */
    function _transferTokensForLiquidity(
        AddLiquidityParams memory params,
        LiquidityResult memory result
    ) internal {
        IERC20(params.tokenA).transferFrom(
            msg.sender,
            address(this),
            result.amountA
        );
        IERC20(params.tokenB).transferFrom(
            msg.sender,
            address(this),
            result.amountB
        );
    }

    /**
     * @notice Mints LP tokens to the specified address
     * @param to Address to receive LP tokens
     * @param result LiquidityResult containing liquidity amount and token addresses
     * @dev Creates LP token contract if necessary and mints tokens
     */
    function _mintLiquidityTokens(
        address to,
        LiquidityResult memory result
    ) internal {
        address lpTokenAddress = _getOrCreateLPToken(
            result.token0,
            result.token1
        );
        LPToken(lpTokenAddress).mint(to, result.liquidity);
    }

    /**
     * @notice Validates parameters for adding liquidity
     * @param params AddLiquidityParams to validate
     * @dev Checks deadline, recipient address, amounts, and minimum constraints
     */
    function _validateAddLiquidityParams(
        AddLiquidityParams memory params
    ) internal view {
        require(
            params.deadline >= block.timestamp,
            "SimpleSwap: Expired deadline"
        );
        require(
            params.to != address(0),
            "SimpleSwap: Invalid recipient address"
        );
        require(
            params.amountADesired > 0,
            "SimpleSwap: Desired A amount must be greater than zero"
        );
        require(
            params.amountBDesired > 0,
            "SimpleSwap: Desired B amount must be greater than zero"
        );
        require(
            params.amountAMin <= params.amountADesired,
            "SimpleSwap: Minumum A amount exceeds desired A amount"
        );
        require(
            params.amountBMin <= params.amountBDesired,
            "SimpleSwap: Minumum B amount exceeds desired B amount"
        );
    }

    /**
     * @notice Calculates and prepares liquidity amounts for addition
     * @param params AddLiquidityParams containing desired amounts and tokens
     * @return result LiquidityResult with optimal amounts and liquidity to mint
     * @dev Determines optimal amounts and calculates LP tokens to mint based on pool state
     */
    function _calculateAndPrepareLiquidity(
        AddLiquidityParams memory params
    ) internal view returns (LiquidityResult memory result) {
        (result.token0, result.token1) = _sortTokens(
            params.tokenA,
            params.tokenB
        );

        (result.amountA, result.amountB) = _calculateOptimalLiquidityAmounts(
            params.tokenA,
            params.tokenB,
            params.amountADesired,
            params.amountBDesired,
            params.amountAMin,
            params.amountBMin
        );

        Reserve memory reserve = reserves[result.token0][result.token1];

        uint256 amount0 = params.tokenA == result.token0
            ? result.amountA
            : result.amountB;
        uint256 amount1 = params.tokenA == result.token0
            ? result.amountB
            : result.amountA;

        if (reserve.totalLiquidity == 0) {
            // Simple calculation instead of using uniswap sqrt
            result.liquidity = amount0 < amount1 ? amount0 : amount1;

            // Ensure minimum liquidity is provided
            require(
                result.liquidity > 0,
                "SimpleSwap: Liquidity cannot be zero"
            );
        } else {
            uint256 liquidity0 = (amount0 * reserve.totalLiquidity) /
                reserve.reserveA;
            uint256 liquidity1 = (amount1 * reserve.totalLiquidity) /
                reserve.reserveB;
            result.liquidity = liquidity0 < liquidity1
                ? liquidity0
                : liquidity1;
        }
    }

    /**
     * @notice Executes token transfers for swapping
     * @param params SwapParams containing swap details
     * @param amountOut Amount of output tokens to transfer
     * @dev Transfers input tokens from user and output tokens to recipient
     */
    function _swapTransfers(
        SwapParams memory params,
        uint256 amountOut
    ) internal {
        IERC20(params.path[0]).transferFrom(
            msg.sender,
            address(this),
            params.amountIn
        );
        IERC20(params.path[1]).transfer(params.to, amountOut);
    }

    /**
     * @notice Updates pool reserves after a swap
     * @param params SwapParams containing swap details
     * @param amountOut Amount of output tokens swapped
     * @param token0 Address of token0 in the pool
     * @param token1 Address of token1 in the pool
     * @dev Increases input token reserve and decreases output token reserve
     */
    function _updateReservesAfterSwap(
        SwapParams memory params,
        uint256 amountOut,
        address token0,
        address token1
    ) internal {
        if (params.path[0] == token0) {
            reserves[token0][token1].reserveA += params.amountIn;
            reserves[token0][token1].reserveB -= amountOut;
        } else {
            reserves[token0][token1].reserveA -= amountOut;
            reserves[token0][token1].reserveB += params.amountIn;
        }
    }

    /**
     * @notice Gets input and output reserves for a swap
     * @param tokenIn Address of input token
     * @param token0 Address of token0 in the pool
     * @param reserve Reserve struct for the pool
     * @return reserveIn Reserve of input token
     * @return reserveOut Reserve of output token
     * @dev Maps token addresses to their corresponding reserves
     */
    function _getSwapReserves(
        address tokenIn,
        address token0,
        Reserve memory reserve
    ) internal pure returns (uint256 reserveIn, uint256 reserveOut) {
        reserveIn = tokenIn == token0 ? reserve.reserveA : reserve.reserveB;
        reserveOut = tokenIn == token0 ? reserve.reserveB : reserve.reserveA;
    }

    /**
     * @notice Gets pool information for a token pair
     * @param tokenA Address of first token
     * @param tokenB Address of second token
     * @return token0 Lexicographically smaller token address
     * @return token1 Lexicographically larger token address
     * @return lpTokenAddress Address of the LP token contract for this pair
     * @return reserve Reserve struct containing pool data
     * @dev Ensures pool exists before returning information
     */
    function _getPoolInfo(
        address tokenA,
        address tokenB
    )
        internal
        view
        returns (
            address token0,
            address token1,
            address lpTokenAddress,
            Reserve memory reserve
        )
    {
        (token0, token1) = _sortTokens(tokenA, tokenB);
        lpTokenAddress = lpTokens[token0][token1];
        require(
            lpTokenAddress != address(0),
            "SimpleSwap: Pool does not exist"
        );
        reserve = reserves[token0][token1];
    }

    /**
     * @notice Validates parameters for token swapping
     * @param params SwapParams to validate
     * @dev Checks deadline, recipient address, and input amount
     */
    function _validateSwapParams(SwapParams memory params) internal view {
        require(
            params.deadline >= block.timestamp,
            "SimpleSwap: Expired deadline"
        );
        require(
            params.to != address(0),
            "SimpleSwap: Invalid recipient address"
        );
        require(
            params.amountIn > 0,
            "SimpleSwap: Amount in must be greater than zero"
        );
    }

    /**
     * @notice Updates pool reserves after liquidity removal
     * @param token0 Address of token0 in the pool
     * @param token1 Address of token1 in the pool
     * @param amountA Amount of tokenA being removed
     * @param amountB Amount of tokenB being removed
     * @param params RemoveLiquidityParams containing liquidity amount
     * @dev Decreases reserves and total liquidity for the pool
     */
    function _updateReservesAfterRemoval(
        address token0,
        address token1,
        uint256 amountA,
        uint256 amountB,
        RemoveLiquidityParams memory params
    ) internal {
        uint256 amount0 = params.tokenA == token0 ? amountA : amountB;
        uint256 amount1 = params.tokenA == token0 ? amountB : amountA;

        reserves[token0][token1].reserveA -= amount0;
        reserves[token0][token1].reserveB -= amount1;
        reserves[token0][token1].totalLiquidity -= params.liquidity;
    }

    /**
     * @notice Burns LP tokens and transfers underlying tokens to user
     * @param params RemoveLiquidityParams containing removal details
     * @param amountA Amount of tokenA to transfer
     * @param amountB Amount of tokenB to transfer
     * @param lpTokenAddress Address of the LP token contract
     * @dev Burns LP tokens from msg.sender and transfers underlying tokens to recipient
     */
    function _burnAndTransferTokens(
        RemoveLiquidityParams memory params,
        uint256 amountA,
        uint256 amountB,
        address lpTokenAddress
    ) internal {
        // Burn Tokens
        LPToken(lpTokenAddress).burn(msg.sender, params.liquidity);

        // Transfer tokens
        IERC20(params.tokenA).transfer(params.to, amountA);
        IERC20(params.tokenB).transfer(params.to, amountB);
    }

    /**
     * @notice Calculates token amounts to be received when removing liquidity
     * @param params RemoveLiquidityParams containing liquidity amount and minimums
     * @param reserve Reserve struct containing pool data
     * @param token0 Address of token0 in the pool
     * @return amountA Amount of tokenA to be received
     * @return amountB Amount of tokenB to be received
     * @dev Calculates proportional amounts based on liquidity share and validates minimums
     */
    function _calculateRemovalAmounts(
        RemoveLiquidityParams memory params,
        Reserve memory reserve,
        address token0
    ) internal pure returns (uint256 amountA, uint256 amountB) {
        uint256 amount0 = (params.liquidity * reserve.reserveA) /
            reserve.totalLiquidity;
        uint256 amount1 = (params.liquidity * reserve.reserveB) /
            reserve.totalLiquidity;

        amountA = params.tokenA == token0 ? amount0 : amount1;
        amountB = params.tokenA == token0 ? amount1 : amount0;

        require(
            amountA >= params.amountAMin,
            "SimpleSwap: Insufficient amount A"
        );
        require(
            amountB >= params.amountBMin,
            "SimpleSwap: Insufficient amount B"
        );
    }

    /**
     * @notice Validates parameters for removing liquidity
     * @param params RemoveLiquidityParams to validate
     * @dev Checks deadline, recipient address, and liquidity amount
     */
    function _validateRemoveLiquidityParams(
        RemoveLiquidityParams memory params
    ) internal view {
        require(
            params.deadline >= block.timestamp,
            "SimpleSwap: Expired deadline"
        );
        require(
            params.to != address(0),
            "SimpleSwap: Invalid recipient address"
        );
        require(
            params.liquidity > 0,
            "SimpleSwap: Liquidity must be greater than zero"
        );
    }
}
