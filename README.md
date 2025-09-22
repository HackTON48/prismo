# Prismo AMM - 创新的自动化做市商协议

## 项目简介

Prismo是一个创新的AMM（自动化做市商）算法，专为HyperCore-Native-Token设计，旨在在HyperEVM上高效建立流动性池。Prismo AMM能够自动将流动性集中在公平市场价格周围（来自HyperCore Orderbook），提升交易费用效率并减少流动性提供者的无常损失，同时让流动性提供者能够同时获得交易费用和借贷利息。

## 核心特性

### 🎯 动态定价机制
- **Oracle价格引导**：AMM价格以HyperCore Orderbook oracle提供的"指导价格"为起点
- **智能价格调整**：根据oracle价格和池子当前代币余额动态调整价格
- **套利保护**：当池子中某种代币过剩时，系统调整价格使该代币更便宜，鼓励套利者介入恢复平衡

### 🔄 自动化集中流动性
- **滑点因子k**：关键参数决定流动性在指导价格周围的集中程度
- **自动跟随**：由于指导价格由oracle持续更新，集中流动性带自动跟随外部市场价格变化
- **最小化无常损失**：无需流动性提供者手动管理头寸即可保护其免受套利影响

### 💰 双重收益机制
- **交易费用**：从每笔交易中收取费用
- **借贷利息**：未使用的流动性自动路由到外部借贷协议（如AAVE、Morpho）获得利息
- **缓冲系统**：持有少量代币储备，使大多数交换能够高效处理而无需每次与借贷协议进行昂贵的交互

## 技术架构

### 核心组件

#### 1. Prismo Router（路由器）
- **入口点**：交易者的主要入口
- **多跳路由**：使用多跳路由和智能订单分割优化交易执行
- **大额交易处理**：将大额交易分割成小部分，在不同流动性池中执行
- **最小化价格影响**：为用户实现最佳执行价格

#### 2. Prismo AMM（核心AMM）
- **高度压缩的订单簿模拟**：设计得像传统订单簿的高度压缩和灵活模拟
- **动态定价**：基于oracle价格和池子余额的智能定价
- **集中流动性**：自动将流动性集中在市场价格周围

#### 3. Prismo Lending Hook（借贷钩子）
- **双重收益**：让流动性提供者获得双重收益
- **外部协议集成**：与AAVE、Morpho等外部借贷协议集成
- **自动路由**：未使用的流动性自动路由到借贷协议

#### 4. Prismo Zoo（动物园）
- **池子管理**：所有Prismo池子的注册中心
- **克隆工厂**：使用克隆工厂模式创建新的AMM池子
- **权限管理**：管理池子的创建、更新和移除

### 智能合约结构

```
prismo/
├── prismo.sol                 # 主合约入口
├── PRISMOZoo.sol             # 池子注册和管理
├── impl/                     # 核心实现
│   ├── Admin.sol             # 管理员功能
│   ├── LiquidityProvider.sol # 流动性提供者功能
│   ├── Pricing.sol           # 定价算法
│   ├── Settlement.sol        # 结算逻辑
│   ├── Storage.sol           # 存储管理
│   └── Trader.sol            # 交易者功能
├── intf/                     # 接口定义
│   ├── IPRISMO.sol           # 主接口
│   ├── IOracle.sol           # Oracle接口
│   └── IERC4626.sol          # ERC4626金库接口
├── lib/                      # 库函数
│   ├── PRISMOMath.sol        # 数学计算
│   ├── DecimalMath.sol       # 小数运算
│   └── Types.sol             # 类型定义
└── token/                    # 代币相关
    ├── PRISMOToken.sol       # PRISMO代币
    ├── PRISMOMine.sol        # 挖矿合约
    └── PRISMORewardVault.sol # 奖励金库
```

## 核心算法

### PMM（Proactive Market Maker）算法

Prismo使用创新的PMM算法，具有以下特点：

1. **R状态管理**：
   - `R = 1`：平衡状态
   - `R > 1`：基础代币过剩
   - `R < 1`：报价代币过剩

2. **价格计算**：
   - 基于oracle价格和当前R状态
   - 使用二次函数求解最优价格
   - 考虑滑点因子k的影响

3. **流动性集中**：
   - 通过k参数控制流动性集中程度
   - 自动跟随市场价格变化
   - 最小化无常损失

## 使用方法

### 对于交易者

#### 购买基础代币
```solidity
function buyBaseToken(
    uint256 amount,        // 要购买的基础代币数量
    uint256 maxPayQuote,   // 愿意支付的最大报价代币数量
    bytes calldata data    // 回调数据
) external returns (uint256);
```

