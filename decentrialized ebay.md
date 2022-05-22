## 1. 业务背景和整体架构

### 1.1 数据的存储

在以太坊上存放图片和大文本十分昂贵，甚至是不可能，因此我们把去中心化项目发热数据存放在IPFS上

### 1.2 为什么要去中心化

中心化平台权力很大，乱封号

中心化平台佣金高，商品价格最终会转移到消费者身上

商家和消费者对自身数据缺少实质性的拥有能力

### 1.3 项目细节

1. 陈列商品
2. 将文件存放到IPFS上
3. 浏览产品
4. 拍卖
5. 托管合约
6. 2/3签名

### 1.4 应用架构

1. Web前端，web前端由HTML、CSS和Javascript组合而成（大量使用可web3.js）
2. 区块链，所有的交易和代码都会在链上，商品、出价和合约都在链上
3. MongoDB：使用其来过滤数据
4. NodeJS服务器：它是后端服务器，前端通过它与后端通信。给前端暴露API从数据库中查询和检索产品
5. IPFS，当用户在商店中上架产品后，前端会将产品文件和介绍上传到IPFS上，并上传文件的哈希存到链

![IMG_33967F03C86E-1](/Users/qinjianquan/Downloads/IMG_33967F03C86E-1.jpeg)

### 1.5 实现步骤

1. 合约实现：solidity + truffle + ganache
2. 通过命令行与IPFS交互
3. 完成端后，实现前端、合约、IPFS的交互，并在前端显示出价和拍卖功能
4. 使用MongoDB存储产品
5. 使用Node.js服务端代码监听合约事件，然后向数据库插入数据
6. 更新数据库以实现产品查询
7. 实现合约托管和前端，已实现资金撤回、退款等功能

## 2. 编写智能合约&上架商品

### 2.1 编写店铺合约

```
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//定义一个电子商店合约

contract EcommerceStore {

     //定义商品状态
     enum ProductStatus {
            Available,
            SoldOut,
            Unsold
     }

     //定义商品类型
     enum ProductCondition {
               New,
               Used
     }

     //定义商品编号代表产品，它是唯一的
     uint public productIndex;

     //定义map类型，用来表示商品在store中唯一索引
     mapping (uint => address) productIdInStore;
     
     //通过地址能够查到商店，通过商店中的商品id能够查到商品
     mapping(address => mapping(uint => Product)) stores;

     //定义商品
     struct Product {

          //商品属性

          uint id;
          string name;
          string category;
          string imageLink;
          string descLink;

          //拍卖属性
 
          uint auctionStartTime;
          uint auctionEndTime;
          uint startPrice;

          address highestBidder;
          uint highestBid;
          uint secondHighestBid;
          uint totalBids;

          //商品状态

          ProductStatus status;
          ProductCondition condition;

     }

     //构造函数与合约同名，并在一开始就会被调用,用来初始化变量
     constructor(){
          productIndex = 0;
     }

     //添加商品

     function addProductToStore(string memory _name, string memory _category, string memory _imageLink, string memory _descLink,
     uint _auctionStartTime, uint _auctionEndTime, uint _startPrice,
     uint _productCondition) public {

          require(_auctionStartTime < _auctionEndTime, "auction start time should be before auction end time");
          productIndex +=1;

          //填写商品信息
          Product memory product = Product(productIndex, _name, _category, _imageLink, _descLink,
          _auctionStartTime, _auctionEndTime, _startPrice, address(0), 0, 0, 0, ProductStatus.Available, ProductCondition(_productCondition));

          //添加商品到商店,msg.sender是商店的地址，productIndex是商品的编号
          stores[msg.sender][productIndex] = product;
          //将商品编号和商店的地址对应起来
          productIdInStore[productIndex] = msg.sender;
     } 

     //查询商品

     function getProduct(uint _productId) public view returns(uint,string memory,string memory,string memory,string memory,uint,uint,uint,ProductStatus,ProductCondition){
          //已知商品编号，去store中查找商品
          Product memory product = stores[productIdInStore[_productId]][_productId];
          //返回商品信息
          return(product.id,product.name,product.category,product.imageLink,product.descLink,
          product.auctionStartTime,product.auctionEndTime,product.startPrice,
          product.status,product.condition);
     }
}
```

### 2.2 部署合约

参考：https://www.cnblogs.com/soowin/p/14345232.html

