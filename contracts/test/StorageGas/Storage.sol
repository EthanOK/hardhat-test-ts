// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Storage {
    mapping(address => uint) balance;

    function deposit(address to, uint256 amount) public payable {
        balance[to] = amount;
    }
}
