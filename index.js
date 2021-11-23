
console.log(1);
var coursesAPI  =  'http://localhost:3000/courses';

function start()    {
    getCourses(renderCourses)

    handleCreateForm()
}

start();

function getCourses(callback)   {
    fetch(coursesAPI)
    .then(function(response){

        return response.json();
    })
    .then(callback)
}

function createCourse(data,callback) {
    var option= {
            method:'POST',
            headers: {
            'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
    }
    fetch(coursesAPI,option)
    .then(function(response)    {
        response.json()
    })
    .then(callback)
}

function renderCourses(courses)    {
    var listCoursesBlock = document.querySelector('#list-courses')
    var htmls=courses.map(function(course){
        return `
        <li>
        <h4>${course.title}</h4>
        <p>${course.description}</p>
        </li>
        `
    })
    listCoursesBlock.innerHTML  = htmls.join('')
}

function handleCreateForm() {
    var createBtn=document.querySelector('#create')
    createBtn.onclick  =   function()  {
        var name=document.querySelector('input[name="title"]').value
        var description=document.querySelector('input[name="description"]').value
        
        var formData={
            title:name,
            description:description
        }
    createCourse(formData)
    }
}