// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurvePool {
    function exchange(
        int128 i,
        int128 j,
        uint amt,
        uint
    ) external returns (uint);

    function exchange(uint i, uint j, uint amt, uint) external returns (uint);
}
