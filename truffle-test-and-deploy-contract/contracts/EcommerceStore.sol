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

          bytes32  sealedBid = keccak256(abi.encode(_amount,_secret));

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