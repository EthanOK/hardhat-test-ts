// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArbiTricrypto {
    function exchange(uint i, uint j, uint amt, uint) external returns (uint);
}
