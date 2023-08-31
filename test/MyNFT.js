const MyNFT = artifacts.require("../contracts/MyNFT.sol");

// Traditional Truffle test
contract("MyNFT", (accounts) => {
    it("Should initialize nft", async function () {
        //initalize
        let account = accounts[0];
        const nftcontract = await MyNFT.new();
        let currentBalance = await nftcontract.balanceAddr(account);
        let numberOfTokensLeft = await nftcontract.numberOfTokensLeft();

        console.log(currentBalance.toString(10), numberOfTokensLeft.toString(10));
        //check balance
        assert.equal(currentBalance, 2);
        //check number of tokens
        assert.equal(numberOfTokensLeft, 10);

        // mint nft
        await nftcontract.mintNFT(account, "ipfs://QmQc4SpF3tMQgP5CCxtoaFtJJTTT8h4CjdSN4X9iFMCxoF")

        currentBalance = await nftcontract.balanceAddr(account);
        numberOfTokensLeft = await nftcontract.numberOfTokensLeft();

        console.log(currentBalance.toString(10), numberOfTokensLeft.toString(10));
        //check balance
        assert.equal(currentBalance, 1);
        //check number of tokens
        assert.equal(numberOfTokensLeft, 9);
    });

});

