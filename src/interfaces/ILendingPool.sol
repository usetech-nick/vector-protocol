//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ReserveConfig} from "../configuration/ReserveConfig.sol";

interface ILendingPool {
    function deposit(address asset, uint256 amount, address onBehalfOf) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function borrow(address asset, uint256 amount, address onBehalfOf) external;
    function repay(address asset, uint256 amount, address onBehalfOf) external returns (uint256);
    function initReserve(
        address asset,
        address vTokenAddress,
        address debtTokenAddress,
        address interestRateModelAddress,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external;
    // view functions
    function getReserveData(address asset) external view returns (ReserveConfig.ReserveData memory);
    function getHealthFactor(address user) external view returns (uint256);
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralValue,
            uint256 totalDebtValue,
            uint256 availableBorrowsValue,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}
