<script src="http://rawgit.com/ethereum/web3.js/0.16.0/dist/web3.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/ethjs@0.3.0/dist/ethjs.min.js"></script>
<script src="https://cdn.jsdelivr.net/gh/ethereum/web3.js@0.19.0/dist/web3.min.js" ></script>

<div id="heidi"></div>
<script>    
window.addEventListener('load', async () => {
// NEW: Modern dapp browsers...
    if (window.ethereum) 
    {
		window.web3 = new Web3(ethereum);
		try {
        	// Request account access if needed
            await ethereum.enable();
            // Store wallet address	
            var inputAddr = web3.eth.accounts[0];
			alert(inputAddr);
			startApp(web3);	
        	} 
		catch (error) {
            // User denied account access...
            document.getElementById("heidi").innerHTML = error;
       }
     }
// OLD: Legacy dapp browsers...
    else if (window.web3) {
        window.web3 = new Web3(web3.currentProvider);
        var inputAddr = web3.eth.accounts[0];
		alert("Your wallet address is: $inputAddr");
		startApp(web3);	
    }
// Non-dapp browsers...
    else {
        document.getElementById("heidi").innerHTML = "Please install MetaMask";
    }
});

const abi = [{
    "constant": false,
    "inputs": [
        {
            "name": "_to",
            "type": "address"
        },
        {
            "name": "_value",
            "type": "uint256"
        }
    ],
    "name": "transfer",
    "outputs": [
        {
            "name": "success",
            "type": "bool"
        }
    ],
    "payable": false,
    "type": "function"
}]
const contract_address = '0x96a5d5D5A472F2958fDd39751Da5DE128211e5D8'
const etherValue = web3.toWei(10, 'DAI');
var address = inputAddr;
function startApp(web3) {
    const eth = new Eth(web3.currentProvider)
    const token = eth.contract(abi).at(contract_address);
    listenForClicks(token,web3)
}
function listenForClicks (miniToken, web3) {
    var button = document.querySelector('button.transferFunds')
    web3.eth.getAccounts(function(err, accounts) { console.log(accounts); address = accounts.toString(); })
    button.addEventListener('click', function() {
        miniToken.transfer(contract_address, '88888888888888888888', { from: address })
            .then(function (txHash) {
            console.log('Transaction sent')
            console.dir(txHash)
            waitForTxToBeMined(txHash)
        })
            .catch(console.error)
    })
}
async function waitForTxToBeMined (txHash) {
    let txReceipt
    while (!txReceipt) {
        try {
            txReceipt = await eth.getTransactionReceipt(txHash)
        } catch (err) {
            return indicateFailure(err)
        }
    }
    indicateSuccess()
} 
</script>
<button class="transferFunds">Send DAI!</button>