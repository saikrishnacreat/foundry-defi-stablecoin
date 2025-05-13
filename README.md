# Foundry DeFi Stablecoin

This project implements a decentralized, USD-pegged stablecoin as part of the [Cyfrin Updraft Advanced Foundry Course](https://updraft.cyfrin.io/). Built using Solidity and Foundry, the protocol allows users to deposit WETH and WBTC as collateral to mint a stablecoin, maintaining stability through over-collateralization and liquidation mechanisms.

## Table of Contents
- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Smart Contracts](#smart-contracts)
- [Test Cases](#test-cases)
- [Running Tests](#running-tests)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## Project Overview
The system consists of two core contracts:
- **DecentralizedStableCoin.sol**: An ERC20 token representing the USD-pegged stablecoin, with minting and burning restricted to the DSCEngine.
- **DSCEngine.sol**: Manages collateral deposits, redemptions, stablecoin minting/burning, and liquidations, using Chainlink price feeds for collateral valuation.

Key features:
- Supports WETH and WBTC as collateral.
- Maintains a health factor to ensure over-collateralization (150% minimum).
- Allows liquidation of under-collateralized positions.
- Uses Chainlink price feeds for real-time WETH/WBTC prices.

## Prerequisites
- [Git](https://git-scm.com/)
- [Foundry](https://book.getfoundry.sh/) (ensure `forge` version >= 0.2.0)
- A testnet RPC URL (e.g., Sepolia) and private key for deployment (set in `.env`)

## Installation
1. **Clone the Repository**:
    ```bash
    git clone https://github.com/saikrishnacreat/foundry-defi-stablecoin.git
    cd foundry-defi-stablecoin
    ```

2. **Install Foundry (if not already installed)**:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

3. **Install Dependencies**:
    ```bash
    forge install
    ```

4. **Set Up Environment Variables**:
    Create a `.env` file in the root directory:
    ```bash
    SEPOLIA_RPC_URL=<your-sepolia-rpc-url>
    PRIVATE_KEY=<your-private-key>
    ```
    > **Note**: Never commit your private key. Use a development wallet with no real funds.

5. **Compile the Contracts**:
    ```bash
    forge build
    ```

## Smart Contracts
- `src/DecentralizedStableCoin.sol`: Implements the stablecoin’s ERC20 functionality, with ownership by the DSCEngine.
- `src/DSCEngine.sol`: Core logic for depositing/redeeming collateral, minting/burning stablecoin, and liquidating positions.
- `script/DeployDSC.s.sol`: Deployment script for initializing the protocol with WETH/WBTC collateral and Chainlink price feeds.

## Test Cases
Comprehensive tests are written in Foundry to ensure protocol security and functionality. Tests cover unit, integration, fuzz, and invariant scenarios.

### Key Test Scenarios
- **Constructor Tests**:
  - Verify DSCEngine initializes with correct collateral tokens (WETH/WBTC) and price feeds.
  - Ensure DecentralizedStableCoin sets correct name ("Decentralized Stable Coin") and symbol ("DSC").

- **Collateral Deposit Tests**:
  - Test successful WETH/WBTC deposits with proper approvals.
  - Test reverts for zero-amount deposits or unsupported tokens.
  - Verify collateral balance updates in `s_collateralDeposited`.

- **Minting Tests**:
  - Test minting DSC with sufficient collateral (health factor > 1).
  - Test reverts when minting violates health factor or exceeds collateral value.
  - Verify `s_DSCMinted` and DSC balance update correctly.

- **Redemption Tests**:
  - Test redeeming collateral reduces `s_collateralDeposited`.
  - Test reverts for redeeming more than deposited.
  - Verify DSC is burned during redemption.

- **Liquidation Tests**:
  - Test liquidation of under-collateralized positions (health factor < 1) using mock price feed updates.
  - Test reverts for liquidating healthy positions.
  - Verify liquidator receives collateral and user’s debt is cleared.

- **Health Factor Tests**:
  - Test `getHealthFactor` for various collateral and debt amounts.
  - Test edge cases (e.g., zero collateral, maximum debt).

- **Price Feed Tests**:
  - Test collateral valuation updates with Chainlink price feed changes.
  - Test reverts for stale or invalid price feeds (using `OracleLib`).

- **Fuzz Tests**:
  - Fuzz collateral deposit amounts to prevent overflows/underflows.
  - Fuzz minting amounts to test health factor boundaries.

- **Invariant Tests**:
  - Ensure total DSC supply equals total minted amount (`s_DSCMinted`).
  - Verify protocol remains over-collateralized (total collateral value >= 150% of minted DSC).

## Running Tests
- **Run All Tests**:
  ```bash
  forge test
  ```

- **Run Specific Tests**:
  ```bash
  forge test --match-contract DSCEngineTest
  forge test --match-test testDepositCollateral
  ```

- **Verbose Output**:
  ```bash
  forge test -vvvv
  ```

- **Gas Snapshot**:
  ```bash
  forge snapshot
  ```

## Deployment
> **Note**: Deployment is not yet performed. To deploy to a testnet (e.g., Sepolia), configure your `.env` file and run:
```bash
forge script script/DeployDSC.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```
Update this section with deployed contract addresses once completed.

## Contributing
Contributions are welcome! To contribute:
1. Fork the repository.
2. Create a new branch:
    ```bash
    git checkout -b feature/your-feature
    ```
3. Make changes and commit:
    ```bash
    git commit -m "Add your feature"
    ```
4. Push to your fork:
    ```bash
    git push origin feature/your-feature
    ```
5. Open a pull request with a clear description.

> Ensure tests pass and follow the existing code style.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

---

Built by Saikrishna following the Cyfrin Updraft Advanced Foundry Course.
