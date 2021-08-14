// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ICrycleFarm {

    function doHardWork(address _user, IERC20 token, uint amount) external;

}
