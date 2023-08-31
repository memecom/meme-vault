// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol";
import "testContracts/TestERC721.sol";
import "testContracts/TestERC1155.sol";
import "testContracts/ReceiverWrapper.sol";

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
// <import file to test>


import "contracts/Vault.sol";
import "contracts/Key.sol";


contract testVaultBackdoor {

    Vault public vaultContract;
    Key public keyContract;
    TestERC721 public ERC721Contract;
    TestERC1155 public  ERC1155Contract;

    uint256 ERC721TokenId = 1;
    uint256 ERC1155TokenId = 1;
    uint256 ERC1155Value = 2;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeEach() public {
        vaultContract = new Vault();
        keyContract = new Key();

        address owner = address(this);

        keyContract.mint(address(vaultContract), 10 * 10**keyContract.decimals());

        ERC721Contract = new TestERC721();
        ERC1155Contract = new TestERC1155();
        ReceiverWrapper receiver = new ReceiverWrapper();

        vaultContract.setKeyContract(keyContract);
        vaultContract.setWhiteList(owner, true);
        vaultContract.setWhiteList(address(ERC721Contract), true);
        vaultContract.setWhiteList(address(receiver), true);

        ERC721Contract.mint(owner, ERC721TokenId, "");
        ERC1155Contract.mint(address(receiver), ERC1155TokenId, ERC1155Value, "");

        ERC721Contract.safeTransferFrom(owner, address(vaultContract), ERC721TokenId);
        receiver.safeTransferERC1155(
            address(ERC1155Contract),
            address(vaultContract),
            ERC1155TokenId,
            ERC1155Value
        );
    }

    function checkBackdoorNFT() public {
        Vault.NFT memory nft = vaultContract.getNFTs()[1];

        ReceiverWrapper receiver = new ReceiverWrapper();

        vaultContract.transferOwnership(address(receiver));

        receiver.backdoorNFT(vaultContract, 0);
        receiver.backdoorNFT(vaultContract, 0);

        Assert.equal(ERC721Contract.ownerOf(ERC721TokenId), address(receiver), "Receiver should own the ERC721 token");
        Assert.equal(ERC1155Contract.balanceOf(address(receiver), 1), ERC1155Value, "Receiver should own 2 of the ERC1155 tokens");
    }

    function checkBackdoorERC721() public {
        ReceiverWrapper receiver = new ReceiverWrapper();

        vaultContract.transferOwnership(address(receiver));

        receiver.backdoorERC721(vaultContract, address(ERC721Contract), ERC721TokenId);

        Vault.NFT[] memory nfts = vaultContract.getNFTs();

        Assert.equal(ERC721Contract.ownerOf(ERC721TokenId), address(receiver), "Receiver should own the ERC721 token");
        Assert.equal(ERC1155Contract.balanceOf(address(receiver), ERC1155TokenId), 0, "Receiver should not own ERC1155 tokens");
        Assert.equal(ERC1155Contract.balanceOf(address(vaultContract), ERC1155TokenId), ERC1155Value, "Vault should own 2 of the ERC1155 tokens");
        Assert.equal(nfts.length, 1, "Should store one nft");
        Assert.equal(nfts[0].contractAddress, address(ERC1155Contract), "Should store ERC1155");
        Assert.equal(nfts[0].value, ERC1155Value, "Should store 2 ERC1155");
    }

    function checkBackdoorERC721LostNFT() public {
        ReceiverWrapper receiver = new ReceiverWrapper();

        vaultContract.transferOwnership(address(receiver));

        TestERC721 lostERC721Contract = new TestERC721();
        lostERC721Contract.mint(address(vaultContract), ERC721TokenId, "");

        receiver.backdoorERC721(vaultContract, address(lostERC721Contract), ERC721TokenId);

        Vault.NFT[] memory nfts = vaultContract.getNFTs();
        Assert.equal(lostERC721Contract.ownerOf(ERC721TokenId), address(receiver), "Receiver should own the lost erc 721 token");
        Assert.equal(ERC721Contract.ownerOf(ERC721TokenId), address(vaultContract), "Vault should own the ERC721 token");
        Assert.equal(ERC1155Contract.balanceOf(address(vaultContract), ERC1155TokenId), ERC1155Value, "Vault should own 2 of the ERC1155 tokens");
        Assert.equal(nfts.length, 2, "Should store two nfts");
        Assert.equal(nfts[0].contractAddress, address(ERC721Contract), "Should store ERC721");
        Assert.equal(nfts[1].contractAddress, address(ERC1155Contract), "Should store ERC1155");
        Assert.equal(nfts[1].value, ERC1155Value, "Should store 2 ERC1155");
    }


    function checkBackdoorERC1155FullWithdraw() public {
        ReceiverWrapper receiver = new ReceiverWrapper();

        vaultContract.transferOwnership(address(receiver));

        receiver.backdoorERC1155(vaultContract, address(ERC1155Contract), ERC1155TokenId, ERC1155Value);

        Vault.NFT[] memory nfts = vaultContract.getNFTs();

        Assert.equal(ERC721Contract.ownerOf(ERC721TokenId), address(vaultContract), "Vault should own the ERC721 token");
        Assert.equal(ERC1155Contract.balanceOf(address(receiver), ERC1155TokenId), ERC1155Value, "Receiver own 2 of the ERC1155 tokens");
        Assert.equal(ERC1155Contract.balanceOf(address(vaultContract), ERC1155TokenId), 0, "Vault should not own ERC1155 tokens");
        Assert.equal(nfts.length, 1, "Should store one nft");
        Assert.equal(nfts[0].contractAddress, address(ERC721Contract), "Should store ERC721");
    }

    function checkBackdoorERC1155PartialWithdraw() public {
        ReceiverWrapper receiver = new ReceiverWrapper();

        vaultContract.transferOwnership(address(receiver));

        receiver.backdoorERC1155(vaultContract, address(ERC1155Contract), ERC1155TokenId, 1);

        Vault.NFT[] memory nfts = vaultContract.getNFTs();

        Assert.equal(ERC721Contract.ownerOf(ERC721TokenId), address(vaultContract), "Vault should own the ERC721 token");
        Assert.equal(ERC1155Contract.balanceOf(address(receiver), ERC1155TokenId), ERC1155Value - 1, "Receiver own 1 of the ERC1155 tokens");
        Assert.equal(ERC1155Contract.balanceOf(address(vaultContract), ERC1155TokenId), 1, "Vault should own 1 of the ERC1155 tokens");
        Assert.equal(nfts.length, 2, "Should store two nfts");
        Assert.equal(nfts[0].contractAddress, address(ERC721Contract), "Should store ERC721");
        Assert.equal(nfts[1].contractAddress, address(ERC1155Contract), "Should store ERC721");
        Assert.equal(nfts[1].value, 1, "Should store 1 ERC1155");
    }

}
