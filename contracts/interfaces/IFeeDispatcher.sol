// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
/*
import '../libraries/SafeMath.sol';
import '../interfaces/IBEP20.sol';
import '../token/SafeBEP20.sol';

import "../token/BabyToken.sol";
import "./SyrupBar.sol";
*/
// import "@nomiclabs/buidler/console.sol";

interface IFeeDispatcher {

    function tokenDestinationLength(address token) external view returns (uint256);

    function defaultDestinationLength(address token) external view returns (uint256);

    function addDefaultDestination(address destination, uint256 percent) external; 

    function delDefaultDestination(uint id) external;

    function setDefaultDestination(uint id, uint percent) external;

    function addTokenDestination(address token, address destination, uint256 percent) external;

    function delTokenDestination(address token, uint id) external;

    function setTokenDestination(address token, uint id, uint percent) external;
    
    function doMultilyHardwork(address[] memory tokens) external;

    function doHardWork(address pair, address token, address user, uint256 amount) external;
}
