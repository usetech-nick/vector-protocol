# Vector Protocol

A minimal, auditable two-asset lending protocol built on Ethereum.

Vector lets users deposit WETH as collateral and borrow USDC against it. USDC liquidity providers earn yield from borrower interest. Designed to be fully readable in one sitting — no governance, no upgradeability, no flash loans. Just core lending mechanics done correctly.

---

## How it works

```
USDC LPs    →  deposit USDC  →  earn supply APR from borrowers
Borrowers   →  deposit WETH  →  borrow USDC  →  pay borrow APR
Liquidators →  repay debt    →  receive WETH collateral + bonus
```

Interest accrues every second via a global index. No per-user updates. O(1) gas regardless of user count.

---

## Architecture

```
src/
  core/
    LendingPool.sol          — entry point, orchestration only
    ReserveLogic.sol         — index update logic
    ValidationLogic.sol      — all checks before actions

  tokens/
    VToken.sol               — rebasing ERC20 for depositors (balanceOf returns real amount)
    DebtToken.sol            — non-transferable ERC20 for borrowers

  libraries/
    WadRayMath.sol           — imported from Aave v3 (MIT)
    MathUtils.sol            — imported from Aave v3 (MIT)

  configuration/
    ReserveConfig.sol        — ReserveData struct

  interfaces/
    ILendingPool.sol
    IVToken.sol
    IDebtToken.sol
    IPriceOracle.sol
    IInterestRateModel.sol

  oracle/
    PriceOracle.sol          — Chainlink primary, TWAP fallback

  InterestRateModel.sol      — kinked rate model
```

---

## Design decisions

**Why two assets only?**
Scope constraint as a feature. A WETH/USDC protocol is fully auditable in one sitting. Every production protocol started minimal — Morpho, Euler, Term Finance. Complexity is added after trust is established.

**Why no upgradeability?**
Upgradeable contracts require trusting the upgrade key. Immutable contracts require trusting only the code. For a v1 protocol, immutability is a stronger security guarantee.

**Why vTokens instead of cTokens?**
vTokens rebase — `balanceOf()` returns the real underlying amount including accrued interest. Users see their balance grow without any transaction. Cleaner UX than the cToken exchange rate model.

**Why non-transferable debt tokens?**
Transferable debt would allow users to move undercollateralized positions to wallets that can't be liquidated. Non-transferable debt keeps the liquidation model simple and safe.

**Why a separate InterestRateModel contract?**
Deploying a new InterestRateModel and pointing the reserve to it is cheaper and safer than upgrading the core protocol. Rate parameters can be adjusted without touching the lending logic.

**Interest rate model**
Kinked model with two slopes. Below 80% utilization rates climb gently. Above 80% they climb steeply — punishing illiquidity and incentivizing repayment.

```
borrow APR = baseRate + slope1 × utilization           (below kink)
borrow APR = baseRate + slope1 + slope2 × excessUtil   (above kink)
supply APR = borrow APR × utilization
```

**Precision**
All internal math uses RAY (1e27) precision via WadRayMath, imported directly from Aave v3. Token amounts are normalized to WAD (1e18) at the oracle boundary. No raw decimal arithmetic anywhere in the protocol.

**Interest accrual asymmetry**
Deposit index grows via linear interest. Borrow index grows via compounded interest (3rd order Taylor approximation). Borrowers pay slightly more than depositors earn — the spread is the protocol's buffer against bad debt.

---

## What this protocol does not implement (but could in the future)

- Flash loans
- Stable borrow rate
- Governance / timelock
- Upgradeability
- Multi-collateral
- Referral codes
- Reward tokens / liquidity mining

These are deliberate exclusions, not missing features.

---

## Acknowledgements

Interest rate math and precision libraries adapted from [Aave v3](https://github.com/aave/aave-v3-core) (MIT License). Scaled balance pattern inspired by [Compound v2](https://compound.finance/documents/Compound.Whitepaper.pdf).

---

## Status

🚧 In development — not audited, do not use in production.
