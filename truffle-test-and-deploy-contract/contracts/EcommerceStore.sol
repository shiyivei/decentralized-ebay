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

          //把与竞价相关的信息加密为hash，并且作为key存储在map中
          //竞价者-竞价信息
          mapping(address => mapping(bytes32 => Bid )) bids;

     }

     //竞拍

     struct Bid {
          address bidder;
          uint productId;

          uint value; //竞价
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

          //填写商品信息
          Product memory product = Product(productIndex, _name, _category, _imageLink, _descLink,
          _auctionStartTime, _auctionEndTime, _startPrice, address(0), 0, 0, 0, ProductStatus.Available, ProductCondition(_productCondition), null);

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
          require(now >= product.auctionStartTime, "auction has not started yet");
          require(now <= product.auctionEndTime, "auction has ended");

          //msg是消息，msg.sender是消息发送者，msg.value是消息金额
          require(msg.value>product.startPrice,"bid should be greater than start price");

          //检查竞拍者是否已经竞拍过，防止重复竞拍
          require(product.bids[msg.sender][_bid].bidder == 0,"you have already bid");

          //添加竞拍者和竞拍信息
          product.bids[msg.sender][_bid]= Bid(msg.sender,_productId,msg.value,false);

          product.totalBids +=1;

          return true;
     }

     //揭示报价
     function revealBid(uint _productId,string _amout,string _secret) public{
          Product storage product = strores[productInStore[_productIdIn]][_productId];
          require(now >= product.auctionEndTime, "reveal should be after auction ended");
          bytes32 sealedBid = sha3(_amout,_secret);
          Bid memory bidInfo = product.bids[msg.sender][sealedBid];

          //校验揭示信息
          require(bidInfo.bidder >0, "bidder should be valid");
          require(bidInfo.reveald == false, "bid should not be revealed");

          
     
     }

}