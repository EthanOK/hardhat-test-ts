// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VmNonceTest is Test {
    address public player = vm.addr(666666);

    function setUp() external {}

    function testNonce() public {
        vm.startPrank(player, player);
        ERC20 token = new ERC20("", "");
        token.transfer(address(2), 0);
        // forge 0.2.0 (0116be1 2024-07-09T00:18:45.429480000Z)
        // Only `new Contract` increases the nonce.
        assertEq(1, vm.getNonce(player));
        vm.stopPrank();
    }

    function testNonce_2() public {
        vm.startPrank(player, player);
        new ERC20("", "");
        new ERC20("", "");
        assertEq(2, vm.getNonce(player));
        vm.stopPrank();
    }
}
