// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "hardhat/console.sol";

contract KeplerToken is ERC20, Ownable {
    
    uint256 public currentSnapshotId;
    mapping(address => uint256) userSnapshotId;
    mapping(address => uint256) userSnapshotAmount;
    address public snapshotCreateCaller;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        if (decimals_ != 18) {
            _setupDecimals(decimals_);
        }
    }

    function setSnapshotCreateCaller(address _snapshotCreateCaller) external onlyOwner {
        snapshotCreateCaller = _snapshotCreateCaller;
    }

    function mint (address to_, uint amount_) external onlyOwner {
        _mint(to_, amount_);
    }

    function createSnapshot(uint256 id) external {
        require(msg.sender == snapshotCreateCaller, "only snapshotCreateCaller can do this");
        require(id > currentSnapshotId, "illegal snapshotId");
        currentSnapshotId = id; 
    }

    function getUserSnapshot(address user) external view returns (uint256) {
        if (currentSnapshotId == 0) {
            return balanceOf(user);
        } else if (userSnapshotId[user] == currentSnapshotId) {
            return userSnapshotAmount[user];
        } else {
            return balanceOf(user);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (false) {
            amount;
        }
        if (currentSnapshotId == 0) {
            return;
        }
        if (userSnapshotId[from] < currentSnapshotId) {
            userSnapshotAmount[from] = balanceOf(from);
            userSnapshotId[from] = currentSnapshotId;
        }
        if (userSnapshotId[to] < currentSnapshotId) {
            userSnapshotAmount[to] = balanceOf(to);
            userSnapshotId[to] = currentSnapshotId;
        }
    }
}
