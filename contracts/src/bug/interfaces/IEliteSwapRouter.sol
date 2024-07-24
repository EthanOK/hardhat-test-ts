// SPDX-License-Identifier: ISC
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEliteSwapRouter {
    enum Version {
        V1,
        V2,
        V2_1
    }

    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOut,
        Path memory path,
        address to,
        uint deadline
    ) external returns (uint);

    function getSwapOut(
        address pool,
        uint128 amountIn,
        bool swapForY
    ) external view returns (uint256, uint256, uint256);
}
