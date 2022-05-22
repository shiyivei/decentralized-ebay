//数组

let classClassmates = ["小明", "小红", "小白"] //array，数组
console.log(classClassmates)

classClassmates.push("小绿") //数组的添加
console.log(classClassmates)

let idPhoto = ["照片1", "照片2", "照片3"] //array，数组     
console.log(idPhoto)

//可以通过索引来访问数组中的元素
console.log(classClassmates[0])

//对象
 const igpost = {
     image: ' https://images.com',
     desc: ' this is a picture',
     date: '2020-05-05',
     comment: 'beautiful',
 }

 console.log('igpost', igpost)

 //通过.来访问对象中的属性
 console.log('igpost', igpost.comment)

 const wall = {
      igpost,
      igpost,
      igpost,  
 }

 console.log('wall', wall)