// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import './IKeplerPair.sol';

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKeplerToken is IERC20 {

    function createSnapshot(uint256 id) external;

    function getUserSnapshot(address user) external view returns (uint256);

}
