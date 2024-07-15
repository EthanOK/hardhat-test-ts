// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ValidId {
    function isValidId(address account, uint256 id) public pure returns (bool) {
        return account == address(bytes20(bytes32(id)));
    }

    function caculateId(
        address account,
        uint96 nonce
    ) external pure returns (uint256) {
        return uint256(bytes32(abi.encodePacked(account, nonce)));
    }

    function parseId(uint256 id) public pure returns (address, uint96) {
        return (address(bytes20(bytes32(id))), uint96(id));
    }
}
