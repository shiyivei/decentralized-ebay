//循环控制for 和 while

// for (let i = 0; i<10;i+=2) {
//      console.log('i =',i)
// }

let grades = [100,80,56,81]

for (let i=0; i < grades.length; i++) {
     if (i === 1) {
          console.log('i =',grades[i]);
     }
}

const posts = [
     { title: 'Post One', body: 'This is post one' },
     { title: 'Post Two', body: 'This is post two' },
     {title: 'Post Three', body: 'This is post three'}
]

//for loop 与object、array的结合使用

for (let i=0; i < posts.length; i++) {
     if (i === 1) {
          let post = posts[i]
          console.log(post.title);
     }
}

// let condition = true
// while (condition) {
//      console.log('Hello World');
//      break;
// }