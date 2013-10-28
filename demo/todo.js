
var app = {};
var hashFilter = {
  '#/':          {},
  '#/active':    {completed:false},
  '#/completed': {completed:true},
}

function renderTodos(){
  updateNumbers();
  var el = document.getElementById('todo-list');
  el.innerHTML = '';
  var cur= app.col.find(app.filter);
  while(cur.hasNext()){
    var todo = cur.next();
    _appendTodo(todo);
  }
}

function updateNumbers(){
  var n = app.col.find({completed: true}).count();
  document.getElementById('nCompleted').innerHTML = n;
  var n = app.col.find({completed: false}).count();
  document.getElementById('nNotCompleted').innerHTML = n;
}

function removeTodo(e){
  var li = e.parentNode.parentNode;
  var oid = e.parentNode.dataset.oid;
  app.col.remove({_id: oid});
  li.parentNode.removeChild(li);
  updateNumbers();
}

function clearCompletedTodos(){
  todos = app.col.remove({completed: true});
  renderTodos();
}

function editTodo(){

}

function toggleTodo(e){
  var completed = e.checked;
  var oid = e.parentNode.dataset.oid;
  app.col.update({_id: oid}, {$set: {completed:completed}});
  updateNumbers();
}

function _appendTodo(todo){
  var el = document.getElementById('todo-list');
  var e = document.createElement('li');
  var html = app.template.replace('{{todo.title}}', todo.title)
                         .replace('checked="{{todo.completed}}"', todo.completed ? ' checked="checked" ' : '')
                         .replace('{{todo._id}}', todo._id);
  e.innerHTML = html;
  el.appendChild(e);
}

function addTodo(){
  var el = document.getElementById('new-todo');
  if(!el.value.trim()) return;
  var doc = {title: el.value, completed: false};
  doc._id = app.col.insert(doc);
  _appendTodo(doc);
  el.value = '';
  updateNumbers();
}

function ready(){
  app.con  = new Chongo.Connection(sessionStorage);
  app.db   = app.con.db('todos');
  app.col  = app.db.col('todos');
  app.filter = {}
  
  var el = document.getElementById('todo-list');
  app.template = el.getElementsByTagName('li')[0].innerHTML;
  checkHash();
  renderTodos();
}

function checkHash(){
  var filter = app.filter;
  var hash = window.location.hash;
  if(hashFilter[hash]) filter = hashFilter[hash];
  if(app.filter != filter){
    app.filter = filter;
    renderTodos();
  }
  setTimeout(checkHash, 500);
}

