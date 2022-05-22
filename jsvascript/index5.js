
//声明了但是并没有调用执行

function hello() {
     console.log('hello');
}

hello();


function addMoney(p1,p2,discount) {
     console.log(p1)
     console.log(p2)
     console.log(discount)

     let res = p1+p2-discount;
     return res
}

let total = addMoney(100,200,10)
let message = "普通会员"

if (total>=200) {
     message = "银卡会员";
}
console.log(total)
console.log(message)

//构造函数

function createCa(name) {
     this.name = name;
}


//通过构造函数初始化对象

const a1 = new createCa('a1');
const a2 = new createCa('a2');
const a3 = new createCa('a3');
const a4 = new createCa('a4');
const a5 = new createCa('a5');

console.log(a1)