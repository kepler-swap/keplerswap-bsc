// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '../libraries/KeplerLibrary.sol';
import '../interfaces/IKeplerFactory.sol';
import '../interfaces/IKeplerPair.sol';
import '../interfaces/IMasterChef.sol';
import '../interfaces/IUser.sol';
import '../interfaces/IInviter.sol';
import 'hardhat/console.sol';

contract Lens is Ownable {
    using SafeMath for uint256;

    struct UserLockInfo {
        uint amount;
        string symbol0;
        string symbol1;
        uint amount0;
        uint amount1;
        uint shares;
        uint lockType;
        uint depositAt;
        uint expireAt;
    }

    function getLockInfoLength(IMasterChef _masterChef, IKeplerPair _pair, address user) external view returns (uint256) {
        return _masterChef.userLockNum(_pair, user);
    }

    function getLockInfo(IMasterChef _masterChef, IKeplerPair _pair, address user, uint from, uint size) external view returns (UserLockInfo[] memory) {
        string memory symbol0 = ERC20(_pair.token0()).symbol();
        string memory symbol1 = ERC20(_pair.token1()).symbol();
        uint balance0 = IERC20(_pair.token0()).balanceOf(address(_pair));
        uint balance1 = IERC20(_pair.token1()).balanceOf(address(_pair));
        uint totalSupply = _pair.totalSupply(); 
        uint totalNum = _masterChef.userLockNum(_pair, user);
        size = totalNum.sub(from) > size ? size : totalNum.sub(from);
        UserLockInfo[] memory res = new UserLockInfo[](size);
        uint currentId = 0;
        for (uint i = from; i < from.add(size); i ++) {
            (res[currentId].amount, res[currentId].shares, res[currentId].lockType, res[currentId].depositAt, res[currentId].expireAt) = _masterChef.userLockInfo(_pair, user, i);
            res[currentId].symbol0 = symbol0;
            res[currentId].symbol1 = symbol1;
            if (totalSupply != 0) {
                res[currentId].amount0 = res[currentId].amount.mul(balance0).div(totalSupply);
                res[currentId].amount1 = res[currentId].amount.mul(balance1).div(totalSupply);
            } else {
                res[currentId].amount0 = 0;
                res[currentId].amount1 = 0;
            }
            currentId = currentId.add(1);
        }
        return res;
    }

    struct SwapInfo {
        uint amountIn;
        uint amountOut;
        uint fee;
        uint affect;
    }

    function getSwapInfoOut(IKeplerFactory _factory, address[] memory _path, uint amountIn) external view returns (SwapInfo memory swapInfo) {
        swapInfo.amountIn = amountIn;
        uint256[] memory fees = _factory.getTransferFee(_path);
        swapInfo.fee = fees[0].mul(amountIn).div(1000);
        uint256[] memory amounts = KeplerLibrary.getAmountsOut(address(_factory), amountIn, _path, fees);
        swapInfo.amountOut = amounts[amounts.length - 1];
        (uint reserve0, uint reserve1, ) = IKeplerPair(_factory.getPair(_path[0], _path[1])).getReserves();
        uint reserve = _path[0] == IKeplerPair(_factory.getPair(_path[0], _path[1])).token0() ? reserve0 : reserve1;
        swapInfo.affect = amounts[0].sub(fees[0]).mul(1e18).div(reserve.add(amounts[0].sub(fees[0])));
    }

    function getSwapInfoIn(IKeplerFactory _factory, address[] memory _path, uint amountOut) external view returns (SwapInfo memory swapInfo) {
        swapInfo.amountOut = amountOut;
        uint256[] memory fees = _factory.getTransferFee(_path);
        uint256[] memory amounts = KeplerLibrary.getAmountsIn(address(_factory), amountOut, _path, fees);
        swapInfo.fee = fees[0].mul(amounts[0]).div(1000);
        swapInfo.amountIn = amounts[0];
        (uint reserve0, uint reserve1, ) = IKeplerPair(_factory.getPair(_path[0], _path[1])).getReserves();
        uint reserve = _path[0] == IKeplerPair(_factory.getPair(_path[0], _path[1])).token0() ? reserve0 : reserve1;
        swapInfo.affect = amounts[0].sub(fees[0]).mul(1e18).div(reserve.add(amounts[0].sub(fees[0])));
    }

    function pendingMine(IMasterChef _masterChef, IKeplerPair _pair, address _token, address _user) external view returns (uint256) {
        address token0 = _pair.token0();
        address token1 = _pair.token1();
        if (_token == token0) {
            (, uint256 acc,) = _masterChef.getPoolInfo(_pair);
            (, uint256 shares, uint256 debt, , uint256 pending, ) = _masterChef.getUserInfo(_pair, _user);
            return acc.mul(shares).div(1e18).sub(debt).add(pending);
        } else if (_token == token1) {
            (, , uint256 acc) = _masterChef.getPoolInfo(_pair);
            (, uint256 shares, , uint256 debt, , uint256 pending) = _masterChef.getUserInfo(_pair, _user);
            return acc.mul(shares).div(1e18).sub(debt).add(pending);
        } else {
            require(false, "illegal token");
        }
        return 0;
    }

    function pendingInviteMine(IMasterChef _masterChef, IKeplerPair _pair, address _token, address _user) external view returns (uint256) {
        address token0 = _pair.token0();
        address token1 = _pair.token1();
        (uint amount, , , , ,) = _masterChef.getUserInfo(_pair, _user);
        if (amount == 0) {
            return 0;
        }
        if (_token == token0) {
            (, uint256 acc,) = _masterChef.getInvitePoolInfo(_pair);
            (, uint256 shares, uint256 debt, , uint256 pending, ) = _masterChef.getInviteUserInfo(_pair, _user);
            return acc.mul(shares).div(1e18).sub(debt).add(pending);
        } else if (_token == token1) {
            (, , uint256 acc) = _masterChef.getInvitePoolInfo(_pair);
            (, uint256 shares, , uint256 debt, , uint256 pending) = _masterChef.getInviteUserInfo(_pair, _user);
            return acc.mul(shares).div(1e18).sub(debt).add(pending);
        } else {
            require(false, "illegal token");
        }
        return 0;
    }

    function pendingInvite(IInviter _inviter, address _token, address _user) external view returns (uint256) {
        return _inviter.profits(_user, _token);
    }

    struct MineInfo {
        string symbol0;
        string symbol1;
        uint256 amount;
        uint256 shares;
        uint256 amount0;
        uint256 amount1;
        uint256 percent;
    }

    function getMineInfo(IMasterChef _masterChef, IKeplerPair _pair, address _user) external view returns (MineInfo memory mineInfo) {
        address token0 = _pair.token0();
        address token1 = _pair.token1();
        mineInfo.symbol0 = ERC20(token0).symbol();
        mineInfo.symbol1 = ERC20(token1).symbol();
        (mineInfo.amount, mineInfo.shares, , , ,) = _masterChef.getUserInfo(_pair, _user);
        uint balance0 = IERC20(_pair.token0()).balanceOf(address(_pair));
        uint balance1 = IERC20(_pair.token1()).balanceOf(address(_pair));
        uint totalSupply = _pair.totalSupply(); 
        if (totalSupply != 0) {
            mineInfo.amount0 = mineInfo.amount.mul(balance0).div(totalSupply);
            mineInfo.amount1 = mineInfo.amount.mul(balance1).div(totalSupply);
        } else {
            mineInfo.amount0 = 0;
            mineInfo.amount1 = 0;
        }
        (uint256 totalShares, ,) = _masterChef.getPoolInfo(_pair);
        if (totalShares > 0) {
            mineInfo.percent = mineInfo.shares.mul(1e18).div(totalShares);
        } else {
            mineInfo.percent = 0;
        }
    }

    function getInviteInfo(IMasterChef _masterChef, IKeplerPair _pair, address _user) external view returns (MineInfo memory mineInfo) {
        address token0 = _pair.token0();
        address token1 = _pair.token1();
        mineInfo.symbol0 = ERC20(token0).symbol();
        mineInfo.symbol1 = ERC20(token1).symbol();
        (mineInfo.amount, mineInfo.shares, , , ,) = _masterChef.getInviteUserInfo(_pair, _user);
        uint balance0 = IERC20(_pair.token0()).balanceOf(address(_pair));
        uint balance1 = IERC20(_pair.token1()).balanceOf(address(_pair));
        uint totalSupply = _pair.totalSupply(); 
        if (totalSupply != 0) {
            mineInfo.amount0 = mineInfo.amount.mul(balance0).div(totalSupply);
            mineInfo.amount1 = mineInfo.amount.mul(balance1).div(totalSupply);
        } else {
            mineInfo.amount0 = 0;
            mineInfo.amount1 = 0;
        }
        (uint256 totalShares, ,) = _masterChef.getInvitePoolInfo(_pair);
        if (totalShares > 0) {
            mineInfo.percent = mineInfo.shares.mul(1e18).div(totalShares);
        } else {
            mineInfo.percent = 0;
        }
    }

    function getAmountOut(IKeplerPair _pair, address token, uint256 amountIn) external view returns (uint256) {
        (uint reserve0, uint reserve1, ) = _pair.getReserves();
        if (token == _pair.token0()) {
            if (reserve0 == 0) {
                return 0;
            } else {
                return reserve1.mul(amountIn).div(reserve0); 
            }
        } else {
            if (reserve1 == 0) {
                return 0;
            } else {
                return reserve0.mul(amountIn).div(reserve1);
            }
        }
    }
}
