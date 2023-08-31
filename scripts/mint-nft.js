require("dotenv").config()
const API_URL = process.env.API_URL;
const PUBLIC_KEY = process.env.PUBLIC_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const { createAlchemyWeb3 } = require("@alch/alchemy-web3")
const web3 = createAlchemyWeb3(API_URL)
const contract = require("../artifacts/contracts/MyNFT.sol/MyNFT.json")

const contractAddress = "0xC51ccf34AAa82804b02A238260891b7260F01642"

const nftContract = new web3.eth.Contract(contract.abi, contractAddress)

async function mintNFT(walletAddress, tokenURI) {
	
	const balance = await web3.eth.get

	const nonce = await web3.eth.getTransactionCount(walletAddress, "latest") //get latest nonce
	console.log("nonce: ", nonce)

	//the transaction
	const tx = {
		from: walletAddress,
		to: contractAddress,
		nonce: nonce,
		gas: 500000,
		data: nftContract.methods.mintNFT(walletAddress, tokenURI).encodeABI(),
	}

	const signPromise = web3.eth.accounts.signTransaction(tx, PRIVATE_KEY)
	signPromise
		.then((signedTx) => {
			web3.eth.sendSignedTransaction(
				signedTx.rawTransaction,
				function (err, hash) {
					if (!err) {
						console.log(
							"The hash of your transaction is: ",
							hash,
							"\nCheck Alchemy's Mempool to view the status of your transaction!"
						)
					} else {
						console.log(
							"Something went wrong when submitting your transaction:",
							err
						)
					}
				}
			)
		})
		.catch((err) => {
			console.log(" Promise failed:", err)
		})
}

mintNFT(PUBLIC_KEY, "ipfs://QmQc4SpF3tMQgP5CCxtoaFtJJTTT8h4CjdSN4X9iFMCxoF")
