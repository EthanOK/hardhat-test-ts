// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMummyVault {
    function swap(
        address tokenIn,
        address tokenOut,
        address
    ) external returns (uint256);
}
