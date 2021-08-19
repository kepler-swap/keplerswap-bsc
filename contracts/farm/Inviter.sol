// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '../interfaces/IUser.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

contract Inviter is ReentrancyGuard {
    using SafeMath for uint256;

    IUser user;
    mapping(address => mapping(address => uint256)) public profits;

    constructor(IUser _user) {
        user = _user;
    }

    function doHardWork(address _user, address _token, uint256 _amount) external nonReentrant {
        SafeERC20.safeTransferFrom(IERC20(_token), msg.sender, address(this), _amount);
        address _inviter = user.inviter(_user);
        require(_inviter != address(0), "inviter not exist");
        profits[_inviter][_token] = profits[_inviter][_token].add(_amount);
    }

    function claim(address _token) external {
        SafeERC20.safeTransfer(IERC20(_token), msg.sender, profits[msg.sender][_token]); 
        profits[msg.sender][_token] = 0;
    }

}
