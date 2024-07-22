// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {VmSafe} from "forge-std/Vm.sol";

contract HelpUtils {
    // keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    function getImplementationAddress(address _proxy) public view returns (address implementation) {
        bytes32 implementation_data = vm.load(_proxy, _IMPLEMENTATION_SLOT);
        implementation = address(uint160(uint256(implementation_data)));
    }
}
