// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IKeplerPair.sol';

interface IMasterChef {

    function getUserAmount(IKeplerPair pair, address user, uint lockType) external view returns (uint);

    function getInviterAmount(IKeplerPair pair, address inviter) external view returns (uint);

    function createSnapshot(uint256 id) external;

    function getUserSnapshot(IKeplerPair pair, address _user) external view returns (uint256);

    function doMiner(IKeplerPair pair, IERC20 token, uint256 amount) external;

    function deposit(IKeplerPair _pair, uint256 _amount, uint256 _lockType) external;

    function depositFor(IKeplerPair _pair, uint256 _amount, uint256 _lockType, address to) external;

    function getPoolInfo(IKeplerPair _pair) external view returns (uint256 totalShares, uint256 token0AccPerShare, uint256 token1AccPerShare);

    function getUserInfo(IKeplerPair _pair, address _user) external view returns (uint256 amount, uint256 shares, uint256 token0Debt, uint256 token1Debt, uint256 token0Pending, uint256 token1Pending);

    function getInvitePoolInfo(IKeplerPair _pair) external view returns (uint256 totalShares, uint256 token0AccPerShare, uint256 token1AccPerShare);

    function getInviteUserInfo(IKeplerPair _pair, address _user) external view returns (uint256 amount, uint256 shares, uint256 token0Debt, uint256 token1Debt, uint256 token0Pending, uint256 token1Pending);

    function doInviteMiner(IKeplerPair pair, IERC20 token, uint256 amount) external;

    function userLockNum(IKeplerPair _pair, address user) external view returns (uint256);

    function userLockInfo(IKeplerPair _pair, address _user, uint256 id) external view returns (uint256, uint256, uint256, uint256, uint256);
}