1. 使用truffle初始化并编译

 使用truffle help查看truffle commands

```
truffle-test-and-deploy-contract % truffle init //初始化truffle文件夹，并将合约放入contracts文件中
```

```
truffle-test-and-deploy-contract % truffle compile //编译合约
```

2. 在migrations文件中创建migration文件并配置要部署合约的参数信息

```
migrations % vim 2_deploy_contract.js
```

```
const EcommerceStore = artifacts.require('EcommerceStore.sol');

module.exports = function (deployer) {
     deployer.deploy(EcommerceStore);
};
```

3. 启动ganache-cli

```
truffle-test-and-deploy-contract % ganache-cli //启动ganache-cli
```

4. 部署合约 （新建一个终端窗口）

```
truffle-test-and-deploy-contract % truffle migrate
```

5. 进入console

```
truffle console
truffle(development)> 
```

### 2.3 测试合约

#### 2.3.1 定义参数

web3.js文档：https://web3js.readthedocs.io/en/v1.2.0/web3-utils.html#towei

```
truffle(develop)> EcommerceStore 

//定义参数
truffle(develop)> amt_1 = web3.utils.toWei('1', 'ether'); //将单位转换为wei
truffle(develop)> current_time = Math.round(new Date()/1000); //转换成秒
1653098076

truffle(develop)> new Date()
2022-05-21T01:47:40.026Z
truffle(develop)> new Date()/1 //获取整型，默认是毫秒
1653097766327
```

#### 2.3.2 执行合约

1. **添加商品到商店**

```
truffle(develop)> EcommerceStore.deployed().then(i=>{i.addProductToStore('iphone6','Cell Phones & Accessories','imagelink','desclink',current_time,current_time + 200,amt_1,0).then(console.log)})
```

```
truffle(develop)> {
  tx: '0x59964db24965822b2dc607d1b1fdf3e7eab138a3b34ef5e5b889c8310b2000e0',
  receipt: {
    transactionHash: '0x59964db24965822b2dc607d1b1fdf3e7eab138a3b34ef5e5b889c8310b2000e0',
    transactionIndex: 0,
    blockNumber: 5,
    blockHash: '0xbcfc2d7a5fde8e2c0ea534655a5794c98063b3b570d20120a93cac27186d8d45',
    from: '0xfb7032b3fcffc0a41e96b99afd663a477819667c',
    to: '0xea914459cde53ebea8adf4f86b26624b8b19f4ad',
    cumulativeGasUsed: 263416,
    gasUsed: 263416,
    contractAddress: null,
    logs: [],
    logsBloom: '0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
    status: true,
    effectiveGasPrice: '0xb5366024',
    type: '0x2',
    rawLogs: []
  },
  logs: []
}
```

2. **查询商品**

```
truffle(develop)> EcommerceStore.deployed().then(i=>{i.getProduct(1).then(console.log)})
```

```
truffle(develop)> Result {
  '0': BN {
    negative: 0,
    words: [ 1, <1 empty item> ],
    length: 1,
    red: null
  },
  '1': 'iphone6',
  '2': 'Cell Phones & Accessories',
  '3': 'imagelink',
  '4': 'desclink',
  '5': BN {
    negative: 0,
    words: [ 42488492, 24, <1 empty item> ],
    length: 2,
    red: null
  },
  '6': BN {
    negative: 0,
    words: [ 42488692, 24, <1 empty item> ],
    length: 2,
    red: null
  },
  '7': BN {
    negative: 0,
    words: [ 56885248, 2993385, 222, <1 empty item> ],
    length: 3,
    red: null
  },
  '8': BN {
    negative: 0,
    words: [ 0, <1 empty item> ],
    length: 1,
    red: null
  },
  '9': BN {
    negative: 0,
    words: [ 0, <1 empty item> ],
    length: 1,
    red: null
  }
}
```

ok,以上就是合约的全部内容

## 3 拍卖逻辑&拍卖合约

### 3.1 暗标拍卖 

**vickery auction**

先统一报价，并且加密，最后拍卖结束统一揭示报价，第二价高者赢得本次报价

### 3.2 拍卖合约

product结构体中还需增加

```
//把与竞价相关的信息加密为hash，并且作为key存储在map中
          //竞价者-竞价信息
          mapping(address => mapping(bytes32 => Bid )) bids;
```

补充与竞价相关的信息

