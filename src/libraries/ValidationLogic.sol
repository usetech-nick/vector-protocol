//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {WadRayMath} from "@aave/contracts/protocol/libraries/math/WadRayMath.sol";
import {ReserveConfig} from "../configuration/ReserveConfig.sol";

/**
 * @title ValidationLogic
 * @author Vector
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
    using WadRayMath for uint256;

    struct ValidateBorrowParams {
        uint256 amount;
        uint256 availableLiquidity;
        uint256 totalCollateralUSD;
        uint256 totalDebtUSD;
        uint256 liquidationThreshold;
        bool isActive;
    }

    struct ValidateWithdrawParams {
        uint256 amount;
        uint256 userBalance;
        uint256 totalCollateralUSD;
        uint256 totalDebtUSD;
        uint256 liquidationThreshold;
        bool isActive;
    }

    uint256 internal constant HEALTH_FACTOR_THRESHOLD = 1e18;

    error ValidationLogic__InvalidAmount();
    error ValidationLogic__ReserveNotActive();
    error ValidationLogic__InsufficientBalance();
    error ValidationLogic__InsufficientLiquidity();
    error ValidationLogic__InsufficientCollateral();
    error ValidationLogic__HealthFactorBelowThreshold();
    error ValidationLogic__NoDebtToRepay();

    /**
     * @notice Validates a deposit action
     * @param reserve The reserve data of the asset being deposited
     * @param amount The amount to deposit
     */
    function validateDeposit(ReserveConfig.ReserveData storage reserve, uint256 amount) internal view {
        if (amount == 0) revert ValidationLogic__InvalidAmount();
        if (!reserve.isActive) revert ValidationLogic__ReserveNotActive();
    }

    /**
     * @notice Validates a withdraw action
     * @dev Skips health factor check if user has no debt
     * @param params Struct containing withdraw validation parameters
     */

    function validateWithdraw(ValidateWithdrawParams memory params) internal pure {
        if (params.amount == 0) revert ValidationLogic__InvalidAmount();
        if (!params.isActive) revert ValidationLogic__ReserveNotActive();
        if (params.userBalance < params.amount) revert ValidationLogic__InsufficientBalance();

        if (params.totalDebtUSD == 0) return;
        uint256 hf =
            params.totalCollateralUSD.wadMul(params.liquidationThreshold.rayToWad()).wadDiv(params.totalDebtUSD);
        if (hf < HEALTH_FACTOR_THRESHOLD) revert ValidationLogic__InsufficientCollateral();
    }

    /**
     * @notice Validates a borrow action
     * @dev totalDebtUSD must already include the new borrow amount (post-action)
     * @param params Struct containing borrow validation parameters
     */
    function validateBorrow(ValidateBorrowParams memory params) internal pure {
        if (params.amount == 0) revert ValidationLogic__InvalidAmount();
        if (!params.isActive) revert ValidationLogic__ReserveNotActive();
        if (params.availableLiquidity < params.amount) revert ValidationLogic__InsufficientLiquidity();
        uint256 hf =
            params.totalCollateralUSD.wadMul(params.liquidationThreshold.rayToWad()).wadDiv(params.totalDebtUSD);
        if (hf < HEALTH_FACTOR_THRESHOLD) revert ValidationLogic__InsufficientCollateral();
    }

    /**
     * @notice Validates a repay action
     * @param reserve The reserve data of the asset being repaid
     * @param amount The amount to repay
     * @param userDebt The current actual debt of the user
     */
    function validateRepay(ReserveConfig.ReserveData storage reserve, uint256 amount, uint256 userDebt) internal view {
        if (amount == 0) revert ValidationLogic__InvalidAmount();
        if (!reserve.isActive) revert ValidationLogic__ReserveNotActive();
        if (userDebt == 0) revert ValidationLogic__NoDebtToRepay();
    }
}
