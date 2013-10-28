# Chongo [![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=basaundi&url=https://github.com/basaundi/chongo&title=chongo&language=coffescript&tags=github&category=software) [![Build Status](https://secure.travis-ci.org/basaundi/chongo.png)](http://travis-ci.org/basaundi/chongo)

A mongo-like interface to browser [Web Storage](http://dev.w3.org/html5/webstorage/) (localStorage and sessionStorage).

[![HEY CHONGO!](http://i.imgur.com/RXWLcrl.png)](http://www.youtube.com/watch?v=km2Tro4S8hk)

## Basic usage

```javascript
// Connection using sessionStorage, i.e. data is cleaned
//  when the browser is closed.
var con = new Chongo.Connection(sessionStorage);
var db = con.db('todos');   // "todo" database. Created if necesary.
var todo = db.col('todos'); // "todo" collection. Created if necesary.

// The next lines work as you'd expect.
todo.insert({title: "Buy apples.", completed: false});
var oid = todo.insert({title: "Take the trash out.", completed: false});
todo.update({_id: oid}, {completed: true});
var cur = todo.find();
while(cur.hasNext()){
	console.log(cur.next().title)
}
```

For more on the usage look in the `demo` and `test` folders.

## Internal behaviour

Each document is stored separately as JSON under a key with the name
`$.<db name>.<collection name>.$<ObjectId>`. An index of the documents
in a collection in $natural order is stored under the key
`$.<db name>.<collection name>`.

## Current and planned features

- [X] CRUD
- [ ] Indexing.
- [X] TodoMVC demo.
- [ ] Minimized build.
- [ ] Automatic synchronization with REST server.
- [ ] Events.
- [ ] Pluggable features for smaller library size.

## License

The code is distributed under MIT license.