```
 //竞拍

     struct Bid {
          address bidders;
          uint productId;

          uint value; //竞价
          bool revealed; //是否揭示
     }
```

所有合约代码

```
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//定义一个电子商店合约

contract EcommerceStore {

     //定义商品状态
     enum ProductStatus {
            Available,
            SoldOut,
            Unsold
     }

     //定义商品类型
     enum ProductCondition {
               New,
               Used
     }

     //定义商品编号代表产品，它是唯一的
     uint public productIndex;

     //定义map类型，用来表示商品在store中唯一索引
     mapping (uint => address) productIdInStore;
     
     //通过地址能够查到商店，通过商店中的商品id能够查到商品
     mapping(address => mapping(uint => Product)) stores;

     //定义商品
     struct Product {

          //商品属性

          uint id;
          string name;
          string category;
          string imageLink;
          string descLink;

          //拍卖属性
 
          uint auctionStartTime;
          uint auctionEndTime;
          uint startPrice;

          address highestBidder;
          uint highestBid;
          uint secondHighestBid;
          uint totalBids;

          //商品状态

          ProductStatus status;
          ProductCondition condition;

     }

     //把与竞价相关的信息加密为hash，并且作为key存储在map中
          //竞价者-竞价信息
     mapping(address => mapping(bytes32 => Bid )) bids;

     //竞拍

     struct Bid {
          address bidder;
          uint productId;

          uint value; //竞价，实际支付的价格
          bool revealed; //是否揭示
     }



     //构造函数与合约同名，并在一开始就会被调用,用来初始化变量
     constructor(){
          productIndex = 0;
     }

     //添加商品函数

     function addProductToStore(string memory _name, string memory _category, string memory _imageLink, string memory _descLink,
     uint _auctionStartTime, uint _auctionEndTime, uint _startPrice,
     uint _productCondition) public {

          require(_auctionStartTime < _auctionEndTime, "auction start time should be before auction end time");
          productIndex +=1;

          //处理map
          

          //填写商品信息
          Product memory product = Product(productIndex, _name, _category, _imageLink, _descLink,_auctionStartTime, _auctionEndTime, _startPrice, address(0), 0, 0, 0, ProductStatus.Available, ProductCondition(_productCondition));

          //添加商品到商店,msg.sender是商店的地址，productIndex是商品的编号
          stores[msg.sender][productIndex] = product;
          //将商品编号和商店的地址对应起来
          productIdInStore[productIndex] = msg.sender;
     } 

     //查询商品函数

     function getProduct(uint _productId) public view returns(uint,string memory,string memory,string memory,string memory,uint,uint,uint,ProductStatus,ProductCondition){
          //已知商品编号，去store中查找商品
          Product memory product = stores[productIdInStore[_productId]][_productId];
          //返回商品信息
          return(product.id,product.name,product.category,product.imageLink,product.descLink,
          product.auctionStartTime,product.auctionEndTime,product.startPrice,
          product.status,product.condition);
     }

     //竞拍
     function bid(uint _productId,bytes32 _bid)public payable returns (bool) {
          //使用storage更改数据
          Product storage product = stores[productIdInStore[_productId]][_productId];

          //检查商品是否已经被拍卖
          //require 判断条件，相当于if，如果不满足条件，则抛出异常，后面的字符串是抛出异常的信息
          require(block.timestamp >= product.auctionStartTime, "auction has not started yet");
          require(block.timestamp <= product.auctionEndTime, "auction has ended");

          //msg是消息，msg.sender是消息发送者，msg.value是消息金额
          require(msg.value>product.startPrice,"bid should be greater than start price");

          //检查竞拍者是否已经竞拍过，防止重复竞拍
          // require(product.bids[msg.sender][_bid].bidder == 0,"you have already bid");
          require(bids[msg.sender][_bid].bidder == address(0x0),"you have already bid");

          //添加竞拍者和竞拍信息
          bids[msg.sender][_bid]= Bid(msg.sender,_productId,msg.value,false);

          product.totalBids +=1;

          return true;
     }

     //揭示报价
     function revealBid(uint _productId,string memory _amount,string memory _secret) public {
          Product storage product = stores[productIdInStore[_productId]][_productId];
          require(block.timestamp >= product.auctionEndTime, "reveal should be after auction ended");
          bytes memory b = bytes(string(abi.encodePacked(_amount,_secret)));

          bytes32 sealedBid = keccak256(b);
          Bid memory bidInfo = bids[msg.sender][sealedBid];

          //校验揭示信息
          require(bidInfo.bidder >address(0x0), "bidder should be valid");
          require(bidInfo.revealed == false, "bid should not be revealed");

          //退款变量
          uint refund;
          //把报价转换为uint
          uint amount = stringToUint(_amount);
          
          //检查报价是否正确，如果实际支付的价格报价低于竞拍的价格，则退款
          if (bidInfo.value < amount) {
               refund = bidInfo.value;
          } else {
               //如果没人报价，则出价为最高价
               if (address(product.highestBidder)==address(0x0)) {
                    product.highestBid = amount;
                    //次高价为起拍价
                    product.secondHighestBid = product.startPrice;
                    //如果支付价格比报价高，则退回高出的部分（其实就是让实际支付的金额=报价）
                    refund = bidInfo.value- amount;
               }else {
                    if(amount > product.highestBid){
                         //如果报价比最高价高，则报价变为最高价
                         //第二高价变为最高价
                         product.secondHighestBid = product.highestBid;

                         // address payable product.highestBidder;
                         //退回原来最高价出价者的钱
                         payable(product.highestBidder).transfer(product.highestBid);

                         //更新最高价
                         product.highestBid = amount;

                         //更新最高价的出价者
                         product.highestBidder = msg.sender;

                         //退回高出的部分
                         refund = bidInfo.value - amount;

                    }else if (amount > product.secondHighestBid) {
                         //如果报价比次高价高，但是低于最高价，则竞价失败，退款
                         product.secondHighestBid = amount;
                         //返回钱
                         refund = bidInfo.value;
                         
                    }else {
                         //如果报价比次高价低，则竞价失败，退款
                         refund = bidInfo.value;
                    }      
               }
          }
          
          bids[msg.sender][sealedBid].revealed = true;

          if (refund > 0) {
               //退款
               payable(msg.sender).transfer(refund);
          }
     }

     function stringToUint(string memory s) private pure  returns(uint) {
          //把字符串转换为字节数组
          bytes memory b = bytes(s);
          //把字节数组转换为uint
          uint result = 0;
          for (uint i = 0; i < b.length; i++){
               //类型不能直接运算，需要先强制转换
               uint8 c = uint8(bytes(b)[i]);
               if(c>=48 && c<=57){
                    result = result*10 + c-48;
               }
          }
          return result;
     }

     function hightestbidderInfo(uint _productId)public view returns(address,uint,uint){
          Product memory product = stores[productIdInStore[_productId]][_productId];

          return (product.highestBidder,product.highestBid,product.secondHighestBid);
     }

     function totalBids(uint _productId)public view returns(uint){
          Product memory product = stores[productIdInStore[_productId]][_productId];
          return product.totalBids;
     }
}
```

