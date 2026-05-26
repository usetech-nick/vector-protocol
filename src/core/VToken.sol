// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {WadRayMath} from "@aave/contracts/protocol/libraries/math/WadRayMath.sol";
import {ILendingPool} from "../interfaces/ILendingPool.sol";
import {IVToken} from "../interfaces/IVToken.sol";

/**
 * @title VToken
 * @author Vector
 * @notice Rebasing ERC20 representing a user's deposit in the protocol
 * @dev balanceOf() returns real underlying amount including accrued interest
 *      internally stores scaled shares — actual balance = shares × currentIndex
 */
contract VToken is ERC20, IVToken {
    using WadRayMath for uint256;

    error VToken__callerNotPool();

    address public immutable POOL;
    address public immutable UNDERLYING_ASSET_ADDRESS;

    mapping(address => uint256) private _scaledBalances;
    uint256 private _scaledTotalSupply;

    modifier onlyPool() {
        if (msg.sender != POOL) {
            revert VToken__callerNotPool();
        }
        _;
    }

    constructor(address pool, address underlyingAsset, string memory name, string memory symbol) ERC20(name, symbol) {
        POOL = pool;
        UNDERLYING_ASSET_ADDRESS = underlyingAsset;
    }

    /**
     * @notice Mints vTokens to a user representing their deposit
     * @dev Stores scaled shares (amount / index) not raw amount
     *      Only callable by LendingPool
     * @param user The address receiving the vTokens
     * @param amount The underlying amount being deposited
     * @param index The current liquidity index of the reserve
     */
    function mint(address user, uint256 amount, uint256 index) external onlyPool {
        uint256 scaledAmount = amount.rayDiv(index);
        _scaledBalances[user] += scaledAmount;
        _scaledTotalSupply += scaledAmount;
        emit Transfer(address(0), user, amount);
    }

    /**
     * @notice Burns vTokens from a user on withdrawal
     * @dev Removes scaled shares (amount / index) from storage
     *      Only callable by LendingPool
     * @param user The address whose vTokens are being burned
     * @param amount The underlying amount being withdrawn
     * @param index The current liquidity index of the reserve
     */
    function burn(address user, uint256 amount, uint256 index) external onlyPool {
        uint256 scaledAmount = amount.rayDiv(index);
        _scaledBalances[user] -= scaledAmount;
        _scaledTotalSupply -= scaledAmount;
        emit Transfer(user, address(0), amount);
    }

    /**
     * @notice Returns the actual underlying balance including accrued interest
     * @dev Reads current liquidityIndex from LendingPool and multiplies by stored shares
     *      balance grows every second as the index increases
     * @param user The address to query
     * @return The actual underlying amount the user can withdraw
     */
    function balanceOf(address user) public view override(ERC20, IERC20) returns (uint256) {
        uint256 index = ILendingPool(POOL).getReserveData(UNDERLYING_ASSET_ADDRESS).liquidityIndex;
        return _scaledBalances[user].rayMul(index);
    }

    /**
     * @notice Returns the total underlying represented by all vTokens
     * @dev Rebasing — grows as interest accrues
     * @return The total underlying amount across all depositors
     */
    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        uint256 index = ILendingPool(POOL).getReserveData(UNDERLYING_ASSET_ADDRESS).liquidityIndex;
        return _scaledTotalSupply.rayMul(index);
    }

    /**
     * @notice Returns the raw scaled shares of a user without index multiplication
     * @dev Used internally by the protocol for accounting
     * @param user The address to query
     * @return The scaled share balance
     */
    function scaledBalanceOf(address user) external view returns (uint256) {
        return _scaledBalances[user];
    }

    /**
     * @notice Returns the total raw scaled shares without index multiplication
     * @return The total scaled supply
     */
    function scaledTotalSupply() external view returns (uint256) {
        return _scaledTotalSupply;
    }
}
