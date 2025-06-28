# SimpleSwap Smart Contract

![Solidity](https://img.shields.io/badge/Solidity-^0.8.24-363636?style=flat-square&logo=solidity)
![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-Contracts-4E5EE4?style=flat-square&logo=openzeppelin)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

A decentralized exchange (DEX) smart contract implementation that replicates Uniswap's core functionality. Built as part of the Eth Kipu blockchain development course assignment.

## 🚀 Overview

SimpleSwap is an Automated Market Maker (AMM) that implements the constant product formula (`x * y = k`) for token swapping. The system allows users to:

- **Add/Remove Liquidity**: Provide liquidity to earn trading fees and LP tokens
- **Swap Tokens**: Exchange tokens at market-determined prices
- **Price Discovery**: Get real-time token prices and swap amounts

## 📋 Features

### Core Functionality

- ✅ **Liquidity Management**: Add and remove liquidity with slippage protection
- ✅ **Token Swapping**: Execute token swaps using the constant product formula
- ✅ **Price Queries**: Get current token prices and expected swap amounts
- ✅ **LP Tokens**: Mint/burn liquidity provider tokens for pool shares
- ✅ **Deadline Protection**: Time-based transaction validation
- ✅ **Minimum Amount Protection**: Slippage protection for all operations

### Technical Features

- 🔒 **Secure**: Built with OpenZeppelin contracts
- 💰 **Gas Optimized**: Efficient storage patterns and calculations
- 🎯 **Precise**: 18-decimal precision for price calculations
- ♻️ **Reusable**: Modular design with internal helper functions

## 🏗️ Architecture

### Smart Contracts

| Contract         | Purpose          | Description                                                |
| ---------------- | ---------------- | ---------------------------------------------------------- |
| `SimpleSwap.sol` | Main DEX Logic   | Core AMM functionality, liquidity management, and swapping |
| `LPToken.sol`    | Liquidity Tokens | ERC20 tokens representing pool shares                      |
| `ERC20Token.sol` | Test Tokens      | Basic ERC20 implementation for testing                     |

### Key Structures

```solidity
struct Reserve {
    uint256 reserveA;      // Reserve of first token
    uint256 reserveB;      // Reserve of second token
    uint256 totalLiquidity; // Total LP tokens minted
}

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
```

## 💡 Usage Examples

### Adding Liquidity

```solidity
SimpleSwap simpleSwap = SimpleSwap(contractAddress);

uint256 amountA = 1000 * 10**18; // 1000 tokens
uint256 amountB = 2000 * 10**18; // 2000 tokens

(uint256 actualAmountA, uint256 actualAmountB, uint256 liquidity) =
    simpleSwap.addLiquidity(
        tokenA,
        tokenB,
        amountA,        // amountADesired
        amountB,        // amountBDesired
        950 * 10**18,   // amountAMin (5% slippage)
        1900 * 10**18,  // amountBMin (5% slippage)
        msg.sender,     // to
        block.timestamp + 300 // deadline (5 minutes)
    );
```

### Swapping Tokens

```solidity
address[] memory path = new address[](2);
path[0] = tokenA; // Input token
path[1] = tokenB; // Output token

uint256[] memory amounts = simpleSwap.swapExactTokensForTokens(
    100 * 10**18,     // amountIn
    95 * 10**18,      // amountOutMin (5% slippage)
    path,             // path
    msg.sender,       // to
    block.timestamp + 300 // deadline
);
```

### Getting Price Information

```solidity
// Get current price of tokenA in terms of tokenB
uint256 price = simpleSwap.getPrice(tokenA, tokenB);

// Get expected output amount for a swap
uint256 expectedOutput = simpleSwap.getAmountOut(
    100 * 10**18,    // amountIn
    reserveIn,       // current reserve of input token
    reserveOut       // current reserve of output token
);
```

### Removing Liquidity

```solidity
(uint256 amountA, uint256 amountB) = simpleSwap.removeLiquidity(
    tokenA,
    tokenB,
    lpTokenAmount,    // liquidity to burn
    minAmountA,       // minimum tokenA to receive
    minAmountB,       // minimum tokenB to receive
    msg.sender,       // to
    block.timestamp + 300 // deadline
);
```

## 🔧 Installation & Setup

### Prerequisites

- Node.js v16+
- Hardhat or Foundry
- OpenZeppelin Contracts

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/simpleswap.git
cd simpleswap

# Install dependencies
npm install

# Install OpenZeppelin contracts
npm install @openzeppelin/contracts
```

### Compilation

```bash
# Using Hardhat
npx hardhat compile

# Using Foundry
forge build
```

## 🧪 Testing

### Deploy Test Tokens

```solidity
// Deploy two ERC20 tokens for testing
ERC20Token tokenA = new ERC20Token("Token A", "TKA", 1000000);
ERC20Token tokenB = new ERC20Token("Token B", "TKB", 1000000);
```

### Test Scenarios

1. **Pool Creation**: Test first liquidity addition
2. **Liquidity Addition**: Test adding to existing pools
3. **Token Swapping**: Test various swap scenarios
4. **Liquidity Removal**: Test LP token burning
5. **Edge Cases**: Test with zero amounts, expired deadlines

## 📊 Mathematical Formulas

### Constant Product Formula

```
x * y = k (where k remains constant)
```

### Price Calculation

```solidity
price = (reserveB * 1e18) / reserveA  // Price of tokenA in tokenB
```

### Swap Amount Calculation

```solidity
amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)
```

### Liquidity Token Calculation

```solidity
// For new pools
liquidity = (amount0 * amount1) / 1e18

// For existing pools
liquidity = min(
    (amount0 * totalSupply) / reserve0,
    (amount1 * totalSupply) / reserve1
)
```

## 🛡️ Security Considerations

### Implemented Protections

- ✅ **Slippage Protection**: Minimum amount parameters
- ✅ **Deadline Protection**: Time-based transaction expiry
- ✅ **Reentrancy Safe**: Uses OpenZeppelin's secure patterns
- ✅ **Integer Overflow**: Solidity 0.8+ built-in protection
- ✅ **Access Control**: Owner-only functions for LP tokens

### Recommendations

- Always set appropriate slippage tolerance
- Use reasonable deadline values
- Validate token addresses before interactions
- Monitor for front-running attacks in production

## 🔍 Events

The contract emits the following events for monitoring:

```solidity
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
```

## 🚧 Limitations

- **No Trading Fees**: Current implementation doesn't charge fees
- **Two-Token Swaps Only**: Multi-hop swaps not supported
- **No Flash Loans**: Flash loan functionality not implemented
- **Basic LP Token**: No additional LP token features

## 👨‍💻 Author

**Robert Rondón**

- Built as part of Eth Kipu blockchain development course

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Uniswap V2](https://uniswap.org/) for the AMM design inspiration
- [OpenZeppelin](https://openzeppelin.com/) for secure contract templates
- [Eth Kipu](https://ethkipu.org/) for the educational framework

---

⚠️ **Disclaimer**: This is an educational project. Use at your own risk in production environments.
