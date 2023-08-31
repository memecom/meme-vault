// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "contracts/Vault.sol";
import "./TestERC1155.sol";
import "contracts/Key.sol";

contract ReceiverWrapper {
    
    function backdoorNFT(Vault vault, uint256 index) public  {
        vault.backdoorNFT(index);
    }

    function backdoorERC721(Vault vault, address contractAddress, uint256 tokenId) public {
        vault.backdoorERC721(contractAddress, tokenId);
    }

    function backdoorERC1155(Vault vault, address contractAddress, uint256 tokenId, uint256 value) public {
        vault.backdoorERC1155(contractAddress, tokenId, value);
    }

    function unlockNFT(Vault vault) public{
        vault.unlockNFT();
    }

    function safeTransferERC1155(address ERCContract, address to, uint256 id, uint256 value) public {
        IERC1155(ERCContract).safeTransferFrom(
            address(this),
            to,
            id,
            value,
            ""
        );
    }

    function approveERC20(Key keyContract, address spender, uint256 amount) public {
        keyContract.approve(spender, amount);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public returns (bytes4) {
        return this.onERC1155Received.selector;
    }

}

