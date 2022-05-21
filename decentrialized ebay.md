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

