// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract User {
    using SafeMath for uint256;

    event NewUser(address user, address inviter, uint256 timestamp);

    mapping(address => address) public inviter;
    mapping(address => uint256) public inviteNum;
    uint256 public userNum;

    constructor() {
    }

    function registe(address _inviter) external {
        require(msg.sender != _inviter, "can not invite yourself");
        if (userNum > 0) {
            require(inviter[_inviter] != address(0), "inviter not exists");
        }
        inviter[msg.sender] = _inviter;
        userNum = userNum.add(1);
        inviteNum[_inviter] = inviteNum[_inviter].add(1);
        emit NewUser(msg.sender, _inviter, block.timestamp);
    }

    function userExists(address user) external view returns (bool) {
        return inviter[user] != address(0);
    }
}
