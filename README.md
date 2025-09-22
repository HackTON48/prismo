# Prismo AMM - Innovative Automated Market Maker Protocol

## Project Overview

Prismo is an innovative AMM (Automated Market Maker) algorithm designed for HyperCore-Native-Token to efficiently establish liquidity pools on HyperEVM. Prismo AMM automatically concentrates liquidity around fair market prices (from HyperCore Orderbook), boosting trading fee efficiency and reducing impermanent loss for liquidity providers, while enabling LPs to earn both trading fees and lending interest simultaneously.

## Core Features

### 🎯 Dynamic Pricing Mechanism
- **Oracle Price Guidance**: AMM price starts with a "guide price" provided by HyperCore Orderbook oracle
- **Intelligent Price Adjustment**: Dynamically adjusts price based on oracle price and current pool token balances
- **Arbitrage Protection**: When the pool has a surplus of one token, the system adjusts the price to make that token cheaper, encouraging arbitrageurs to step in and restore balance

### 🔄 Automated Concentrated Liquidity
- **Slippage Factor k**: Key parameter determining how tightly liquidity is concentrated around the guide price
- **Auto-Follow**: Since the guide price is constantly updated by the oracle, the band of concentrated liquidity automatically shifts to follow external market price changes
- **Minimize Impermanent Loss**: Protects liquidity providers from arbitrage without requiring manual position management

### 💰 Dual Yield Mechanism
- **Trading Fees**: Collects fees from each transaction
- **Lending Interest**: Unused liquidity is automatically routed to external lending protocols (like AAVE, Morpho) to earn interest
- **Buffer System**: Holds small reserves of tokens, allowing most swaps to be processed gas-efficiently without costly interactions with lending protocols

## Technical Architecture

### Core Components

#### 1. Prismo Router
- **Entry Point**: Main entry point for traders
- **Multi-hop Routing**: Optimizes trade execution using multi-hop routing and intelligent order splitting
- **Large Trade Handling**: Divides large trades into smaller parts and executes them across different liquidity pools
- **Minimize Price Impact**: Achieves the best possible execution price for users

#### 2. Prismo AMM (Core AMM)
- **Highly Compressed Orderbook Simulation**: Designed like a highly compressed and flexible simulation of a traditional order book
- **Dynamic Pricing**: Smart pricing based on oracle price and pool balance
- **Concentrated Liquidity**: Automatically concentrates liquidity around market price

#### 3. Prismo Lending Hook
- **Dual Yields**: Enables liquidity providers to earn dual yields
- **External Protocol Integration**: Integrates with external lending protocols like AAVE and Morpho
- **Automatic Routing**: Unused liquidity is automatically routed to lending protocols

#### 4. Prismo Zoo
- **Pool Management**: Registry for all Prismo pools
- **Clone Factory**: Uses clone factory pattern to create new AMM pools
- **Permission Management**: Manages pool creation, updates, and removal

### Smart Contract Structure

```
prismo/
├── prismo.sol                 # Main contract entry point
├── PRISMOZoo.sol             # Pool registration and management
├── impl/                     # Core implementation
│   ├── Admin.sol             # Admin functions
│   ├── LiquidityProvider.sol # Liquidity provider functions
│   ├── Pricing.sol           # Pricing algorithm
│   ├── Settlement.sol        # Settlement logic
│   ├── Storage.sol           # Storage management
│   └── Trader.sol            # Trader functions
├── intf/                     # Interface definitions
│   ├── IPRISMO.sol           # Main interface
│   ├── IOracle.sol           # Oracle interface
│   └── IERC4626.sol          # ERC4626 vault interface
├── lib/                      # Library functions
│   ├── PRISMOMath.sol        # Mathematical calculations
│   ├── DecimalMath.sol       # Decimal operations
│   └── Types.sol             # Type definitions
└── token/                    # Token related
    ├── PRISMOToken.sol       # PRISMO token
    ├── PRISMOMine.sol        # Mining contract
    └── PRISMORewardVault.sol # Reward vault
```

## Core Algorithm

### PMM (Proactive Market Maker) Algorithm

Prismo uses an innovative PMM algorithm with the following characteristics:

1. **R Status Management**:
   - `R = 1`: Balanced state
   - `R > 1`: Base token surplus
   - `R < 1`: Quote token surplus

2. **Price Calculation**:
   - Based on oracle price and current R status
   - Uses quadratic function to solve for optimal price
   - Considers the impact of slippage factor k

3. **Liquidity Concentration**:
   - Controls liquidity concentration through k parameter
   - Automatically follows market price changes
   - Minimizes impermanent loss

## Usage Guide

### For Traders

#### Buy Base Token
```solidity
function buyBaseToken(
    uint256 amount,        // Amount of base tokens to buy
    uint256 maxPayQuote,   // Maximum quote tokens willing to pay
    bytes calldata data    // Callback data
) external returns (uint256);
```

