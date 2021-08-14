// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import './KeplerPair.sol';
import '../libraries/KeplerLibrary.sol';
import '../interfaces/IKeplerPair.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract KeplerFactory is Ownable {
    using SafeMath  for uint;

    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(KeplerPair).creationCode));

    address public feeTo;

    mapping(address => mapping(address => address)) public getPair;
    uint public allPairsLength;
    bool public whiteListAvaliable;
    mapping(address => bool) public whiteList;
    uint public defaultTransferFee;
    mapping(address => uint) public tokenTransferFee;
    mapping(address => uint) public relateTransferFee;

    uint256 public currentSnapshotId;
    mapping(address => mapping(address => uint256)) userSnapshotId;
    mapping(address => mapping(address => uint256)) userSnapshotAmount;
    mapping(address => mapping(address => uint256)) pairSnapshotPrice;
    address public snapshotCreateCaller;

    event TokenInfo(address token, string name, string symbol, uint256 decimals);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor() {
    }

    function setSnapshotCreateCaller(address _snapshotCreateCaller) external onlyOwner {
        snapshotCreateCaller = _snapshotCreateCaller;
    }

    function setDefaultTransferFee(uint _defaultTransferFee) external onlyOwner {
        defaultTransferFee = _defaultTransferFee;
    }

    function setTokenTransferFee(address token, uint256 fee) external onlyOwner {
        tokenTransferFee[token] = fee; 
    }

    function setRelateTransferFee(address token, uint256 fee) external onlyOwner {
        relateTransferFee[token] = fee;
    }

    function getTransferFee(address[] memory tokens) external view returns (uint[] memory) {
        uint[] memory fees = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length - 1; i ++) {
            if (tokenTransferFee[tokens[i]] != 0) {
                fees[i] = tokenTransferFee[tokens[i]];
            } else if (relateTransferFee[tokens[i+1]] != 0) {
                fees[i] = relateTransferFee[tokens[i+1]];
            } else {
                fees[i] = defaultTransferFee;
            }
        }
        return fees;
    }

    function expectPairFor(address token0, address token1) external view returns (address) {
        return KeplerLibrary.pairFor(address(this), token0, token1);
    }

    function isWhiteList(address token0, address token1) external view returns (bool) {
        address pair = KeplerLibrary.pairFor(address(this), token0, token1);
        return isWhiteList(pair);
    }

    function isWhiteList(address pair) internal view returns(bool) {
        if (whiteListAvaliable) {
            return whiteList[pair];
        } else {
            return true;
        }
    }

    function createPair(address tokenA, address tokenB) public returns (address pair) {
        require(tokenA != tokenB, 'Kepler: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Kepler: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Kepler: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(KeplerPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(isWhiteList(pair), "Kepler: NOT WHITELIST");
        IKeplerPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairsLength = allPairsLength + 1;
        emit TokenInfo(token0, ERC20(token0).name(), ERC20(token0).symbol(), ERC20(token0).decimals());
        emit TokenInfo(token1, ERC20(token1).name(), ERC20(token1).symbol(), ERC20(token1).decimals());
        emit PairCreated(token0, token1, pair, allPairsLength);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function createSnapshot(address pair, uint256 id) external {
        require(msg.sender == snapshotCreateCaller, "only snapshotCreateCaller can do this");
        currentSnapshotId = id; 
        address token0 = IKeplerPair(pair).token0();
        address token1 = IKeplerPair(pair).token1();
        (uint112 reserve0, uint112 reserve1,) = IKeplerPair(pair).getReserves();
        if (reserve0 != 0) {
            pairSnapshotPrice[pair][token0] = IERC20(token0).balanceOf(pair).mul(1e18).div(reserve0);
        }
        if (reserve1 != 0) {
            pairSnapshotPrice[pair][token1] = IERC20(token1).balanceOf(pair).mul(1e18).div(reserve1);
        }
    }

    function getSnapshotPrice(IKeplerPair pair) public view returns(uint price0, uint price1) {
        address token0 = pair.token0();
        address token1 = pair.token1();
        if (currentSnapshotId == 0) {
            (uint reserve0, uint reserve1,) = pair.getReserves();
            if (reserve0 != 0) {
                price0 = IERC20(token0).balanceOf(address(pair)).mul(1e18).div(reserve0);
            }
            if (reserve1 != 0) {
                price1 = IERC20(token1).balanceOf(address(pair)).mul(1e18).div(reserve1);
            }
        } else {
            price0 = pairSnapshotPrice[address(pair)][token0];
            price1 = pairSnapshotPrice[address(pair)][token1];
        }
    }

    function getSnapshotBalance(IKeplerPair pair, address user) public view returns (uint) {
        if (currentSnapshotId == 0 || userSnapshotId[address(pair)][user] != currentSnapshotId) {
            return pair.balanceOf(user);
        } else if (userSnapshotId[address(pair)][user] == currentSnapshotId) {
            return userSnapshotAmount[address(pair)][user];
        } else {
            return 0;
        }
    }

    function getUserSnapshot(address pair, address user) external view returns (uint256, uint256) {
        uint balance = getSnapshotBalance(IKeplerPair(pair), user);
        (uint price0, uint price1) = getSnapshotPrice(IKeplerPair(pair));
        return (balance.mul(price0).div(1e18), balance.mul(price1).div(1e18));
    }

    function _beforeTokenTransfer(address token0, address token1, address from, address to, uint256 amount) external {
        if (false) {
            amount;
        }
        address pair = getPair[token0][token1];
        if (pair == address(0)) {
            return;
        }
        require(msg.sender == pair, "only pair can do this");
        if (currentSnapshotId == 0) {
            return;
        }
        if (userSnapshotId[pair][from] < currentSnapshotId) {
            userSnapshotAmount[pair][from] = IKeplerPair(pair).balanceOf(from);
            userSnapshotId[pair][from] = currentSnapshotId;
        }
        if (userSnapshotId[pair][to] < currentSnapshotId) {
            userSnapshotAmount[pair][to] = IKeplerPair(pair).balanceOf(to);
            userSnapshotId[pair][to] = currentSnapshotId;
        }
    }
}
