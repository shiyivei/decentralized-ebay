
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

let score = 100;

//漏斗比较

// if (score ===100) {
//      console.log("perfect")
// }else if (score >=90) {
//      console.log("great")
// }else if (score >=80) {
//      console.log("good")
// }else if (score >= 60) {
//      console.log("pass")
// }else {
//      console.log("you need more harder")
// }

//switch 结构
//不同于golang的switch，Javascript匹配到分支后需要break才能结束
// 而golang只要匹配到一个分支就结束

switch(score) {
     case 100:
          console.log("perfect")
          break;
     case 80:
          console.log("great")
          break;
     case 60:
          console.log("passed")
          break;
     default:
          console.log("you need more harder")
          break;
}



