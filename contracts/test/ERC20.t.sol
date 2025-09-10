// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Test is Test {
    ERC20 public erc20;

    function setUp() public {
        erc20 = new ERC20("Test", "TEST");
    }

    function testTotalSupply() public view {
        uint256 totalSupply = erc20.totalSupply();
        console.log("totalSupply: ", totalSupply);
    }

    function testName() public view {
        string memory name = erc20.name();
        console.log("name: ", name);
    }

    function testSymbol() public view {
        string memory symbol = erc20.symbol();
        console.log("symbol: ", symbol);
    }

    function testDecimals() public view {
        uint8 decimals = erc20.decimals();
        console.log("decimals: ", decimals);
    }
}
