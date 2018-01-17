var PULSCrowdsale = artifacts.require("./PULSCrowdsale.sol");

module.exports = function(deployer, network, accounts) {
	return liveDeploy(deployer, accounts);
};

function latestTime() {
	return web3.eth.getBlock('latest').timestamp;
}

const duration = {
	seconds: function(val) { return val},
	minutes: function(val) { return val * this.seconds(60) },
	hours:	 function(val) { return val * this.minutes(60) },
	days:	 function(val) { return val * this.hours(24) },
	weeks:	 function(val) { return val * this.days(7) },
	years:	 function(val) { return val * this.days(365)} 
};

async function liveDeploy(deployer, accounts) {
	const BigNumber = web3.BigNumber;
	const RATE = 1000;
	const startTime = latestTime() + duration.seconds(10);
	const endTime =	startTime + duration.weeks(1);
	// console.log('\n', [startTime, endTime, RATE, accounts[0]]);	
	//(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) 
	
	return deployer.deploy(PULSCrowdsale, startTime, endTime, RATE, accounts[0]).then( async () => {

		var Web3 = require('web3');
		var web3 = new Web3('http://localhost:8545');
		var encodedConstructorParameters = web3.eth.abi.encodeParameters(['uint256', 'uint256', 'uint256', 'address'], [startTime, endTime, RATE, accounts[0]]);
		console.log('\nPULSCrowdsale encoded constructor parameteres to validate a contract:\n', encodedConstructorParameters, '\n');


		const instance = await PULSCrowdsale.deployed();
		const token = await instance.token.call();
		console.log('PULSToken address:\n', token, '\n');
	});
}