### 3.3 部署&交互

合约部署完成与合约进行交互

查看账户余额

```
ruffle(development)> web3.eth.getBalance("0x6592456de564327bBcFe709E432BBdC6Fa18CC19")
'99943149980000000000'
truffle(development)> web3.eth.getBalance(accounts[0])
'99943149980000000000'
```

```
//定义参数
truffle(develop)> amt_1 = 10; //起拍价
truffle(develop)> current_time = Math.round(new Date()/1000); //转换成秒
1653098076
```

向商店中加入商品

```
truffle(develop)> EcommerceStore.deployed().then(i=>{i.addProductToStore('iphone6','Cell Phones & Accessories','imagelink','desclink',current_time,current_time + 600,amt_1,0).then(console.log)})
```

打款1

```
sealedBid = web3.utils.keccak256(web3.eth.abi.encodeParameters(['string','string'],['20','_secret1']))//出价和保密信息
```

报价1

```
EcommerceStore.deployed().then(i=>{i.bid(1,sealedBid,{from:accounts[0],value:15}).then(console.log)})
```

打款2

```
sealedBid = web3.utils.keccak256(web3.eth.abi.encodeParameters(['string','string'],['30','_secret2']))//出价和保密信息
```

报价2

```
EcommerceStore.deployed().then(i=>{i.bid(1,sealedBid,{from:accounts[1],value:17}).then(console.log)})
```

揭示报价

```
EcommerceStore.deployed().then(i=>{i.revealBid(1,	'20','_secret1').then(console.log)})
```

```
EcommerceStore.deployed().then(i=>{i.revealBid(1,	'30','_secret2').then(console.log)})
```

