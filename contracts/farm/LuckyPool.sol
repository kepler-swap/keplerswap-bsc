// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/IKeplerPair.sol';
import '../interfaces/IRandom.sol';
import '../interfaces/IUser.sol';

contract LuckyPool is Ownable {
    using SafeMath for uint256;
    using Address for address;
	
    uint256 constant public WINER_NUM = 10;
    uint256 constant public BEST_WINER_NUM = 1;
    uint256 constant public TOTAL_WINER_NUM = WINER_NUM + BEST_WINER_NUM;
    //uint256 constant public OPEN_WAIT = 3600;
    uint256 constant public OPEN_WAIT = 60;
    uint256 constant public CLAIM_WAIT = 3 days;
    //uint256 constant public CLAIM_WAIT = 3600;
		
    event LuckyPoolBegin(uint256 luckyId, uint256 timestamp);
    event LuckyPoolOpen(uint256 luckyId, uint256 countAt, uint256 openAt, uint256 finishAt);
    event LuckyPoolRewardInfo(uint256 luckyId, IKeplerPair pair, uint256 userNum, uint256 reward0, uint256 reward1);
    event LuckyPoolClaim(uint256 luckyId, address user, IKeplerPair pair, bool lucky, bool best, uint256 reward0, uint256 reward1);

    mapping(IKeplerPair => mapping(address => uint256)) public receiveAmounts;

    function doHardWork(IKeplerPair _pair, address _token, uint256 _amount) external {
        SafeERC20.safeTransferFrom(IERC20(_token), msg.sender, address(this), _amount);
        receiveAmounts[_pair][_token] += _amount;
    }

    struct LuckyInfo {
        uint256 beginAt;
        uint256 countAt;
        uint256 openAt;
        uint256 finishAt;
        uint256 luckyPairsNum;
    }
    LuckyInfo[] public luckyInfos;
    mapping(uint256 => mapping(IKeplerPair => bool)) public luckyPairs;

    function beginLuckyPool() public onlyOwner {
        if (luckyInfos.length > 0) {
            LuckyInfo storage luckyInfo = luckyInfos[luckyInfos.length - 1];
            if (luckyInfo.countAt == 0) {
                return;
            }
        }
        luckyInfos.push(LuckyInfo({
            beginAt: block.timestamp,
            countAt: 0,
            openAt: 0,
            finishAt: 0,
            luckyPairsNum: 0
        }));
        emit LuckyPoolBegin(luckyInfos.length - 1, block.timestamp);
    }

    struct RewardInfo {
        uint256 avaliableUserNum;
        uint256 openUserNum;
        address bestUser;
        uint256 luckyUserNum;
        uint256 reward0;
        uint256 reward1;
    }
    mapping(uint256 => mapping(IKeplerPair => RewardInfo)) public rewardInfos;
    mapping(uint256 => mapping(IKeplerPair => mapping(address => bool))) public avaliableUsers;
    mapping(uint256 => mapping(IKeplerPair => mapping(address => bool))) public openUsers;
    mapping(uint256 => mapping(IKeplerPair => mapping(address => uint256))) public luckyUsers0;
    mapping(uint256 => mapping(IKeplerPair => mapping(address => uint256))) public luckyUsers1;

    function openLuckyPool(address[] calldata users, IKeplerPair[] calldata pairs, uint256[] calldata perPairNum) external onlyOwner {
        LuckyInfo memory luckyInfo; 
        uint256 luckyInfoIndex = uint256(-1);
        if (luckyInfos.length > 0) {
            luckyInfo = luckyInfos[luckyInfos.length -1];
            if (luckyInfos.length > 1 && luckyInfo.countAt == 0) {
                luckyInfo = luckyInfos[luckyInfos.length - 2];
                luckyInfoIndex = luckyInfos.length - 2;
            } else {
                luckyInfoIndex = luckyInfos.length - 1;
            }
            if (luckyInfo.finishAt <= block.timestamp) {
                luckyInfo = luckyInfos[luckyInfos.length - 1];
                luckyInfoIndex = luckyInfos.length - 1;
            }
            require(luckyInfo.openAt == 0 || luckyInfo.openAt >= block.timestamp, "lucky pool already open");
        }
        require(luckyInfoIndex != uint256(-1), "lucky pool not begin");
        require(pairs.length == perPairNum.length, "illegal pair num");
        uint userIndex = 0;
        for(uint i = 0; i < pairs.length; i ++) {
            uint avaliableUserNum = 0;
            for (uint j = 0; j < perPairNum[i]; j ++) {
                require(users.length > userIndex, "illegal user length");
                address user = users[userIndex];
                userIndex ++;
                if (!avaliableUsers[luckyInfoIndex][pairs[i]][user]) {
                    avaliableUsers[luckyInfoIndex][pairs[i]][user] = true;
                    avaliableUserNum ++;
                }
            }
            if (avaliableUserNum > 0) {
                rewardInfos[luckyInfoIndex][pairs[i]].avaliableUserNum = rewardInfos[luckyInfoIndex][pairs[i]].avaliableUserNum + avaliableUserNum; 
                rewardInfos[luckyInfoIndex][pairs[i]].reward0 = receiveAmounts[pairs[i]][pairs[i].token0()];
                rewardInfos[luckyInfoIndex][pairs[i]].reward1 = receiveAmounts[pairs[i]][pairs[i].token1()];
                emit LuckyPoolRewardInfo(luckyInfoIndex, pairs[i], rewardInfos[luckyInfoIndex][pairs[i]].avaliableUserNum, rewardInfos[luckyInfoIndex][pairs[i]].reward0, rewardInfos[luckyInfoIndex][pairs[i]].reward1);
            }
            if (!luckyPairs[luckyInfoIndex][pairs[i]]) {
                luckyPairs[luckyInfoIndex][pairs[i]] = true;
                luckyInfos[luckyInfoIndex].luckyPairsNum ++;
            }
        }
        if (luckyInfo.countAt == 0) {
            luckyInfos[luckyInfoIndex].countAt = block.timestamp;
            luckyInfos[luckyInfoIndex].openAt = block.timestamp + OPEN_WAIT; //1 hour later
            luckyInfos[luckyInfoIndex].finishAt = block.timestamp + CLAIM_WAIT; //72 hour later
            emit LuckyPoolOpen(luckyInfoIndex, luckyInfos[luckyInfoIndex].countAt, luckyInfos[luckyInfoIndex].openAt, luckyInfos[luckyInfoIndex].finishAt);
            beginLuckyPool();
        }
    }

    function rewardPoolId() public view returns (uint256) {
        uint256 luckyInfoIndex = uint256(-1);
        if (luckyInfos.length > 0) {
            LuckyInfo storage luckyInfo = luckyInfos[luckyInfos.length - 1];
            if (luckyInfos.length > 1 && luckyInfo.countAt == 0) {
                luckyInfo = luckyInfos[luckyInfos.length - 2];
                luckyInfoIndex = luckyInfos.length - 2;
            } else {
                luckyInfoIndex = luckyInfos.length - 1;
            }
            if (luckyInfo.openAt != 0 && luckyInfo.openAt <= block.timestamp && luckyInfo.finishAt >= block.timestamp) {
                return luckyInfoIndex;
            }
        }
        return uint256(-1);
    }

    function currentPoolId() public view returns (uint256) {
        return luckyInfos.length - 1;
    }

    IRandom public random;

    constructor(IRandom _random) {
        random = _random;
        beginLuckyPool();
    }

    function setRandom(IRandom _random) external onlyOwner {
        random = _random;
    }

    function tokenSafeTransfer(IERC20 token,address toAddr,uint256 amount) private{
	SafeERC20.safeTransfer(token, toAddr, amount <token.balanceOf(address(this))? amount :token.balanceOf(address(this)));
    }
    
    function claim(IKeplerPair pair, string memory r) external {
        require(!address(msg.sender).isContract(), "contract can not claim");
        uint256 currentRewardPoolId = rewardPoolId();
        LuckyInfo storage luckyInfo = luckyInfos[currentRewardPoolId];
        RewardInfo storage rewardInfo = rewardInfos[currentRewardPoolId][pair];
        require(block.timestamp >= luckyInfo.openAt && block.timestamp <= luckyInfo.finishAt, "not the right time");
        require(avaliableUsers[currentRewardPoolId][pair][msg.sender], "do not have the right");
        require(!openUsers[currentRewardPoolId][pair][msg.sender], "already opened");
        bool luckyOne = false;
        if (rewardInfo.avaliableUserNum - rewardInfo.openUserNum <= TOTAL_WINER_NUM - rewardInfo.luckyUserNum) {
            luckyOne = true;
        } else if (rewardInfo.luckyUserNum >= TOTAL_WINER_NUM) {
            luckyOne = false;
        } else {
            uint num = random.win(r, 5);
            luckyOne = num == 1;
        }
        openUsers[currentRewardPoolId][pair][msg.sender] = true;
        rewardInfo.openUserNum ++;
        if (!luckyOne) {
            emit LuckyPoolClaim(currentRewardPoolId, msg.sender, pair, luckyOne, false, 0, 0);
            return;
        }
        rewardInfo.luckyUserNum ++;
        bool isBestUser = false;
        if (rewardInfo.bestUser == address(0) && rewardInfo.luckyUserNum > 2) {
            isBestUser = true;
        }
        uint reward0 = 0;
        uint reward1 = 0;
        if (isBestUser) {
            reward0 = rewardInfo.reward0.div(2);
            reward1 = rewardInfo.reward1.div(2);
            rewardInfo.bestUser = msg.sender;
        } else {
            reward0 = rewardInfo.reward0.div(2).div(WINER_NUM);
            reward1 = rewardInfo.reward1.div(2).div(WINER_NUM);
        }
        luckyUsers0[currentRewardPoolId][pair][msg.sender] = reward0;
        luckyUsers1[currentRewardPoolId][pair][msg.sender] = reward1;
        if (reward0 > 0) {
            //SafeERC20.safeTransfer(IERC20(pair.token0()), msg.sender, reward0);
            tokenSafeTransfer(IERC20(pair.token0()), msg.sender, reward0);
            receiveAmounts[pair][pair.token0()] -= reward0;
        }
        if (reward1 > 0) {
            //SafeERC20.safeTransfer(IERC20(pair.token1()), msg.sender, reward1);
            tokenSafeTransfer(IERC20(pair.token1()), msg.sender, reward1);
            receiveAmounts[pair][pair.token1()] -= reward1;
        }
        emit LuckyPoolClaim(currentRewardPoolId, msg.sender, pair, luckyOne, isBestUser, reward0, reward1);
    }
    
}