#### 出售基础代币
```solidity
function sellBaseToken(
    uint256 amount,           // 要出售的基础代币数量
    uint256 minReceiveQuote,  // 期望收到的最少报价代币数量
    bytes calldata data       // 回调数据
) external returns (uint256);
```

#### 查询价格
```solidity
function queryBuyBaseToken(uint256 amount) external view returns (uint256);
function querySellBaseToken(uint256 amount) external view returns (uint256);
```

### 对于流动性提供者

#### 存入流动性
```solidity
function depositBaseTo(address to, uint256 amount) external returns (uint256);
function depositQuoteTo(address to, uint256 amount) external returns (uint256);
```

#### 提取流动性
```solidity
function withdrawBase(uint256 amount) external returns (uint256);
function withdrawQuote(uint256 amount) external returns (uint256);
function withdrawAllBase() external returns (uint256);
function withdrawAllQuote() external returns (uint256);
```

#### 查看LP余额
```solidity
function getLpBaseBalance(address lp) public view returns (uint256);
function getLpQuoteBalance(address lp) public view returns (uint256);
```

### 对于管理员

#### 创建新的AMM池子
```solidity
function breedPRISMO(
    address maintainer,    // 维护者地址
    address baseToken,     // 基础代币地址
    address quoteToken,    // 报价代币地址
    address oracle,        // Oracle地址
    uint256 lpFeeRate,     // LP费用率
    uint256 mtFeeRate,     // 维护者费用率
    uint256 k,             // 滑点因子
    uint256 gasPriceLimit  // Gas价格限制
) external returns (address);
```

## 费用结构

- **LP费用率**：支付给流动性提供者的费用
- **维护者费用率**：支付给维护者的费用
- **总费用率**：LP费用率 + 维护者费用率 < 1

## 安全特性

1. **重入保护**：使用ReentrancyGuard防止重入攻击
2. **权限控制**：多级权限管理（Owner、Supervisor、Maintainer）
3. **Gas限制**：防止Gas价格攻击
4. **参数验证**：严格的参数检查
5. **紧急暂停**：Supervisor可以在紧急情况下暂停系统

## 代币经济学

### PRISMO代币
- **总供应量**：10亿枚
- **用途**：治理、挖矿奖励、费用支付
- **挖矿**：通过提供流动性获得PRISMO代币奖励

### 挖矿机制
- **质押LP代币**：质押AMM池子的LP代币
- **获得奖励**：根据质押数量和分配点获得PRISMO代币
- **自动复利**：奖励自动累积

## 部署和使用

### 部署步骤

1. **部署核心合约**：
   ```bash
   # 部署PRISMO主合约
   # 部署PRISMOZoo合约
   # 部署PRISMOToken合约
   ```

2. **初始化系统**：
   ```solidity
   // 初始化PRISMOZoo
   prismoZoo.init(prismoLogic, cloneFactory, defaultSupervisor);
   
   // 创建新的AMM池子
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

3. **配置权限**：
   ```solidity
   // 设置管理员权限
   // 启用交易和存款功能
   ```

### 集成指南

1. **前端集成**：
   - 使用Web3.js或ethers.js连接合约
   - 实现交易界面
   - 显示价格和流动性信息

2. **后端集成**：
   - 监听合约事件
   - 计算实时价格
   - 管理用户余额

## 优势和创新点

### 相比传统AMM的优势

1. **更低的滑点**：集中流动性在市场价格周围
2. **更少的无常损失**：自动跟随市场价格变化
3. **双重收益**：同时获得交易费用和借贷利息
4. **更好的价格发现**：基于oracle的智能定价

### 对RWA生态的积极影响

1. **解决流动性问题**：为RWA代币提供深度流动性
2. **降低参与门槛**：减少无常损失风险
3. **提高资本效率**：最大化资金利用率
4. **促进生态发展**：创造正向飞轮效应

## 风险提示

1. **智能合约风险**：代码可能存在漏洞
2. **Oracle风险**：价格数据可能不准确
3. **流动性风险**：极端市场条件下可能缺乏流动性
4. **监管风险**：相关法规可能发生变化

## 社区和支持

- **GitHub**：https://github.com/prismo-amm
- **文档**：https://docs.prismo.finance
- **Discord**：https://discord.gg/prismo
- **Twitter**：@PrismoFinance

## 许可证

本项目采用Apache-2.0许可证。

---

**免责声明**：本协议仍在开发中，可能存在风险。使用前请仔细阅读相关文档并进行充分测试。
