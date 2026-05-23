//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVToken is IERC20 {
    function mint(address user, uint256 amount, uint256 index) external;
    function burn(address user, uint256 amount, uint256 index) external;
    function scaledBalanceOf(address user) external view returns (uint256);
    function scaledTotalSupply() external view returns (uint256);
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
    function POOL() external view returns (address);
}
