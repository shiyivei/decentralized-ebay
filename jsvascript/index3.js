
// 注意：javascript的比较条件在括号内

if (100>50) {
     console.log("100 is greater than 50"); //console.log可以认为直接输出
}else{
     console.log("100 is less than 50");
}

//逻辑运算符有三种

//&&, || , !

//相等 ===

let a =100;
let b =100;

if (a === b) {
     console.log(true)
}

let score = 45;

//漏斗比较

if (score ===100) {
     console.log("perfect")
}else if (score >=90) {
     console.log("great")
}else if (score >=80) {
     console.log("good")
}else if (score >= 60) {
     console.log("pass")
}else {
     console.log("you need more harder")
}