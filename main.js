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

var courses=[
    {
        name:'Javascript',
        coin:680
    },
    {
        name:'Ruby',
        coin:860
    },
    {
        name:'PHP',
        coin:980
    }
];
// Array.prototype.filter2=function(callback)  {
//     var output=[];
//     for(var index in this)  {
//         if(this.hasOwnProperty(index))  {
//            var result= callback(this[index],index,this);
//            if(result)   {
//                output.push(this[index]);
//            }
//         }
//     }
//     return output;
// }
// var filtercourse=courses.filter2(function(course,index,array){
//     return  course.coin>770;
// })
// console.log(filtercourse)

// courses.forEach(function(course,index,array)    {
//     console.log(index,course)
// })
// console.log(document)
var headingNode = document.getElementById('hehe')
console.log(headingNode)