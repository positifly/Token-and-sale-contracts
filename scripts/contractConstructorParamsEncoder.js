var Web3 = require('web3');

var web3 = new Web3('http://localhost:8545');

var encodedConstructorParameters = web3.eth.abi.encodeParameters(['uint256', 'uint256', 'uint256', 'address'], [ 1516115506, 1516720306, 1000, '0x7043eeabe627b6d17aed216e7132b92bcdb64357' ]);

console.log(encodedConstructorParameters);