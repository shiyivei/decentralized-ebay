//监听器，回呼
window.addEventListener('load',function(){
     const p1= document.getElementById("title")
     console.log(p1)
     p1.innerText = "订阅布鲁斯前端" //抓到更新

     const b1 = document.getElementById("btn")
     b1.addEventListener('click',function(){
          console.log("点击了按钮")
     })

     const box1 = document.getElementById("box")
     box1.innerHTML = '<p>Test</p>' //抓到更新

     //获得输入
     const input = document.getElementById("input1")
     input.addEventListener('keyup',function(e){
          console.log(e.target.value)
     })
     
})

