// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

interface IUser {

    function inviter(address user) external view returns (address);

    function inviteNume(address user) external view returns (uint256);

    function userNum() external view returns (uint256);

    function registe(address _inviter) external;

    function userExists(address user) external view returns (bool);
}
