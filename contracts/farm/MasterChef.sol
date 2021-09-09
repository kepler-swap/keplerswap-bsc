// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '../interfaces/IKeplerPair.sol';
import '../interfaces/IKeplerRouter.sol';
import '../interfaces/IUser.sol';
import '../interfaces/IWETH.sol';
import '../libraries/KeplerLibrary.sol';
import 'hardhat/console.sol';

contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IUser user;
    address public immutable WETH;

    uint256 public currentSnapshotId;
    mapping(IKeplerPair => mapping(address => uint256)) userSnapshotId;
    mapping(IKeplerPair => mapping(address => uint256)) userSnapshotAmount;
    address public snapshotCreateCaller;
    uint256 constant public RATIO = 1e18;

    struct UserLockInfo {
        uint256 amount;     
        uint256 shares;
        uint256 lockType;
        uint256 depositAt;
        uint256 expireAt;
    }

    struct UserInfo {
        uint256 amount;     
        uint256 shares;
        uint256 token0Debt;
        uint256 token1Debt;
        uint256 token0Pending;
        uint256 token1Pending;
    }

    struct PoolInfo {
        uint256 totalShares;
        uint256 token0AccPerShare;
        uint256 token1AccPerShare;
        bool avaliable;
    }

    mapping(IKeplerPair => PoolInfo) public poolInfo;
    mapping(IKeplerPair => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint256) userMaxLockId;
    mapping(IKeplerPair => mapping(address => mapping(uint256 => UserLockInfo))) public userLockInfo;
    mapping(IKeplerPair => mapping(address => mapping(uint256 => uint256))) public userLockTypeAmount;

    mapping(IKeplerPair => PoolInfo) public inviterPoolInfo;
    mapping(IKeplerPair => mapping(address => UserInfo)) public inviterUserInfo;

    event Deposit(address indexed user, address indexed inviter, address indexed pair, uint256 lockId, uint256 amount, uint256 shares, uint256 lockType);
    event Withdraw(address indexed user, address indexed inviter, address indexed pair, uint256 lockId, uint256 amount, uint256 shares, uint256 lockType);
    event NewSnapshot(uint256 snapshotId);

    constructor(IUser _user, address _weth) {
        user = _user;
        WETH = _weth;
    }

    function setSnapshotCreateCaller(address _snapshotCreateCaller) external onlyOwner {
        snapshotCreateCaller = _snapshotCreateCaller;
    }

    function addDefaultPool(IKeplerPair pair) internal {
        if (poolInfo[pair].avaliable == true) {
            return;
        }
        PoolInfo storage _poolInfo = poolInfo[pair];
        _poolInfo.avaliable = true;
        if (inviterPoolInfo[pair].avaliable == true) {
            return;
        }
        PoolInfo storage _inviterPoolInfo = inviterPoolInfo[pair];
        _inviterPoolInfo.avaliable = true;
    }

    function doMiner(IKeplerPair pair, IERC20 token, uint256 amount) external {
        addDefaultPool(pair);
        address _token0 = pair.token0();
        address _token1 = pair.token1();
        require(address(token) == _token0 || address(token) == _token1, "illegal token");
        bool isToken0 = address(token) == _token0;
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);
        PoolInfo memory _poolInfo = poolInfo[pair];
        if (_poolInfo.totalShares == 0) {
            return;
        }
        if (isToken0) {
            poolInfo[pair].token0AccPerShare = _poolInfo.token0AccPerShare.add(amount.mul(RATIO).div(_poolInfo.totalShares));
        } else {
            poolInfo[pair].token1AccPerShare = _poolInfo.token1AccPerShare.add(amount.mul(RATIO).div(_poolInfo.totalShares));
        }
    }

    function doInviteMiner(IKeplerPair pair, IERC20 token, uint256 amount) external {
        addDefaultPool(pair);
        address _token0 = pair.token0();
        address _token1 = pair.token1();
        require(address(token) == _token0 || address(token) == _token1, "illegal token");
        bool isToken0 = address(token) == _token0;
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);
        PoolInfo memory _poolInfo = inviterPoolInfo[pair];
        if (_poolInfo.totalShares == 0) {
            return;
        }
        if (isToken0) {
            inviterPoolInfo[pair].token0AccPerShare = _poolInfo.token0AccPerShare.add(amount.mul(RATIO).div(_poolInfo.totalShares));
        } else {
            inviterPoolInfo[pair].token1AccPerShare = _poolInfo.token1AccPerShare.add(amount.mul(RATIO).div(_poolInfo.totalShares));
        }
    }

    function userClear(IKeplerPair _pair, address _user, PoolInfo memory _poolInfo, UserInfo memory _userInfo) internal {
        if (_userInfo.shares > 0) {
            uint256 token0Debt = _userInfo.shares.mul(_poolInfo.token0AccPerShare).div(RATIO);
            userInfo[_pair][_user].token0Pending = _userInfo.token0Pending.add(token0Debt.sub(_userInfo.token0Debt));
            userInfo[_pair][_user].token0Debt = token0Debt;

            uint256 token1Debt = _userInfo.shares.mul(_poolInfo.token1AccPerShare).div(RATIO);
            userInfo[_pair][_user].token1Pending = _userInfo.token1Pending.add(token1Debt.sub(_userInfo.token1Debt));
            userInfo[_pair][_user].token1Debt = token1Debt;
        }
    }

    function userClear(IKeplerPair _pair, address _user) internal {
        if (userInfo[_pair][_user].shares > 0) {
            uint256 token0Debt = userInfo[_pair][_user].shares.mul(poolInfo[_pair].token0AccPerShare).div(RATIO);
            userInfo[_pair][_user].token0Pending = userInfo[_pair][_user].token0Pending.add(token0Debt.sub(userInfo[_pair][_user].token0Debt));
            userInfo[_pair][_user].token0Debt = token0Debt;

            uint256 token1Debt = userInfo[_pair][_user].shares.mul(poolInfo[_pair].token1AccPerShare).div(RATIO);
            userInfo[_pair][_user].token1Pending = userInfo[_pair][_user].token1Pending.add(token1Debt.sub(userInfo[_pair][_user].token1Debt));
            userInfo[_pair][_user].token1Debt = token1Debt;
        }
    }

    function inviterClear(IKeplerPair _pair, address _user, PoolInfo memory _poolInfo, UserInfo memory _userInfo) internal {
        if (_userInfo.shares > 0) {
            uint userShares = userInfo[_pair][_user].shares;
            uint256 token0Debt = _userInfo.shares.mul(_poolInfo.token0AccPerShare).div(RATIO);
            if (userShares > 0) {
                inviterUserInfo[_pair][_user].token0Pending = _userInfo.token0Pending.add(token0Debt.sub(_userInfo.token0Debt));
            }
            inviterUserInfo[_pair][_user].token0Debt = token0Debt;

            uint256 token1Debt = _userInfo.shares.mul(_poolInfo.token1AccPerShare).div(RATIO);
            if (userShares > 0) {
                inviterUserInfo[_pair][_user].token1Pending = _userInfo.token1Pending.add(token1Debt.sub(_userInfo.token1Debt));
            }
            inviterUserInfo[_pair][_user].token1Debt = token1Debt;
        }
    }

    function inviterClear(IKeplerPair _pair, address _user) internal {
        if (inviterUserInfo[_pair][_user].shares > 0) {
            uint userShares = userInfo[_pair][_user].shares;
            uint256 token0Debt = inviterUserInfo[_pair][_user].shares.mul(inviterPoolInfo[_pair].token0AccPerShare).div(RATIO);
            if (userShares > 0) {
                inviterUserInfo[_pair][_user].token0Pending = inviterUserInfo[_pair][_user].token0Pending.add(token0Debt.sub(inviterUserInfo[_pair][_user].token0Debt));
            }
            inviterUserInfo[_pair][_user].token0Debt = token0Debt;

            uint256 token1Debt = inviterUserInfo[_pair][_user].shares.mul(inviterPoolInfo[_pair].token1AccPerShare).div(RATIO);
            if (userShares > 0) {
                inviterUserInfo[_pair][_user].token1Pending = inviterUserInfo[_pair][_user].token1Pending.add(token1Debt.sub(inviterUserInfo[_pair][_user].token1Debt));
            }
            inviterUserInfo[_pair][_user].token1Debt = token1Debt;
        }
    }

    function getType(uint lockType) public pure returns (uint256, uint256) {
        if (lockType == 0) {
            return (3, 0); 
        } else if (lockType == 1) {
            return (10, 30 days);
            //return (10, 30 * 24 * 60 * 60);
        } else if (lockType == 2) {
            return (15, 90 days);
            //return (15, 90 * 24 * 60 * 60);
        } else if (lockType == 3) {
            return (30, 360 days);
            //return (30, 360* 24 * 60 * 60);
        } else {
            revert ("illegal lockType");
        }
        return (0, 0);
    }

    function inviteDeposit(address _user, IKeplerPair _pair, uint256 _amount, uint256 _shares) internal {
        address _inviter = user.inviter(_user);
        require(_inviter != address(0), "user not registe");
        PoolInfo memory _poolInfo = inviterPoolInfo[_pair];
        UserInfo memory _userInfo = inviterUserInfo[_pair][_inviter];
        inviterClear(_pair, _inviter, _poolInfo, _userInfo);
        if (_shares > 0) {
            if (userInfo[_pair][_inviter].shares > 0) {
                inviterPoolInfo[_pair].totalShares = _poolInfo.totalShares.add(_shares); 
            }
            inviterUserInfo[_pair][_inviter].shares = _userInfo.shares.add(_shares);
            inviterUserInfo[_pair][_inviter].amount = _userInfo.amount.add(_amount);
            inviterUserInfo[_pair][_inviter].token0Debt = _userInfo.shares.add(_shares).mul(_poolInfo.token0AccPerShare).div(RATIO);
            inviterUserInfo[_pair][_inviter].token1Debt = _userInfo.shares.add(_shares).mul(_poolInfo.token1AccPerShare).div(RATIO);
        }
    }

    function deposit(IKeplerPair _pair, uint256 _amount, uint256 _lockType) external {
        depositFor(_pair, _amount, _lockType, msg.sender);
    }

    function depositFor(IKeplerPair _pair, uint256 _amount, uint256 _lockType, address to) public {
        _beforeDepositOrWithdraw(_pair, to, _amount);
        addDefaultPool(_pair);
        (uint ratio, uint lockTime) = getType(_lockType);
        PoolInfo memory _poolInfo = poolInfo[_pair];
        UserInfo memory _userInfo = userInfo[_pair][to];
        userClear(_pair, to, _poolInfo, _userInfo);
        uint shares = _amount.mul(ratio);
        require(_amount > 0, "illegal amount");
        SafeERC20.safeTransferFrom(IERC20(address(_pair)), msg.sender, address(this), _amount);

        uint lockId = userMaxLockId[to];
        UserLockInfo storage _userLockInfo = userLockInfo[_pair][to][lockId];
        _userLockInfo.amount = _amount;
        _userLockInfo.shares = shares;
        _userLockInfo.lockType = _lockType;
        _userLockInfo.depositAt = block.timestamp;
        _userLockInfo.expireAt = block.timestamp + lockTime;
        userMaxLockId[to] = lockId.add(1);
        if (_userInfo.shares == 0) {
            inviterClear(_pair, to);
            inviterPoolInfo[_pair].totalShares = inviterPoolInfo[_pair].totalShares.add(inviterUserInfo[_pair][to].shares);
        }
        poolInfo[_pair].totalShares = _poolInfo.totalShares.add(shares);
        userInfo[_pair][to].shares = _userInfo.shares.add(shares);
        userInfo[_pair][to].amount = _userInfo.amount.add(_amount);
        userInfo[_pair][to].token0Debt = _userInfo.shares.add(shares).mul(_poolInfo.token0AccPerShare).div(RATIO);
        userInfo[_pair][to].token1Debt = _userInfo.shares.add(shares).mul(_poolInfo.token1AccPerShare).div(RATIO);
        userLockTypeAmount[_pair][to][_lockType] = userLockTypeAmount[_pair][to][_lockType].add(_amount);
        inviteDeposit(to, _pair, _amount, shares);
        emit Deposit(to, user.inviter(to), address(_pair), lockId,  _amount, shares, _lockType);
    }

    function inviteWithdraw(address _user, IKeplerPair _pair, uint256 _amount, uint256 _shares) internal {
        address _inviter = user.inviter(_user);
        require(_inviter != address(0), "user not registe");
        PoolInfo memory _poolInfo = inviterPoolInfo[_pair];
        UserInfo memory _userInfo = inviterUserInfo[_pair][_inviter];
        inviterClear(_pair, _inviter, _poolInfo, _userInfo);
        if (_shares > 0) {
            if (userInfo[_pair][_inviter].shares > 0) {
                inviterPoolInfo[_pair].totalShares = _poolInfo.totalShares.sub(_shares); 
            }
            inviterUserInfo[_pair][_inviter].shares = _userInfo.shares.sub(_shares);
            inviterUserInfo[_pair][_inviter].amount = _userInfo.amount.sub(_amount);
        }
        inviterUserInfo[_pair][_inviter].token0Debt = _userInfo.shares.sub(_shares).mul(_poolInfo.token0AccPerShare).div(RATIO);
        inviterUserInfo[_pair][_inviter].token1Debt = _userInfo.shares.sub(_shares).mul(_poolInfo.token1AccPerShare).div(RATIO);
    }

    function withdraw(IKeplerPair _pair, uint256 _lockId, uint256 amount0Min, uint256 amount1Min) external nonReentrant {
        UserLockInfo memory _userLockInfo = userLockInfo[_pair][msg.sender][_lockId];
        require(_userLockInfo.amount > 0, "illegal lock id");
        require (block.timestamp >= _userLockInfo.expireAt, "not the right time");
        PoolInfo memory _poolInfo = poolInfo[_pair];
        UserInfo memory _userInfo = userInfo[_pair][msg.sender];
        _beforeDepositOrWithdraw(_pair, msg.sender, _userInfo.amount);
        userClear(_pair, msg.sender, _poolInfo, _userInfo);
        poolInfo[_pair].totalShares = _poolInfo.totalShares.sub(_userLockInfo.shares); 
        userInfo[_pair][msg.sender].shares = _userInfo.shares.sub(_userLockInfo.shares);
        userInfo[_pair][msg.sender].amount = _userInfo.amount.sub(_userLockInfo.amount);
        userLockTypeAmount[_pair][msg.sender][_userLockInfo.lockType] = userLockTypeAmount[_pair][msg.sender][_userLockInfo.lockType].sub(_userLockInfo.amount);
        if (_userInfo.shares == _userLockInfo.shares) {
            inviterClear(_pair, msg.sender);
            inviterPoolInfo[_pair].totalShares = inviterPoolInfo[_pair].totalShares.sub(inviterUserInfo[_pair][msg.sender].shares);
        }
        uint amount0 = 0;
        uint amount1 = 0;
        if (_userLockInfo.amount > 0) {
            address token0 = _pair.token0();
            address token1 = _pair.token1();
            SafeERC20.safeTransfer(IERC20(address(_pair)), address(_pair), _userLockInfo.amount);
            if (token0 == WETH) {
                (amount0, amount1) = _pair.burn(address(this));
                SafeERC20.safeTransfer(IERC20(token1), msg.sender, amount1);
                IWETH(WETH).withdraw(amount0);
                (bool success,) = msg.sender.call{value:amount0}(new bytes(0));
                require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
            } else if (token1 == WETH) {
                (amount0, amount1) = _pair.burn(address(this));
                SafeERC20.safeTransfer(IERC20(token0), msg.sender, amount0);
                IWETH(WETH).withdraw(amount1);
                (bool success,) = msg.sender.call{value:amount1}(new bytes(0));
                require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
            } else {
                (amount0, amount1) = _pair.burn(msg.sender);
            }
        }
        require(amount0 >= amount0Min && amount1 >= amount1Min, "illegal witdraw slippage");
        uint256 _amount = _userLockInfo.amount;
        uint256 _shares = _userLockInfo.shares;
        delete userLockInfo[_pair][msg.sender][_lockId];
        userInfo[_pair][msg.sender].token0Debt = _userInfo.shares.sub(_shares).mul(_poolInfo.token0AccPerShare).div(RATIO);
        userInfo[_pair][msg.sender].token1Debt = _userInfo.shares.sub(_shares).mul(_poolInfo.token1AccPerShare).div(RATIO);
        inviteWithdraw(msg.sender, _pair, _amount, _shares);
        emit Withdraw(msg.sender, user.inviter(msg.sender), address(_pair), _lockId, _userLockInfo.amount, _userLockInfo.shares, _userLockInfo.lockType);
    }

    function createSnapshot(uint256 id) external {
        require(msg.sender == snapshotCreateCaller, "only snapshotCreateCaller can do this");
        require(id > currentSnapshotId, "illegal snapshotId");
        require(id < currentSnapshotId + 100, "snapshot id too big");
        currentSnapshotId = id; 
        emit NewSnapshot(currentSnapshotId);
    }

    function getUserSnapshot(address pair, address _user) external view returns (uint256) {
        if (currentSnapshotId == 0) {
            return userInfo[IKeplerPair(pair)][_user].amount;
        } else if (userSnapshotId[IKeplerPair(pair)][_user] == currentSnapshotId) {
            return userSnapshotAmount[IKeplerPair(pair)][_user];
        } else {
            return userInfo[IKeplerPair(pair)][_user].amount;
        }
    }

    function _beforeDepositOrWithdraw(IKeplerPair pair, address _user, uint256) internal {
        if (currentSnapshotId == 0) {
            return;
        }
        if (userSnapshotId[pair][_user] < currentSnapshotId) {
            userSnapshotAmount[pair][_user] = userInfo[pair][_user].amount;
            userSnapshotId[pair][_user] = currentSnapshotId;
        }
    }

    function getUserAmount(IKeplerPair pair, address _user, uint lockType) external view returns (uint) {
        return userLockTypeAmount[pair][_user][lockType];
    }

    function getInviterAmount(IKeplerPair pair, address inviter) external view returns (uint) {
        return inviterUserInfo[pair][inviter].amount;
    }

    function getPoolInfo(IKeplerPair _pair) external view returns (uint256 totalShares, uint256 token0AccPerShare, uint256 token1AccPerShare) {
        PoolInfo memory _poolInfo = poolInfo[_pair];
        totalShares = _poolInfo.totalShares;
        token0AccPerShare = _poolInfo.token0AccPerShare;
        token1AccPerShare = _poolInfo.token1AccPerShare;
    }

    function getUserInfo(IKeplerPair _pair, address _user) external view returns (uint256 amount, uint256 shares, uint256 token0Debt, uint256 token1Debt, uint256 token0Pending, uint256 token1Pending) {
        UserInfo memory _userInfo = userInfo[_pair][_user];
        amount = _userInfo.amount;
        shares = _userInfo.shares;
        token0Debt = _userInfo.token0Debt;
        token1Debt = _userInfo.token1Debt;
        token0Pending = _userInfo.token0Pending;
        token1Pending = _userInfo.token1Pending;
    }

    function getInvitePoolInfo(IKeplerPair _pair) external view returns (uint256 totalShares, uint256 token0AccPerShare, uint256 token1AccPerShare) {
        PoolInfo memory _poolInfo = inviterPoolInfo[_pair];
        totalShares = _poolInfo.totalShares;
        token0AccPerShare = _poolInfo.token0AccPerShare;
        token1AccPerShare = _poolInfo.token1AccPerShare;
    }

    function getInviteUserInfo(IKeplerPair _pair, address _user) external view returns (uint256 amount, uint256 shares, uint256 token0Debt, uint256 token1Debt, uint256 token0Pending, uint256 token1Pending) {
        UserInfo memory _userInfo = inviterUserInfo[_pair][_user];
        amount = _userInfo.amount;
        shares = _userInfo.shares;
        token0Debt = _userInfo.token0Debt;
        token1Debt = _userInfo.token1Debt;
        token0Pending = _userInfo.token0Pending;
        token1Pending = _userInfo.token1Pending;
    }

    function claimMine(IKeplerPair _pair, address _token) external nonReentrant {
        address token0 = _pair.token0();
        address token1 = _pair.token1();
        uint amount = 0;
        if (_token == token0) {
            uint acc = poolInfo[_pair].token0AccPerShare;
            uint shares = userInfo[_pair][msg.sender].shares;
            uint debt = userInfo[_pair][msg.sender].token0Debt;
            uint pending = userInfo[_pair][msg.sender].token0Pending;
            amount = acc.mul(shares).div(RATIO).sub(debt).add(pending);
            userInfo[_pair][msg.sender].token0Debt = acc.mul(shares).div(RATIO);
            userInfo[_pair][msg.sender].token0Pending = 0;
        } else if (_token == token1) {
            uint acc = poolInfo[_pair].token1AccPerShare;
            uint shares = userInfo[_pair][msg.sender].shares;
            uint debt = userInfo[_pair][msg.sender].token1Debt;
            uint pending = userInfo[_pair][msg.sender].token1Pending;
            amount = acc.mul(shares).div(RATIO).sub(debt).add(pending);
            userInfo[_pair][msg.sender].token1Debt = acc.mul(shares).div(RATIO);
            userInfo[_pair][msg.sender].token1Pending = 0;
        } else {
            require(false, "illegal token");
        }
        SafeERC20.safeTransfer(IERC20(_token), msg.sender, amount);
    }

    function claimInviteMine(IKeplerPair _pair, address _token) external nonReentrant {
        address token0 = _pair.token0();
        address token1 = _pair.token1();
        uint amount = userInfo[_pair][msg.sender].amount;
        if (amount == 0) {
            return;
        }
        if (_token == token0) {
            uint acc = inviterPoolInfo[_pair].token0AccPerShare;
            uint shares = inviterUserInfo[_pair][msg.sender].shares;
            uint debt = inviterUserInfo[_pair][msg.sender].token0Debt;
            uint pending = inviterUserInfo[_pair][msg.sender].token0Pending;
            amount = acc.mul(shares).div(RATIO).sub(debt).add(pending);
            inviterUserInfo[_pair][msg.sender].token0Debt = acc.mul(shares).div(RATIO);
            inviterUserInfo[_pair][msg.sender].token0Pending = 0;
        } else if (_token == token1) {
            uint acc = inviterPoolInfo[_pair].token1AccPerShare;
            uint shares = inviterUserInfo[_pair][msg.sender].shares;
            uint debt = inviterUserInfo[_pair][msg.sender].token1Debt;
            uint pending = inviterUserInfo[_pair][msg.sender].token1Pending;
            amount = acc.mul(shares).div(RATIO).sub(debt).add(pending);
            inviterUserInfo[_pair][msg.sender].token1Debt = acc.mul(shares).div(RATIO);
            inviterUserInfo[_pair][msg.sender].token1Pending = 0;
        } else {
            require(false, "illegal token");
        }
        SafeERC20.safeTransfer(IERC20(_token), msg.sender, amount);
    }
}
