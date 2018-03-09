var PULSCrowdsale = artifacts.require("./PULSCrowdsale.sol");

module.exports = function(deployer, network, accounts) {
	return liveDeploy(deployer, accounts);
};

async function liveDeploy(deployer, accounts) {	
	return deployer.deploy(PULSCrowdsale, { gas: web3.eth.getBlock("pending").gasLimit }).then( async () => {
		const instance = await PULSCrowdsale.deployed();
		const token = await instance.token.call();
		console.log('PULSToken address:\n', token, '\n');


		var Web3 = require('web3');
		var web3 = new Web3('http://localhost:8545');
		var encodedConstructorParameters = web3.eth.abi.encodeParameters(['address'], ['0x00233e2909c6c8c8Ea29029547067a948965fb55']);
		console.log('\nPULSCrowdsale encoded constructor parameteres to validate a contract:\n', encodedConstructorParameters, '\n');
	});
}