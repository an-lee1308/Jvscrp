// alert('Hello')
// // forEach
// var courses =   [
//     'Javascript',
//     'ruby',
//     'PHP', 
// ];
// Array.prototype.forEach2=function(callback){
//     for(var index in this)
//     if(this.hasOwnProperty(index))  {
//     callback(this[index],index,this)
//     }
// };
// courses.forEach2(function(course,index,array) {  
//     console.log(course,index,array) 
// });
// courses.forEach(function(course,index,array){
//     console.log(course,index,array);
// });*/

// var courses=[
//     {
//         name:'Javascript',
//         coin:680
//     },
//     {
//         name:'Ruby',
//         coin:860
//     },
//     {
//         name:'PHP',
//         coin:980
//     }
// ];
// Array.prototype.filter2=function(callback)  {
//     var output=[];
//     for(var index in this)  {
//         if(this.hasOwnProperty(index))  {
//            var result= callback(this[index],index,this);
//            console.log(this[index].coin)
//            if(result)   {
//                output.push(this[index]);
//            }
//         }
//     }
//     return output;
// }
// var filterCourse=courses.filter2(function(course,index,array){
//     return  course.coin>1000;
// })
// console.log(filterCourse)
// var x=courses.fill(99999,0)
// var n=[]
// console.log(typeof(n))
// courses.forEach(function(course,index,array)    {
//     console.log(index,course)
// })
// console.log(document)
// console.log('hello')
    // var headingElement = document.querySelector('h1');
    // headingElement.title='Heading'


    // console.log(courses.map(course => course.name.length
    // ))

    // console.log(courses.map(function(course) {
    //  return course.name.length
    // }))

// var inputElement = document.querySelector('input[type="checkbox"]')

// inputElement.onchange = function(e) {
//     console.log(e.target.checked);
// }
// var promise = new Promise(
//     //Executor
//     function(resolve,reject) {
//         //Logic
//         //Thành công
//         //Thất bại
//         //reject();
//         resolve();
//     }
// )

// promise 
// .then(function(result)    {
//     console.log("Successful!")
// })
// .catch(function(error)   {
//     console.log("Fail")
// })
// .finally(function() {
//         console.log("Done!")
// })
// promise.all([promise1],[promise2])
//     .then(function([result1,result2]) {
//         var result1=result[0];
//         var result2=result[1];
//     })

// fetch('http://localhost:3000/courses')
//   .then(function(response)  {
//       return response.json();
//   })
//   .then(function(posts) {
//       var htmls=posts.map(function(post)    {
//           return `<li>
//           <img src="${post.img}" alt="">
//               <h2>${post.name}</h2>
//               <p>${post.description}</p>
//               </li>`;
//       })
//     var html=htmls.join('');
//     console.log(typeof(htmls[1]));
//     document.getElementById('test').innerHTML=html;
//   })
 

//   var coursesAPI="http://localhost:3000/courses"
//   fetch(coursesAPI)
//     .then(function(response){
//         return response.json();
//         //console.log(response);
//     })
//     .then(function(result){
//         console.log(result);
//     })
