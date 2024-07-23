// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Script is Script {
    ERC20 public token;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        token = new ERC20("Test Token", "TTT");
    }
}

// forge script ERC20Script --rpc-url sepolia
// forge script --broadcast ERC20Script --rpc-url sepolia
