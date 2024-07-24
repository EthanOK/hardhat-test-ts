// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEqualizerRouter {
    function swapExactTokensForTokensSimple(
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        bool stable,
        address,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountOut(
        uint256 amount,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256, uint256);
}
