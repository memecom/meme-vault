// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract TestERC721 is ERC721URIStorage, Ownable {
    constructor() ERC721("Test ERC721", "TE721") {}
    
    function mint(address to, uint256 tokenId, string memory uri) public onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

}

