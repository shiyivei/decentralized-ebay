EcommerceStore = artifacts.require("./EcommerceStore.sol");//相当于获取了实例化后的合约

amt_1 = web3.toWei(1, "ether");
current_time = Math.round(new Date()/1000);

EcommerceStore.deployed().then(i=>{i.addProductToStore('iphone6','Cell Phones & Accessories','imagelink','desclink',current_time,current_time + 300,amt_1,0).then(console.log)});
EcommerceStore.deployed().then(i=>{i.addProductToStore('iphone6s','Cell Phones & Accessories','imagelink','desclink',current_time,current_time + 300,amt_1,0).then(console.log)});
EcommerceStore.deployed().then(i=>{i.addProductToStore('iphone7','Cell Phones & Accessories','imagelink','desclink',current_time,current_time + 300,amt_1,0).then(console.log)});
EcommerceStore.deployed().then(i=>{i.addProductToStore('iphone7s','Cell Phones & Accessories','imagelink','desclink',current_time,current_time + 300,amt_1,0).then(console.log)});
EcommerceStore.deployed().then(i=>{i.productIndex.call().then(function(f){console.log(f)})});

module.exports = function(deployer) {

}

