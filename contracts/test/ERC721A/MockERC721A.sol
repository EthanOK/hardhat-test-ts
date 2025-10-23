// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@erc721a/ERC721A.sol";

contract MockERC721A is ERC721A {
    constructor() ERC721A("MockERC721A", "MOCK-NFT") {}

    function mint(address to, uint256 quantity) external payable {
        _mint(to, quantity);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