查看最高报价

```
EcommerceStore.deployed().then(i=>{i.hightestbidderInfo(1).then(console.log)})
```

查看第二高报价

```
EcommerceStore.deployed().then(i=>{i.totalBids(1).then(console.log)})
```

## 4 IPFS

是一个点对点分布式文件系统

### 4.1 安装IPFS

下载文件

```
https://github.com/ipfs/ipfs-desktop/releases
```

解压文件

```
go-ipfs % bash install.sh //进入文件夹并安装
```

```
go-ipfs % ipfs --version  //查看版本
ipfs version 0.12.2
```

### 4.2 启用IPFS

```
ipfs daemon
```

```
Initializing daemon...
go-ipfs version: 0.12.2
Repo version: 12
System version: amd64/darwin
Golang version: go1.16.15
Swarm listening on /ip4/127.0.0.1/tcp/4001
Swarm listening on /ip4/127.0.0.1/udp/4001/quic
Swarm listening on /ip4/192.168.31.144/tcp/4001
Swarm listening on /ip4/192.168.31.144/udp/4001/quic
Swarm listening on /ip6/::1/tcp/4001
Swarm listening on /ip6/::1/udp/4001/quic
Swarm listening on /p2p-circuit
Swarm announcing /ip4/127.0.0.1/tcp/4001
Swarm announcing /ip4/127.0.0.1/udp/4001/quic
Swarm announcing /ip4/192.168.31.144/tcp/4001
Swarm announcing /ip4/192.168.31.144/udp/4001/quic
Swarm announcing /ip6/::1/tcp/4001
Swarm announcing /ip6/::1/udp/4001/quic
API server listening on /ip4/127.0.0.1/tcp/5001
WebUI: http://127.0.0.1:5001/webui
Gateway (readonly) server listening on /ip4/127.0.0.1/tcp/8080
Daemon is ready
```

https://www.youtube.com/watch?v=yxzEIlShZp4

```
ipfs add -r . //上传文件
```

## 5 Web前端功能

### 5.1 主体架构

1. 展示商品的页面
2. 上传商品的功能
3. 用户可以看到产品细节，出价和揭示出价

```
import {default as Web3} from 'web3';
import {default as contract} from 'truffle-test-and-deploy-contract';
import ecommerce_store_artifacts from '../.../build/contracts/EcommerceStore.json';

var EcommerceStore = contract(ecommerce_store_artifacts);

var ipfsAPI = require('ipfs-api');

var ipfs = ipfsAPI({host: 'localhost', port: 5001, protocol: 'http'});

window.addEventListener('load', function() {
     if (typeof web3 !== undefined) {
          window.web3 = new Web3(web3.currentProvider);
     }else {
          window.web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
     }
     App.start();
});
```

### 5.2 种子区块链

自动化生成脚本

```
EcommerceStore = artifacts.require("./EcommerceStore.sol");//相当于获取了实例化后的合约

amt_1 = web3.toWei(1, "ether");
current_time = Math.round(new Date()/1000);

EcommerceStore.deployed().then(i=>{i.addProductToStore('iphone6','Cell Phones & Accessories','imagelink','desclink',current_time,current_time + 300,amt_1,0).then(console.log)});
EcommerceStore.deployed().then(i=>{i.addProductToStore('iphone6s','Cell Phones & Accessories','imagelink','desclink',current_time,current_time + 300,amt_1,0).then(console.log)});
EcommerceStore.deployed().then(i=>{i.addProductToStore('iphone7','Cell Phones & Accessories','imagelink','desclink',current_time,current_time + 300,amt_1,0).then(console.log)});
EcommerceStore.deployed().then(i=>{i.addProductToStore('iphone7s','Cell Phones & Accessories','imagelink','desclink',current_time,current_time + 300,amt_1,0).then(console.log)});
EcommerceStore.deployed().then(i=>{i.productIndex.call().then(function(f){console.log(f)})});
```

### 5.3 主页面HTML

### 5.4 上架商品页面HTML

### 5.5 上架商品JS实现

### 5.6 上传商品到IPFS

### 5.7 商品详情HTML

### 5.8 测试

## 6 资金托管合约

### 6.1 宣布赢家

### 6.2 获取信息

### 6.3 资金托管页面

### 6.4 测试

### 6.5 释放资金

## 7 MongoDB

### 7.1 MongoDB简介

