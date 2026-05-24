//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ReserveConfig} from "../configuration/ReserveConfig.sol";
import {MathUtils} from "@aave/contracts/protocol/libraries/math/MathUtils.sol";
import {WadRayMath} from "@aave/contracts/protocol/libraries/math/WadRayMath.sol";
import {IInterestRateModel} from "../interfaces/IInterestRateModel.sol";

library ReserveLogic {
    using WadRayMath for uint256;

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

    function updateInterestRates(ReserveConfig.ReserveData storage reserve, uint256 totalDeposits, uint256 totalBorrows)
        internal
    {
        uint256 utilization = totalDeposits == 0 ? 0 : totalBorrows.rayDiv(totalDeposits);
        IInterestRateModel interestRateModel = IInterestRateModel(reserve.interestRateModelAddress);
        reserve.currentBorrowRate = interestRateModel.getBorrowRate(totalBorrows, totalDeposits);
        reserve.currentLiquidityRate = reserve.currentBorrowRate.rayMul(utilization);
    }
}
