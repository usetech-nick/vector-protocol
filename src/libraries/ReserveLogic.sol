//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ReserveConfig} from "../configuration/ReserveConfig.sol";
import {MathUtils} from "@aave/contracts/protocol/libraries/math/MathUtils.sol";
import {WadRayMath} from "@aave/contracts/protocol/libraries/math/WadRayMath.sol";
import {IInterestRateModel} from "../interfaces/IInterestRateModel.sol";

/**
 * @title ReserveLogic
 * @author Vector
 * @notice Implements the logic to update the reserve state and interest rates
 */
library ReserveLogic {
    using WadRayMath for uint256;

    /**
     * @notice Updates the reserve liquidity and borrow indices
     * @dev liquidityIndex grows via linear interest, borrowIndex via compounded interest
     *      No-op if called twice in the same block or if reserve is uninitialized
     * @param reserve The reserve data to update
     */
    function updateState(ReserveConfig.ReserveData storage reserve) internal {
        if (reserve.lastUpdateTimestamp == uint40(block.timestamp)) return;
        if (reserve.liquidityIndex == 0) return;

        reserve.liquidityIndex = reserve.liquidityIndex
            .rayMul(MathUtils.calculateLinearInterest(reserve.currentLiquidityRate, reserve.lastUpdateTimestamp));
        uint40 currentTimestamp = uint40(block.timestamp);
        reserve.borrowIndex = reserve.borrowIndex
            .rayMul(
                MathUtils.calculateCompoundedInterest(
                    reserve.currentBorrowRate, reserve.lastUpdateTimestamp, currentTimestamp
                )
            );
        reserve.lastUpdateTimestamp = currentTimestamp;
    }

    /**
     * @notice Recalculates and stores the current borrow and liquidity rates
     * @dev Called after every state-changing action to reflect new utilization
     *      supplyRate = borrowRate × utilization — depositors only earn on deployed capital
     * @param reserve The reserve data to update
     * @param totalDeposits Total underlying asset deposited in the reserve
     * @param totalBorrows Total underlying asset borrowed from the reserve
     */
    function updateInterestRates(ReserveConfig.ReserveData storage reserve, uint256 totalDeposits, uint256 totalBorrows)
        internal
    {
        uint256 utilization = totalDeposits == 0 ? 0 : totalBorrows.rayDiv(totalDeposits);
        IInterestRateModel interestRateModel = IInterestRateModel(reserve.interestRateModelAddress);
        reserve.currentBorrowRate = interestRateModel.getBorrowRate(totalBorrows, totalDeposits);
        reserve.currentLiquidityRate = reserve.currentBorrowRate.rayMul(utilization);
    }
}