#### Sell Base Token
```solidity
function sellBaseToken(
    uint256 amount,           // Amount of base tokens to sell
    uint256 minReceiveQuote,  // Minimum quote tokens expected to receive
    bytes calldata data       // Callback data
) external returns (uint256);
```

#### Query Prices
```solidity
function queryBuyBaseToken(uint256 amount) external view returns (uint256);
function querySellBaseToken(uint256 amount) external view returns (uint256);
```

### For Liquidity Providers

#### Deposit Liquidity
```solidity
function depositBaseTo(address to, uint256 amount) external returns (uint256);
function depositQuoteTo(address to, uint256 amount) external returns (uint256);
```

#### Withdraw Liquidity
```solidity
function withdrawBase(uint256 amount) external returns (uint256);
function withdrawQuote(uint256 amount) external returns (uint256);
function withdrawAllBase() external returns (uint256);
function withdrawAllQuote() external returns (uint256);
```

#### View LP Balance
```solidity
function getLpBaseBalance(address lp) public view returns (uint256);
function getLpQuoteBalance(address lp) public view returns (uint256);
```

### For Administrators

#### Create New AMM Pool
```solidity
function breedPRISMO(
    address maintainer,    // Maintainer address
    address baseToken,     // Base token address
    address quoteToken,    // Quote token address
    address oracle,        // Oracle address
    uint256 lpFeeRate,     // LP fee rate
    uint256 mtFeeRate,     // Maintainer fee rate
    uint256 k,             // Slippage factor
    uint256 gasPriceLimit  // Gas price limit
) external returns (address);
```

## Fee Structure

- **LP Fee Rate**: Fees paid to liquidity providers
- **Maintainer Fee Rate**: Fees paid to maintainers
- **Total Fee Rate**: LP Fee Rate + Maintainer Fee Rate < 1

## Security Features

1. **Reentrancy Protection**: Uses ReentrancyGuard to prevent reentrancy attacks
2. **Access Control**: Multi-level permission management (Owner, Supervisor, Maintainer)
3. **Gas Limits**: Prevents gas price attacks
4. **Parameter Validation**: Strict parameter checking
5. **Emergency Pause**: Supervisor can pause the system in emergencies

## Token Economics

### PRISMO Token
- **Total Supply**: 1 billion tokens
- **Use Cases**: Governance, mining rewards, fee payments
- **Mining**: Earn PRISMO tokens by providing liquidity

### Mining Mechanism
- **Stake LP Tokens**: Stake AMM pool LP tokens
- **Earn Rewards**: Earn PRISMO tokens based on stake amount and allocation points
- **Auto Compounding**: Rewards automatically accumulate

## Deployment and Usage

### Deployment Steps

1. **Deploy Core Contracts**:
   ```bash
   # Deploy PRISMO main contract
   # Deploy PRISMOZoo contract
   # Deploy PRISMOToken contract
   ```

2. **Initialize System**:
   ```solidity
   // Initialize PRISMOZoo
   prismoZoo.init(prismoLogic, cloneFactory, defaultSupervisor);
   
   // Create new AMM pool
   address newPool = prismoZoo.breedPRISMO(
       maintainer,
       baseToken,
       quoteToken,
       oracle,
       lpFeeRate,
       mtFeeRate,
       k,
       gasPriceLimit
   );
   ```

3. **Configure Permissions**:
   ```solidity
   // Set admin permissions
   // Enable trading and deposit functions
   ```

### Integration Guide

1. **Frontend Integration**:
   - Use Web3.js or ethers.js to connect to contracts
   - Implement trading interface
   - Display price and liquidity information

2. **Backend Integration**:
   - Listen to contract events
   - Calculate real-time prices
   - Manage user balances

## Advantages and Innovations

### Advantages over Traditional AMMs

1. **Lower Slippage**: Concentrates liquidity around market price
2. **Less Impermanent Loss**: Automatically follows market price changes
3. **Dual Yields**: Earn both trading fees and lending interest
4. **Better Price Discovery**: Oracle-based smart pricing

### Positive Impact on RWA Ecosystem

1. **Solves Liquidity Issues**: Provides deep liquidity for RWA tokens
2. **Reduces Participation Barriers**: Minimizes impermanent loss risk
3. **Improves Capital Efficiency**: Maximizes capital utilization
4. **Promotes Ecosystem Development**: Creates positive flywheel effects

## Risk Warnings

1. **Smart Contract Risk**: Code may contain vulnerabilities
2. **Oracle Risk**: Price data may be inaccurate
3. **Liquidity Risk**: May lack liquidity under extreme market conditions
4. **Regulatory Risk**: Relevant regulations may change

## Community and Support

- **GitHub**: https://github.com/prismo-amm
- **Documentation**: https://docs.prismo.finance
- **Discord**: https://discord.gg/prismo
- **Twitter**: @PrismoFinance

## License

This project is licensed under the Apache-2.0 License.

---

**Disclaimer**: This protocol is still under development and may contain risks. Please read the relevant documentation carefully and conduct thorough testing before use.
