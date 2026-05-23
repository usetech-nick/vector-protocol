// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library ReserveConfig {
    struct ReserveData {
        // token addresses
        address vTokenAddress;
        address debtTokenAddress;
        address interestRateModelAddress;

        // indices — both start at 1 RAY
        uint256 liquidityIndex; // depositIndex — grows at supplyRate (linear)
        uint256 borrowIndex; // grows at borrowRate (compounded)

        // current rates — stored for frontend reads
        uint256 currentLiquidityRate; // current supply APR in RAY
        uint256 currentBorrowRate; // current borrow APR in RAY

        // risk params — all in RAY
        uint256 ltv; // max borrow % e.g. 0.8e27
        uint256 liquidationThreshold; // HF drops below 1 when breached
        uint256 liquidationBonus; // liquidator's reward e.g. 0.05e27

        // meta
        uint40 lastUpdateTimestamp;
        bool isActive;
    }
}
