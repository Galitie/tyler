console.log("This code is linked to the html")

document.querySelector('button').addEventListener('click', postIt)

function postIt(){
console.log("You pressed the submit button!")
fetch("https://galitie.github.io/tyler/", {
  method: "POST",
  body: JSON.stringify({
    userId: 1,
    title: "Fix my bugs",
    completed: false
  }),
  headers: {
    "Content-type": "application/json; charset=UTF-8"
  }
})
  .then((response) => response.json())
  .then((json) => console.log(json));
}
