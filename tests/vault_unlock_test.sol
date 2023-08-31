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


contract testVaultUnlock {

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

    function checkUnlockNFTFailsOnNotEnoughtKeys() public {
        ReceiverWrapper receiver = new ReceiverWrapper();
        ReceiverWrapper burn = new ReceiverWrapper();

        vaultContract.transferOwnership(address(burn));

        // Remove ERC1155 from prize pool
        burn.backdoorNFT(vaultContract, 1);

        try receiver.unlockNFT(vaultContract) {
            Assert.ok(false, "Should have failed to unlock NFT without enough keys.");
        }
        catch (bytes memory) {}

        Vault.NFT[] memory nfts = vaultContract.getNFTs();
        Assert.equal(nfts.length, 1, "Should store nft");
        Assert.equal(ERC721Contract.ownerOf(ERC721TokenId), address(vaultContract), "Vault should own the ERC721 token");
    }

    function checkUnlockNFTGetsERC721() public {
        ReceiverWrapper receiver = new ReceiverWrapper();
        ReceiverWrapper burn = new ReceiverWrapper();
        keyContract.mint(address(receiver), 10**keyContract.decimals());
        receiver.approveERC20(keyContract, address(vaultContract), 10**keyContract.decimals());

        vaultContract.transferOwnership(address(burn));

        // Remove ERC1155 from prize pool
        burn.backdoorNFT(vaultContract, 1);

        receiver.unlockNFT(vaultContract);

        Vault.NFT[] memory nfts = vaultContract.getNFTs();
        Assert.equal(nfts.length, 0, "Should not store nft");
        Assert.equal(ERC721Contract.ownerOf(ERC721TokenId), address(receiver), "Receiver should own the ERC721 token");
        Assert.equal(keyContract.balanceOf(address(receiver)), 0, "should have used key");
    }

    function checkUnlockNFTGetsERC1155() public {
        ReceiverWrapper receiver = new ReceiverWrapper();
        ReceiverWrapper burn = new ReceiverWrapper();
        keyContract.mint(address(receiver), 10**keyContract.decimals());
        receiver.approveERC20(keyContract, address(vaultContract), 10**keyContract.decimals());

        vaultContract.transferOwnership(address(burn));

        // Remove ERC721 from prize pool
        burn.backdoorNFT(vaultContract, 0);


        receiver.unlockNFT(vaultContract);

        Vault.NFT[] memory nfts = vaultContract.getNFTs();
        Assert.equal(nfts.length, 1, "Should store one nft");
        Assert.equal(ERC1155Contract.balanceOf(address(vaultContract), ERC1155TokenId), 1, "Vault should own ERC1155 tokens");
        Assert.equal(ERC1155Contract.balanceOf(address(receiver), ERC1155TokenId), 1, "Receiver should own ERC1155 tokens");
        Assert.equal(keyContract.balanceOf(address(receiver)), 0, "should have used key");
        Assert.equal(nfts[0].value, 1, "Should store 1 ERC1155");
    }

    function checkUnlockNFTAll() public {
        ReceiverWrapper receiver = new ReceiverWrapper();
        keyContract.mint(address(receiver), 3*10**keyContract.decimals());
        receiver.approveERC20(keyContract, address(vaultContract), 3*10**keyContract.decimals());


        receiver.unlockNFT(vaultContract);
        receiver.unlockNFT(vaultContract);
        receiver.unlockNFT(vaultContract);

        Vault.NFT[] memory nfts = vaultContract.getNFTs();
        Assert.equal(nfts.length, 0, "Should store one nft");
        Assert.equal(ERC1155Contract.balanceOf(address(vaultContract), ERC1155TokenId), 0, "Vault should noz own ERC1155 tokens");
        Assert.equal(ERC1155Contract.balanceOf(address(receiver), ERC1155TokenId), 2, "Receiver should own ERC1155 tokens");
        Assert.equal(ERC721Contract.ownerOf(ERC721TokenId), address(receiver), "Receiver should own the ERC721 token");
        Assert.equal(keyContract.balanceOf(address(receiver)), 0, "should have used key");
    }

}
