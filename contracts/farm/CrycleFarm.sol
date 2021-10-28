// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '../interfaces/IKeplerFactory.sol';
import '../interfaces/IKeplerToken.sol';
import '../interfaces/IKeplerPair.sol';
import '../interfaces/ICrycle.sol';
import '../interfaces/IUser.sol';

contract CrycleFarm {
    using SafeMath for uint256;

    ICrycle crycle;

    constructor(ICrycle _crycle) {
        crycle = _crycle;
    }

    mapping(address => mapping(address => uint)) public reward;

    function doHardWork(address _user, IERC20 token, uint amount) external {
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);
        address crycleCreator = crycle.userCrycle(_user);
        reward[crycleCreator][address(token)] = amount;
    }

    function claim(address _user, address _token) external {
        if (reward[_user][_token] > 0) {
            SafeERC20.safeTransfer(IERC20(_token), _user, reward[_user][_token]);
            reward[_user][_token] = 0;
        }
    }

}
