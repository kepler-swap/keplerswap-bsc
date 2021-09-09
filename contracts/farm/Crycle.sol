// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IKeplerFactory.sol';
import '../interfaces/IKeplerToken.sol';
import '../interfaces/IKeplerPair.sol';
import '../interfaces/IMasterChef.sol';
import '../interfaces/IUser.sol';
import '@openzeppelin/contracts/utils/Address.sol';

contract Crycle is Ownable {
    using SafeMath for uint256;
    using Address for address;

    event NewCrycle(address creator, string title, string mainfest, string telegram, uint256 timestamp);
    event NewTitle(address creator, string oldTitle, string newTitle, uint256 timestamp);
    event NewMainfest(address creator, string oldMainfest, string newMainfest, uint256 timestamp);
    event NewTelegram(address creator, string oldTelegram, string newTelegram, uint256 timestamp);
    event NewUser(address user, address creator, uint256 userNum, uint256 timestamp);
    event NewVoteInfo(uint256 voteId, uint256 beginAt, uint256 countAt, uint256 finishAt, uint256 reward);
    event NewVote(uint256 voteId, address user, address crycle, uint256 num, uint totalSended, uint totalReceived);

    IUser public immutable user;
    IMasterChef public immutable masterChef;
    IKeplerPair[] public pairs;
    IERC20 public immutable busd;
    IKeplerToken public immutable sds;
    IKeplerFactory public immutable factory;
    uint256 public totalDelt;

    uint256 constant public MIN_LOCK_AMOUNT = 500 * 1e18;
    uint256 constant public MIN_INVITER_AMOUNT = 5000 * 1e18;

    struct CrycleInfo {
        address creator;
        string title;
        string mainfest;
        string telegram;
        uint256 userNum;
    }
    mapping(address => CrycleInfo) public crycles;
    mapping(address => address) public userCrycle;
    mapping(uint256 => mapping(address => uint256)) public userVote;
    mapping(uint256 => mapping(address => uint256)) public crycleVote;
    mapping(uint256 => address[]) public voteWiners;
    mapping(uint256 => mapping(address => uint256)) public voteReward;

    function addPair(IKeplerPair pair) external onlyOwner {
        pairs.push(pair);
    }

    function removePair(uint index) external onlyOwner {
        require(index < pairs.length, "illegal index");
        if (index < pairs.length - 1) {
            pairs[index] = pairs[pairs.length - 1];
        }
        pairs.pop();
    }


    constructor(IUser _user, IMasterChef _masterChef, IKeplerPair _pair, IERC20 _busd, IKeplerToken _sds, IKeplerFactory _factory) {
        user = _user;
        masterChef = _masterChef;
        pairs.push(_pair);
        busd = _busd;
        sds = _sds;
        factory = _factory;
    }

    function getPairTokenPrice(IKeplerPair _pair, IERC20 token) internal view returns(uint price) {
        address token0 = _pair.token0();
        address token1 = _pair.token1();
        require(token0 == address(token) || token1 == address(token), "illegal token");
        (uint reserve0, uint reserve1,) = _pair.getReserves();
        if (address(token) == token0) {
            if (reserve0 != 0) {
                return IERC20(token0).balanceOf(address(_pair)).mul(1e18).div(reserve0);
            }
        } else if (address(token) == token1) {
            if (reserve1 != 0) {
                return IERC20(token1).balanceOf(address(_pair)).mul(1e18).div(reserve1);
            }
        }
        return 0;
    }

    function canCreateCrycle(address _user) public view returns (bool) {
        uint totalUser = 0;
        uint totalInviter = 0;
        for (uint i = 0; i < pairs.length; i ++) {
            uint price = getPairTokenPrice(pairs[i], busd);
            uint balanceUser = masterChef.getUserAmount(pairs[i], _user, 3);
            uint balanceInviter = masterChef.getInviterAmount(pairs[i], _user);
            totalUser = totalUser.add(balanceUser.mul(price).div(1e18));
            totalInviter = totalInviter.add(balanceInviter.mul(price).div(1e18));
        }
        if (totalUser >= MIN_LOCK_AMOUNT || totalInviter >= MIN_INVITER_AMOUNT) {
            return true;
        } else {
            return false;
        }
    }

    function createCrycle(string memory title, string memory mainfest, string memory telegram) external {
        require(!address(msg.sender).isContract(), "contract can not create crycle");
        require(bytes(title).length <= 32, "title too long");
        require(bytes(mainfest).length <= 1024, "mainfest too long");
        require(bytes(telegram).length <= 256, "mainfest too long");
        require(canCreateCrycle(msg.sender), "at lease lock 500 BUSD and SDS or invite 5000 BUSD and SDS");
        require(crycles[msg.sender].creator == address(0), "already create crycle");
        require(userCrycle[msg.sender] == address(0), "already in crycle");
        crycles[msg.sender] = CrycleInfo({
            creator: msg.sender,
            title: title,
            mainfest: mainfest,
            telegram: telegram,
            userNum: 0
        });
        userCrycle[msg.sender] = msg.sender;
        crycles[msg.sender].userNum = crycles[msg.sender].userNum + 1;
        emit NewCrycle(msg.sender, title, mainfest, telegram, block.timestamp);
        emit NewUser(msg.sender, msg.sender, crycles[msg.sender].userNum, block.timestamp);
    }

    function setTitle(string memory title) external {
        require(bytes(title).length <= 32, "title too long");
        require(crycles[msg.sender].creator != address(0), "crycle not create");
        string memory oldTitle = crycles[msg.sender].title;
        crycles[msg.sender].title = title;
        emit NewTitle(msg.sender, oldTitle, title, block.timestamp);
    }

    function setMainfest(string memory mainfest) external {
        require(bytes(mainfest).length <= 1024, "mainfest too long");
        require(crycles[msg.sender].creator != address(0), "crycle not create");
        string memory oldMainfest = crycles[msg.sender].mainfest;
        crycles[msg.sender].mainfest = mainfest;
        emit NewMainfest(msg.sender, oldMainfest, mainfest, block.timestamp);
    }

    function setTelegram(string memory telegram) external {
        require(bytes(telegram).length <= 256, "mainfest too long");
        require(crycles[msg.sender].creator != address(0), "crycle not create");
        string memory oldTelegram = crycles[msg.sender].telegram;
        crycles[msg.sender].telegram = telegram;
        emit NewTelegram(msg.sender, oldTelegram, telegram, block.timestamp);
    }

    function addCrycle(address creator) external {
        require(msg.sender != creator, "can not add yourself");
        require(user.userExists(msg.sender), "user not registe");
        require(crycles[creator].creator != address(0), "crycle not exists");
        require(userCrycle[msg.sender] == address(0), "already joined crycle");
        userCrycle[msg.sender] = creator;
        crycles[creator].userNum = crycles[creator].userNum + 1;
        emit NewUser(msg.sender, creator, crycles[creator].userNum, block.timestamp);
    }

    struct VoteInfo {
        uint beginAt;
        uint countAt;
        uint finishAt;
        uint reward;
    }

    function DebugSetBeginAt(uint timestamp) external {
        voteInfo[voteInfo.length - 1].beginAt = timestamp;
    }

    function DebugSetCountAt(uint timestamp) external {
        voteInfo[voteInfo.length - 1].countAt = timestamp;
    }

    function DebugSetFinishAt(uint timestamp) external {
        voteInfo[voteInfo.length - 1].finishAt = timestamp;
    }

    VoteInfo[] public voteInfo;

    function getVoteId() external view returns (uint) {
        return voteInfo.length;
    }

    function startVote(uint256 beginAt, uint256 countAt, uint256 finishAt) external onlyOwner {
        require(beginAt <= countAt && countAt <= finishAt, "illegal time");
        if (voteInfo.length > 0) { //check if last vote finish
            require(block.timestamp > voteInfo[voteInfo.length - 1].finishAt, "last vote not finish");
        }

        uint currentBalance = sds.balanceOf(address(this));
        voteInfo.push(VoteInfo({
            beginAt: beginAt,
            countAt: countAt,
            finishAt: finishAt,
            reward: currentBalance.sub(totalDelt)
        }));
        totalDelt = currentBalance;
        uint _currentVoteId = voteInfo.length;
        masterChef.createSnapshot(_currentVoteId);
        sds.createSnapshot(_currentVoteId);
        for (uint i = 0; i < pairs.length; i ++) {
            factory.createSnapshot(address(pairs[i]), _currentVoteId);
        }
        emit NewVoteInfo(_currentVoteId, beginAt, countAt, finishAt, sds.balanceOf(address(this)));
    }

    function voteNum(address _user) public view returns (uint256) {
        uint totalVotes = sds.getUserSnapshot(_user);
        for (uint i = 0; i < pairs.length; i ++) {
            (uint price0, uint price1) = factory.getSnapshotPrice(pairs[i]);
            uint price = address(sds) == pairs[i].token0() ? price0 : price1;
            uint pairVotes = factory.getSnapshotBalance(pairs[i], msg.sender);
            uint lockVotes = masterChef.getUserSnapshot(pairs[i], msg.sender);
            totalVotes = totalVotes.add(price.mul(pairVotes.div(1e18))).add(price.mul(lockVotes).div(1e18)).div(1e16);
        }
        return totalVotes;
    }

    function doVote(uint num) external {
        uint voteId = voteInfo.length;
        require(voteId > 0, "vote not begin");
        VoteInfo memory _voteInfo = voteInfo[voteInfo.length - 1];
        require(block.timestamp >= _voteInfo.beginAt && block.timestamp < _voteInfo.countAt, "not the right time");
        require(userCrycle[msg.sender] != address(0), "illegal user vote");
        userVote[voteId][msg.sender] = userVote[voteId][msg.sender].add(num);
        crycleVote[voteId][userCrycle[msg.sender]] = crycleVote[voteId][userCrycle[msg.sender]].add(num);
        require(userVote[voteId][msg.sender] <= voteNum(msg.sender), "illegal vote num");
        emit NewVote(voteId, msg.sender, userCrycle[msg.sender], num, userVote[voteId][msg.sender], crycleVote[voteId][userCrycle[msg.sender]]);
    }

    function doCount(address[] memory _crycles) external onlyOwner {
        uint voteId = voteInfo.length;
        if (voteId == 0) {
            return;
        }
        VoteInfo memory _voteInfo = voteInfo[voteId - 1];
        if (block.timestamp < _voteInfo.countAt && block.timestamp >= _voteInfo.finishAt) {
            return;
        }
        voteWiners[voteId] = _crycles;
        if (_crycles.length == 0) {
            return;
        }
        for (uint i = 0; i < _crycles.length; i ++) {
            voteReward[voteId][_crycles[i]] = _voteInfo.reward.div(_crycles.length); 
        }
    }

    function claim(uint _voteId, address _user) external {
        if (voteReward[_voteId][_user] > 0) {
            uint amount = voteReward[_voteId][_user];
            voteReward[_voteId][_user] = 0;
            totalDelt = totalDelt.sub(amount);
            sds.transfer(_user, amount);
        }
    }

}
