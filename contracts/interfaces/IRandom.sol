// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

interface IRandom {

    function win(string memory r, uint256 maxNum) external returns (uint256);

}
