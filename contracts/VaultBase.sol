// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./ParamCheckBase.sol";
import "./Key.sol";

abstract contract VaultBase is Context, Ownable, ParamCheckBase {
   
    // custom data type for holding contract address and token id
    struct NFT {
        address contractAddress;
        uint256 tokenId;
        uint256 value; //ERC1155 value
    }

    // ERC20 token that'll be used for transactions
    Key keyContract;

    // Amount that is sent when a NFT is received
    uint256 public KEYS_AMOUNT_AS_REWARD = 1;

    //Minimum number of KEYS contract needs to receive to pick a random NFT
    uint256 public KEYS_AMOUNT_TO_UNLOCK_NFT = 1;

    // List of ERC721 address and tokenid that are currently in the smart contract
    NFT[] nfts;

    // addresses to be able to send NFTs to vault
    mapping(address => bool) public whiteList;

    string internal constant ERROR_KEYS_AMOUNT_AS_REWARD_CAN_NOT_BE_ZERO = 'ERROR_KEYS_AMOUNT_AS_REWARD_CAN_NOT_BE_ZERO';
    string internal constant ERROR_KEYS_AMOUNT_TO_UNLOCK_NFT_CAN_NOT_BE_ZERO = 'ERROR_KEYS_AMOUNT_TO_UNLOCK_NFT_CAN_NOT_BE_ZERO';

    /**
    * @dev Event emited when Amount of keys to be received after sending NFT to contract has changed
    * @param newAmount new amount of initial supply
    * @param oldAmount old amount of initial supply
    */
    event KeysAmountAsRewardChanged(uint256 newAmount, uint256 oldAmount);

    /**
    * @dev Event emited when Amount of keys to unlock NFT from vault has changed
    * @param newAmount new amount of initial supply
    * @param oldAmount old amount of initial supply
    */
    event KeysAmountToUnlockNFTChanged(uint256 newAmount, uint256 oldAmount);

    /**
    * @dev Event emited when key contract is changed
    * @param newKeyContract new amount of initial supply
    * @param oldKeyContract old amount of initial supply
    */
    event KeyContractChanged(address newKeyContract, address oldKeyContract);

    /**
    * @dev Sets weight of reserve currency compared to mToken coins
    * @param _amount hit some heavy numbers !! :)
    */
    function setKeysAmountAsReward(uint256 _amount)
    public
    onlyOwner
    aboveZero(_amount, ERROR_KEYS_AMOUNT_AS_REWARD_CAN_NOT_BE_ZERO)
    {
        uint256 oldKeysAmount = KEYS_AMOUNT_AS_REWARD;

        KEYS_AMOUNT_AS_REWARD = _amount;

        emit KeysAmountAsRewardChanged(KEYS_AMOUNT_AS_REWARD, oldKeysAmount);
    }

    /**
    * @dev Sets weight of reserve currency compared to mToken coins
    * @param _amount hit some heavy numbers !! :)
    */
    function setKeysAmountToUnlockNFT(uint256 _amount)
    public
    onlyOwner
    aboveZero(_amount, ERROR_KEYS_AMOUNT_TO_UNLOCK_NFT_CAN_NOT_BE_ZERO)
    {
        uint256 oldKeysAmount = KEYS_AMOUNT_TO_UNLOCK_NFT;

        KEYS_AMOUNT_TO_UNLOCK_NFT = _amount;

        emit KeysAmountToUnlockNFTChanged(KEYS_AMOUNT_AS_REWARD, oldKeysAmount);
    }

    /**
    * @dev Sets key contract
    * @param _keyContract new key contract !! :)
    */
    function setKeyContract(Key _keyContract)
    public
    onlyOwner
    {
        address oldContract = address(keyContract);

        keyContract = _keyContract;

        emit KeyContractChanged(address(keyContract), oldContract);
    }

    /**
     * @dev Whitelists the wallets that are allowed to send ERC721/ERC1155 tokens to this contract
     *
     * Requirements:
     * @param addressAbleToSendNFTsToVault: Wallet address that you want to whitelist
     * @param isWhiteListed: Whitelist/Blacklist contract based on value
     */
    function setWhiteList(address addressAbleToSendNFTsToVault, bool isWhiteListed) 
    public 
    onlyOwner
    {
        whiteList[addressAbleToSendNFTsToVault] = isWhiteListed;
    }

    /**
     * @dev check if address can send NFTs to vault and receive Keys as reward
     *
     * Requirements:
     * @param addressAbleToSendNFTsToVault: Wallet address that you want to whitelist
     */
    function isInWhiteList(address addressAbleToSendNFTsToVault) 
    public view returns (bool isWhiteListed)
    {
        return whiteList[addressAbleToSendNFTsToVault];
    }

    /**
     * @dev check if address can send NFTs to vault and receive Keys as reward
     *
     */
    function getKeyContract() 
    public view returns (address currentKeyContract)
    {
        return address(keyContract);
    }

    /**
     * @dev returns list of NFTs hidden in the vault 
     *
     */
    function getNFTs() public view returns (NFT[] memory) {
        NFT[] memory arr = new NFT[](nfts.length);
        for (uint256 i = 0; i < nfts.length; i++) {
            NFT storage nft = nfts[i];
            arr[i] = nft;
        }
        return arr;
    }


    /**
     * @dev Get token type whether it is ERC721 or ERC1155
     */
    function getNFTsCount()
        public
        view
        returns (uint256 nftsCount)
    {
        return nfts.length;
    }

    /**
    * @dev try to find index of NFT if not in the list error is thrown.
    */
    error NFTIndexNotFound();
    function findIndexOfNFT(address contractAddress, uint256 tokenId) 
    public view returns (uint256 index) 
    {
        for (uint256 i = 0; i < nfts.length; i++) {
            NFT memory nft = nfts[i];
            if (nft.contractAddress == contractAddress && nft.tokenId == tokenId) {
                return i;
            }
        }

        revert NFTIndexNotFound();
    }

    /**
     * @dev Get token type whether it is ERC721 or ERC1155
     */
    function getNFTType(address addr)
        public
        view
        returns (string memory tokenType)
    {
        if (IERC721(addr).supportsInterface(0x80ac58cd)) return "ERC721";
        if (IERC1155(addr).supportsInterface(0xd9b67a26)) return "ERC1155";
        return "unknown";
    }
}
