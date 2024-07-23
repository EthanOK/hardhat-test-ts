// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ValidId} from "../src/ValidId.sol";

contract ValidIdTest is Test {
    ValidId public validId;
    uint256 constant private_key = 666666;
    address account = vm.addr(private_key);

    function setUp() public {
        validId = new ValidId();
    }

    function testCaculateId() public view {
        uint256 id = validId.caculateId(account, 435345436);

        console.log("id: ", id);
        bool result = validId.isValidId(account, id);
        assertEq(true, result);
    }
}
