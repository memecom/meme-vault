// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./VaultReceiver.sol";
import "./VaultBackdoor.sol";

contract Vault is VaultReciever, VaultBackdoor {

    event NFTUnlocked(address newOwner, uint256 keysSpent, string nftType, address nftContract, uint256 tokenId, uint256 amount);

    constructor() { }

    /**
     * @dev Send NFT to the wallet (that called) AFTER >=10 keys(ERC20 token) are sent to this function
     *
     * Requirements:
     *
     * Transfer amount from sender to this contract and a random ERC721 from this contract if:
     * 1. Wallet should have > 0 keys, will fail if there are no keys
     * 2. NFTs in the this contract should be > 0, will fail if there are no NFTs
     * 3. Amount that is being sent to the smart should be exactly 10, will failif the amount is not equal to 10
     */
    function unlockNFT() public returns (bool success) {
        require(keyContract.balanceOf(msg.sender) >= KEYS_AMOUNT_TO_UNLOCK_NFT, "ERROR: Not enough keys to receive NFT has been sent!");
        require(nfts.length > 0, "ERROR: There are no NFTs in the contract");

        if (keyContract.transferFrom(msg.sender, address(this), KEYS_AMOUNT_TO_UNLOCK_NFT * (10**keyContract.decimals()))) {
            uint256 randomIndex = uint256(keccak256(abi.encodePacked(
                block.timestamp, 
                blockhash(block.number - 1),
                block.prevrandao,
                msg.sender
                ))) % nfts.length;

            string memory nftType = getNFTType(nfts[randomIndex].contractAddress);

            if (keccak256(bytes(nftType)) == keccak256(bytes("ERC721"))) {
                IERC721(nfts[randomIndex].contractAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    nfts[randomIndex].tokenId
                );
            }

            if (keccak256(bytes(nftType)) == keccak256(bytes("ERC1155"))) {
                NFT memory nft;
                IERC1155(nfts[randomIndex].contractAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
                    nfts[randomIndex].tokenId,
                    1,
                    "0x0"
                );
                nft = nfts[randomIndex];
                nft.value = nft.value - 1;
                nfts[randomIndex] = nft;
            }

            emit NFTUnlocked(msg.sender, KEYS_AMOUNT_TO_UNLOCK_NFT, nftType, nfts[randomIndex].contractAddress, nfts[randomIndex].tokenId, nfts[randomIndex].value);

            if (nfts[randomIndex].value == 0) {
                nfts[randomIndex] = nfts[nfts.length - 1];
                nfts.pop();
            }

            return true;
        }
        return false;
    }
}
