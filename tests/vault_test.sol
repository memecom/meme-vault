// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 
import "testContracts/TestERC721.sol";
import "testContracts/TestERC1155.sol";

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
// <import file to test>


import "contracts/Vault.sol";
import "contracts/Key.sol";

contract testVault {

    Vault public vaultContract;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeEach() public {
        vaultContract = new Vault();
    }

    function checkWhiteListAdress() public {
        vaultContract.setWhiteList(TestsAccounts.getAccount(1), true);

        Assert.ok(vaultContract.isInWhiteList(TestsAccounts.getAccount(1)), "should be whitelested");
        Assert.ok(!vaultContract.isInWhiteList(TestsAccounts.getAccount(2)), "should not be whitelisted");
    }

    function checkSetKeysAmountAsReward() public {
        vaultContract.setKeysAmountAsReward(10);

        Assert.equal(vaultContract.KEYS_AMOUNT_AS_REWARD(), uint256(10), "should be 10");
    }

    function checkSetKeysAmountToUnlockNFT() public {
        vaultContract.setKeysAmountToUnlockNFT(10);

        Assert.equal(vaultContract.KEYS_AMOUNT_TO_UNLOCK_NFT(), 10, "should be 10");
    }

    function checkSetKeyContract() public {
        Key key = new Key();
        vaultContract.setKeyContract(key);

        Assert.equal(vaultContract.getKeyContract(), address(key), "should be same adress");
    }

    function checkOnERC721Received() public {
        address sender = TestsAccounts.getAccount(1);

        Key keyContract = new Key();
        keyContract.mint(address(vaultContract), 10**keyContract.decimals());

        vaultContract.setKeyContract(keyContract);
        vaultContract.setWhiteList(sender, true);
        vaultContract.onERC721Received(0x0000000000000000000000000000000000000000, sender, 1, "");


        Vault.NFT[] memory nfts = vaultContract.getNFTs();

        Assert.equal(nfts.length, 1, "should not be empty");
        Assert.equal(keyContract.balanceOf(sender), 10**keyContract.decimals(), "should have one key");
        Assert.equal(keyContract.balanceOf(address(vaultContract)), 0, "should have zero keys");
    }

    function checkOnERC1155Received() public {
        address sender = TestsAccounts.getAccount(1);

        Key keyContract = new Key();
        keyContract.mint(address(vaultContract), 3 * 10**keyContract.decimals());

        vaultContract.setKeyContract(keyContract);
        vaultContract.setWhiteList(sender, true);
        vaultContract.onERC1155Received(0x0000000000000000000000000000000000000000, sender, 1, 1,"");
        vaultContract.onERC1155Received(0x0000000000000000000000000000000000000000, sender, 1, 2,"");


        Vault.NFT[] memory nfts = vaultContract.getNFTs();

        Assert.equal(nfts.length, 1, "should store exactly one ");
        Assert.equal(nfts[0].value, 3, "should reviece 3 erc1155 nfts");
        Assert.equal(keyContract.balanceOf(sender), 3 * 10**keyContract.decimals(), "should have one key");
        Assert.equal(keyContract.balanceOf(address(vaultContract)), 0, "should have zero keys");
    }

    function checkOnERC1155BatchReceived() public {
        address sender = TestsAccounts.getAccount(1);

        Key keyContract = new Key();
        keyContract.mint(address(vaultContract), 7 * 10**keyContract.decimals());

        vaultContract.setKeyContract(keyContract);
        vaultContract.setWhiteList(sender, true);
        vaultContract.onERC1155Received(0x0000000000000000000000000000000000000000, sender, 1, 1,"");
        uint256[] memory ids = new uint256[](3);
        ids[0] = 1;
        ids[1] = 1;
        ids[2] = 2;

        uint256[] memory values = new uint256[](3);
        values[0] = 2;
        values[1] = 1;
        values[2] = 3;
        vaultContract.onERC1155BatchReceived(0x0000000000000000000000000000000000000000, sender, ids, values,"");

        Vault.NFT[] memory nfts = vaultContract.getNFTs();

        Assert.equal(nfts.length, 2, "should store exactly two nfts ");
        Assert.equal(nfts[0].value, 4, "should reviece 4 erc1155 nfts for first nft");
        Assert.equal(nfts[1].value, 3, "should reviece 3 erc1155 nfts for first nft");
        Assert.equal(keyContract.balanceOf(sender), 7 * 10**keyContract.decimals(), "should have one key");
        Assert.equal(keyContract.balanceOf(address(vaultContract)), 0, "should have zero keys");
    }
}