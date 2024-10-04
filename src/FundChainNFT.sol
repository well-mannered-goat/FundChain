// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract FundChainNFT is ERC721, Ownable {
    uint256 tokenId;
    address private immutable admin;
    error Balance_Already_Positive();

    constructor() ERC721("FundChain", "FC") Ownable(admin) {
        tokenId = 0;
    }

    function mint(address to) external onlyOwner {
        if (balanceOf(to) > 0) revert Balance_Already_Positive();

        _safeMint(to, tokenId);
        tokenId++;
    }
}
