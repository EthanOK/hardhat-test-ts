// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Storage} from "./Storage.sol";

contract StorageTest is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");
    Storage storage_;

    function setUp() public {
        storage_ = new Storage();
        storage_.deposit(bob, 10);
    }

    function test_Deposit() public {
        // storage cost: 20000 （零值 => 非零值） + 2100 （冷存储访问） = 22100
        // 22786 - 22100 = 686 （基础的函数调用、参数解码等操作消耗）
        storage_.deposit(alice, 2);

        // storage cost: 100 (热存访问修改)
        // 100 + 686 = 786
        storage_.deposit(alice, 3);

        // storage cost: 2900 (非零值 => 非零值) + 2100 (冷存储访问) = 5000
        // 5000 + 686 = 5686
        storage_.deposit(bob, 1);
    }
}

// forge test --match-contract StorageTest -vvvvv
