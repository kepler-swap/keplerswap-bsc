// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ICrycle {

    function userCrycle(address _user) external view returns (address);

}
