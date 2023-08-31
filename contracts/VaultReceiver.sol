// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";


import "./VaultBase.sol";

abstract contract VaultReciever is VaultBase, IERC721Receiver, IERC1155Receiver {

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /**
     * @dev Emitted when ERC721 token is received (must be included for receiving ERC721 tokens)
     *
     * Requirements:
     * from: Wallet that sent the NFT
     * tokenId: ERC721 tokenid
     * memory:
     *
     * If the ERC721 contract is whitelisted and keys are sent to from:
     * Token ID and contract address of ERC721 token are saved for receiveToken and backDoor
     */


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        require(isInWhiteList(from), "ERROR: NFT owner has to be whitelisted to be able to add NFTs");

        if (keyContract.transfer(from, KEYS_AMOUNT_AS_REWARD * (10**keyContract.decimals()))) {
            nfts.push(NFT(msg.sender, tokenId, 0));
            return this.onERC721Received.selector;
        }
        revert("onERC721Received failed");
    }
    

    /**
     * @dev Emitted when ERC1155 token is received (must be included for receiving ERC1155 tokens)
     *
     * Requirements:
     * from: Wallet that sent the NFT
     * id: ERC1155 token id
     * value: ERC1155 value
     * data:
     *
     * If the ERC1155 contract is whitelisted and keys are sent to from:
     * Token ID and contract address of ERC721 token are saved for receiveToken and backDoor
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        require(isInWhiteList(from), "ERROR: NFT owner has to be whitelisted to be able to add NFTs");

        if (keyContract.transfer(from, value * KEYS_AMOUNT_AS_REWARD * (10**keyContract.decimals()))) {
            _storeERC1155(msg.sender, id, value);
            return this.onERC1155Received.selector;
        }
        revert("onERC1155Received failed");
    }

    /**
     * @dev Emitted when multiple ERC1155 tokens are received (must be included for receiving ERC1155 tokens)
     *
     * Requirements:
     * from: Wallet that sent the NFT
     * ids: ERC1155 token ids
     * values: ERC1155 values
     * memory:
     *
     * If the ERC1155 contract is whitelisted and keys are sent to from:
     * Token ID and contract address of ERC721 token are saved for receiveToken and backDoor
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        require(whiteList[from], "Address not whitelisted");

        uint256 totalValue = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            totalValue = totalValue + values[i];
        }

        keyContract.transfer(from, totalValue * KEYS_AMOUNT_AS_REWARD * (10**keyContract.decimals()));
        for (uint256 i = 0; i < ids.length; i++) {
            _storeERC1155(msg.sender, ids[i], values[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    function _storeERC1155(
        address contract_adress,
        uint256 id,
        uint256 value
    ) internal {
        try this.findIndexOfNFT(msg.sender, id) returns (uint256 index) {
            NFT memory nft = nfts[index];
            nft.value = nft.value + value;
            nfts[index] = nft;
        } 
        catch (bytes memory) {
            nfts.push(NFT(msg.sender, id, value));
        }
    }
}
