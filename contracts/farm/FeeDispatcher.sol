// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '../interfaces/IKeplerPair.sol';
import '../interfaces/IMasterChef.sol';
import '../interfaces/ICrycleFarm.sol';
import '../interfaces/ILuckyPool.sol';
import '../interfaces/IInviter.sol';
import '../interfaces/IUser.sol';
import 'hardhat/console.sol';
import '@openzeppelin/contracts/utils/Address.sol';

contract FeeDispatcher is Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 constant TOTAL_PERCENT = 10000;

    enum FarmType {
        Account,
        Miner,
        InviteMiner,
        Crycle,
        Lucky,
        Inviter
    }

    event TransferFeeFarm(address to, address token, uint256 amount, uint256 farmType);

    struct Destination {
        address destination;
        uint256 percent;
        bool avaliable;
        FarmType farmType;
    }

    Destination[] public defaultDestination;

    function defaultDestinationLength() external view returns (uint256) {
        return defaultDestination.length;
    }

    function checkDefaultDestination() internal view {
        uint totalPercent = 0;
        for (uint i = 0; i < defaultDestination.length; i ++) {
            totalPercent = totalPercent.add(defaultDestination[i].percent);
        }
        require(totalPercent >= 0 && totalPercent <= TOTAL_PERCENT, "illegal totalPercent");
    }

    function addDefaultDestination(address _destination, uint256 _percent, uint256 _farmType) external onlyOwner {
        defaultDestination.push(Destination({
            destination: _destination,
            percent: _percent,
            avaliable: true,
            farmType: FarmType(_farmType)
        }));
        checkDefaultDestination();
    }

    function delDefaultDestination(uint id) external onlyOwner {
        require(id >= 0 && id < defaultDestination.length, "illegal id");
        if (id < defaultDestination.length - 1) {
            Destination memory lastDestination = defaultDestination[defaultDestination.length - 1];
            Destination storage toDeleteDestination = defaultDestination[id];
            toDeleteDestination.destination = lastDestination.destination;
            toDeleteDestination.percent = lastDestination.percent;
            toDeleteDestination.avaliable = lastDestination.avaliable;
            toDeleteDestination.farmType = lastDestination.farmType;
        }
        defaultDestination.pop();
    }

    mapping(address => Destination[]) tokenDestination;

    function tokenDestinationLength(address token) external view returns (uint256) {
        return tokenDestination[token].length;
    }

    function checkTokenDestination(address token) internal view {
        uint totalPercent = 0;
        Destination[] storage _tokenDestination = tokenDestination[token];
        for (uint i = 0; i < _tokenDestination.length; i ++) {
            totalPercent = totalPercent.add(_tokenDestination[i].percent);
        }
        require(totalPercent >= 0 && totalPercent <= TOTAL_PERCENT, "illegal totalPercent");
    }

    function addTokenDestination(address _token, address _destination, uint256 _percent, uint256 _farmType) external onlyOwner {
        tokenDestination[_token].push(Destination({
            destination: _destination,
            percent: _percent,
            avaliable: true,
            farmType: FarmType(_farmType)
        }));
        checkTokenDestination(_token);
    }

    function delTokenDestination(address token, uint id) external onlyOwner {
        require(id >= 0 && id < tokenDestination[token].length, "illegal id");
        if (id < tokenDestination[token].length - 1) {
            Destination memory lastDestination = tokenDestination[token][tokenDestination[token].length - 1];
            Destination storage toDeleteDestination = tokenDestination[token][id];
            toDeleteDestination.destination = lastDestination.destination;
            toDeleteDestination.percent = lastDestination.percent;
            toDeleteDestination.avaliable = lastDestination.avaliable;
            toDeleteDestination.farmType = lastDestination.farmType;
        }
        tokenDestination[token].pop();
    }

    mapping(address => Destination[]) relateDestination;

    function relateDestinationLength(address token) external view returns (uint256) {
        return relateDestination[token].length;
    }

    function checkRelateDestination(address token) internal view {
        uint totalPercent = 0;
        Destination[] storage _tokenDestination = relateDestination[token];
        for (uint i = 0; i < _tokenDestination.length; i ++) {
            totalPercent = totalPercent.add(_tokenDestination[i].percent);
        }
        require(totalPercent >= 0 && totalPercent <= TOTAL_PERCENT, "illegal totalPercent");
    }

    function addRelateDestination(address _token, address _destination, uint256 _percent, uint256 _farmType) external onlyOwner {
        relateDestination[_token].push(Destination({
            destination: _destination,
            percent: _percent,
            avaliable: true,
            farmType: FarmType(_farmType)
        }));
        checkRelateDestination(_token);
    }

    function delRelateDestination(address token, uint id) external onlyOwner {
        require(id >= 0 && id < relateDestination[token].length, "illegal id");
        if (id < relateDestination[token].length - 1) {
            Destination memory lastDestination = relateDestination[token][relateDestination[token].length - 1];
            Destination storage toDeleteDestination = relateDestination[token][id];
            toDeleteDestination.destination = lastDestination.destination;
            toDeleteDestination.percent = lastDestination.percent;
            toDeleteDestination.avaliable = lastDestination.avaliable;
            toDeleteDestination.farmType = lastDestination.farmType;
        }
        relateDestination[token].pop();
    }

    function doHardWork(address pair, address token, address user, uint256 amount) external {
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
        Destination[] memory destinations;
        if (tokenDestination[token].length > 0) {
            destinations = tokenDestination[token];
        } else if (pair != address(0)) {
            address relateToken = token == IKeplerPair(pair).token0() ? IKeplerPair(pair).token1() : IKeplerPair(pair).token0();
            if (relateDestination[relateToken].length > 0) {
                destinations = relateDestination[relateToken];
            } else {
                destinations = defaultDestination;
            }
        } else {
            destinations = defaultDestination;
        }
        for (uint i = 0; i < destinations.length; i ++) {
            uint farmAmount = amount.mul(destinations[i].percent).div(TOTAL_PERCENT);
            if (destinations[i].farmType == FarmType.Account) {
                SafeERC20.safeTransfer(IERC20(token), destinations[i].destination, farmAmount);
            } else if (destinations[i].farmType == FarmType.Miner) {
                IERC20(token).approve(destinations[i].destination, farmAmount);
                IMasterChef(destinations[i].destination).doMiner(IKeplerPair(pair), IERC20(token), farmAmount);
            } else if (destinations[i].farmType == FarmType.InviteMiner) {
                IERC20(token).approve(destinations[i].destination, farmAmount);
                IMasterChef(destinations[i].destination).doInviteMiner(IKeplerPair(pair), IERC20(token), farmAmount);
            } else if (destinations[i].farmType == FarmType.Crycle) {
                IERC20(token).approve(destinations[i].destination, farmAmount);
                ICrycleFarm(destinations[i].destination).doHardWork(user, IERC20(token), farmAmount);
            } else if (destinations[i].farmType == FarmType.Inviter) {
                IERC20(token).approve(destinations[i].destination, farmAmount);
                IInviter(destinations[i].destination).doHardWork(user, token, farmAmount);
            } else if (destinations[i].farmType == FarmType.Lucky) {
                IERC20(token).approve(destinations[i].destination, farmAmount);
                ILuckyPool(destinations[i].destination).doHardWork(IKeplerPair(pair), token, farmAmount);
            } else {
                continue;
            }
            emit TransferFeeFarm(destinations[i].destination, token, farmAmount, uint(destinations[i].farmType));
        }
    }

    function transferOut(IERC20 token, uint256 amount) external onlyOwner {
        SafeERC20.safeTransfer(token, owner(), amount);
    }

    function transferETH(uint256 amount) external onlyOwner {
        Address.sendValue(payable(owner()), amount);
    }
}
