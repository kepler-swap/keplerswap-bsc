// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IKeplerPair.sol';

interface ILuckyPool {

    function doHardWork(IKeplerPair _pair, address _token, uint256 _amount) external;

}
