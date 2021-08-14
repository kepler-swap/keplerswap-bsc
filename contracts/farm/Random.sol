// SPDX-License-Identifier: MIT

pragma solidity >=0.7.2;

import '@openzeppelin/contracts/access/Ownable.sol';

contract Random is Ownable {

    bytes32 data;

    function win(string memory r, uint256 maxNum) external returns (uint256) {
        bytes32 data1 = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.coinbase, block.number)); 
        bytes32 data2 = keccak256(abi.encodePacked(msg.data, gasleft(), tx.gasprice));
        uint8 num = uint8(uint256(keccak256(abi.encodePacked(data, data1, data2, r)))%maxNum);
        data = keccak256(abi.encodePacked(data1, data2));
        return num;
    }

}
