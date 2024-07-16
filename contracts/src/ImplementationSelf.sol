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
        // TODO:从 EVM >= Cancun 开始， selfdestruct 只会将帐户中的所有以太币发送给给定的接收者，而不会销毁合约。
        selfdestruct(payable(_msgSender()));
    }

    function withdraw() public payable {
        (bool success, ) = implementAddress.delegatecall(
            abi.encodeWithSignature("withdraw()")
        );
        require(success, "withdraw failed");
    }
}
