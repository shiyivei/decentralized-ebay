//开头大写，代表class

// class Card {

//      constructor(initName) {
//           this.name = initName;
//      }

// }

// const c1 = new Card("shiyivei");
// console.log(c1.name);


//this 指的是当下执行的环境,跟着执行者走的

class Card {
     constructor(initName) {
          this.name = initName;
          this.hello=this.hello.bind(this);//绑定
     }

     hello () {
          console.log("hello",this.name);
     }
}

const c1 = new Card("shiyivei");
c1.hello();

const c2 = {name :"aa"};
c2.hello = c1.hello;
c2.hello();

//继承
class Car {

     constructor(initName) {
          this.name = initName;
     }
     start() {
          console.log("car start");
     }
}

class Porshe extends Car {
     constructor(namePorshe) {
          super(namePorshe);
     }
     start() {
          super.start();
          console.log("car emit");
     }

     start() {
          console.log("porshe start");
     }
}

const p1 = new Porshe("porshe");
p1.start();
console.log("name",p1.name);

