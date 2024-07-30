// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// https://etherscan.io/tx/0xd82fe84e63b1aa52e1ce540582ee0895ba4a71ec5e7a632a3faa1aff3e763873
library LibSwap {
    struct SwapData {
        address callTo;
        address approveTo;
        address sendingAssetId;
        address receivingAssetId;
        uint256 fromAmount;
        bytes callData;
        bool requiresDeposit;
    }
}

interface IGasZipFacet {
    function depositToGasZipERC20(
        LibSwap.SwapData calldata _swapData,
        uint256 _destinationChains,
        address _recipient
    ) external;
}
