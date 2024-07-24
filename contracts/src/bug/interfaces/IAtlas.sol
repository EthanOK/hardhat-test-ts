// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAtlas {
    struct SwapData {
        address[] routers;
        uint256[] routerType;
        uint256[] pairBinId;
        address[] tokensIn;
        address[] tokensOut;
        int128[] curvei;
        int128[] curvej;
        uint256 amt;
    }

    // tuple(address[],uint256[],uint256[],address[],address[],uint256[],uint256[],uint256)
}
