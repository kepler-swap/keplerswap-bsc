// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IKeplerPair.sol';

interface IInviter {

    function profits(address user, address token) external view returns (uint);

    function doHardWork(address _user, address _token, uint256 _amount) external;

}
