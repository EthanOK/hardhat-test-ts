// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ImplementationSelf is UUPSUpgradeable, OwnableUpgradeable {
    address implementAddress;
    constructor() {
        // _disableInitializers();
    }
    function initialize(address _imp, address _owner) public initializer {
        implementAddress = _imp;
        _transferOwnership(_owner);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {
        _authorizeUpgrade(newImplementation);
    }

    function selfDestruct() public onlyOwner {
        selfdestruct(payable(_msgSender()));
    }

    function withdraw() public payable {
        (bool success, ) = implementAddress.delegatecall(
            abi.encodeWithSignature("withdraw()")
        );
        require(success, "withdraw failed");
    }
}
