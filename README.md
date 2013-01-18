jQuery REST Client
=====
v0.0.2

Summary
---
A jQuery plugin for easy consumption of REST APIs

Downloads
---

* [Development Version](http://raw.github.com/jpillora/jquery.rest/gh-pages/dist/jquery.rest.js)
* [Production Version](http://raw.github.com/jpillora/jquery.rest/gh-pages/dist/jquery.rest.min.js)

Features
---
* Simple !
* Helpful Error Messages
* Uses jQuery Deferred for Asynchonous chaining
* Basic Auth Support

Basic Usage
---

1. Create a client.
2. Construct your API.
3. Make requests.

First setup your page:

``` html
<!-- jQuery -->
<script src="//ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script>

<!-- jQuery rest -->
<script src="//raw.github.com/jpillora/jquery.rest/gh-pages/dist/jquery.rest.min.js"></script>

<script>
  // Examples go here...
</script>
```

*Note: I strongly advise downloading and hosting the library on your own server as GitHub has download limits.*

Basic Example
``` javascript
var client = new $.RestClient('/rest/api/');

client.add('foo');

client.foo.read();
// GET /rest/api/foo/
client.foo.read("42");
// GET /rest/api/foo/42/
```

Retrieving Results Example (Uses [jQuery's $.Deferred](http://api.jquery.com/category/deferred-object/))
``` javascript
var client = new $.RestClient('/rest/api/');

client.add('foo');

var request = client.foo.read();
// GET /rest/api/foo/
request.done(function (data){ 
  alert('I have data: ' + data);
});

// OR simply:
client.foo.read().done(function (data){ 
  alert('I have data: ' + data);
});
```

Nested Example
``` javascript

var client = new $.RestClient('/rest/api/');

client.add('foo');
client.foo.add('baz');

client.foo.read();
// GET /rest/api/foo/
client.foo.read("42");
// GET /rest/api/foo/42/

client.foo.baz.read();
// GET /rest/api/foo/{ID Placeholder}/baz/
// ERROR ! Invalid number of arguments
client.foo.baz.read("42");
// GET /rest/api/foo/42/baz/
client.foo.baz.read("42","21");
// GET /rest/api/foo/42/baz/21/

```


Basic CRUD Operations Example
``` javascript

var client = new $.RestClient('/rest/api/');

client.add('foo');

// C
client.foo.create({a:21,b:42});
// POST /rest/api/foo/ (with data a=21 and b=42)
// Note: data can also be stringified to: {"a":21,"b":42} in this case, see options below

// R
client.foo.read();
// GET /rest/api/foo/
client.foo.read("42");

// U
client.foo.update("42", {my:"updates"});
// PUT /rest/api/42/   my=updates

// D
client.foo.delete("42");
// Or if JSLint is complaining...
client.foo.del("42");
```

Adding Custom Operations Example
``` javascript

var client = new $.RestClient('/rest/api/');

client.add('foo');
client.foo.add('bang', 'PATCH');

client.foo.patch({my:"data"});
//PATCH /foo/bang/   my=data
client.foo.patch("42",{my:"data"});
//PATCH /foo/42/bang/   my=data
```


Basic Authentication Example
``` javascript
var client = new $.RestClient({
  url: '/rest/api/',
  username: 'admin',
  password: 'secr3t'
});

client.add('foo');

client.foo.read();
// GET /rest/api/foo/
// With header "Authorization: Basic YWRtaW46c2VjcjN0"
```

Cache Example
``` javascript
var client = new $.RestClient({
  url: '/rest/api/',
  cache: 5 //This will cache requests for 5 seconds
});

client.add('foo');

client.foo.read().done(function(data) {
  //'client.foo.read' is now cached for 5 seconds
});

// wait 3 seconds...

client.foo.read().done(function(data) {
  //data returns instantly from cache
});

// wait another 3 seconds (total 6 seconds)...

client.foo.read().done(function(data) {
  //'client.foo.read' cached result has expired
  //data is once again retrieved from the server
});

// Note: the cache can be cleared with:
client.cache.clear();

```

Override Options Example
``` javascript

var client = new $.RestClient({
  url: '/rest/api/',
  cache: 5
});

client.add({
  name: 'foo'
});

client.add({
  name: 'bar',
  cache: 10,
  stringifyData: true
});

client.foo.read();
// GET /rest/api/foo/ (using the inherited cache timeout of 5)

client.bar.create({a:5});
// POST /rest/api/foo/ (using a cache timeout of 10 and will also stringify the POST data)

```

Show API Example
``` javascript
var client = new $.RestClient('/rest/api/');

client.add('foo');
client.add('bar');
client.foo.add('baz');

client.show();

// Console should say:
// ROOT: /rest/api/ 
//   foo: /rest/api/foo/:ID_1/ 
//     POST: create 
//     GET: read 
//     PUT: update 
//     DELETE: delete 
//     baz: /rest/api/foo/:ID_1/baz/:ID_2/ 
//       POST: create 
//       GET: read 
//       PUT: update 
//       DELETE: delete 
//   bar: /rest/api/bar/:ID_1/ 
//     POST: create 
//     GET: read 
//     PUT: update 
//     DELETE: delete 

```

Global/Singleton Example
``` javascript

$.client = new $.RestClient('/rest/api/');
$.client.add('foo');

```

Options
---

The base url to use for all requests

**url**: string (default `''` empty string)



Whether to run all data given through `JSON.stringify` (polyfill required for IE<=8)

**stringifyData**: boolean (default `false`)



When both username and password are provided. They will be base64 encoded using `btoa` (pollyfill required not non-webkit)

**username** and **password**: string (default `null`)


[jQuery's Ajax Options](http://api.jquery.com/jQuery.ajax/)

**dataType**: string (default `'json'`)

**processData**: boolean (default `true`)

**crossDomain**: boolean (default `false`)

**timeout**: number (default browser defined)


*Note: Want more options ? Open up a New Feature Issue above.*

Conceptual Overview
---

This plugin is made up nested 'Resource' classes. Resources contain options, child Resources and child Operations. Operations are functions that execute each the desired HTTP request.
Both `new $.RestClient` and `client.add` construct new instances of Resource, however the former will create a root Resource, whereas the latter will create child Resources.

Since each Resource can have it's own set of options, at instantiation time, options are inherited from parent Resources, allowing one default set of options with custom options on child Resources.

Todo
---
* CSRF
* Method Override Header
* Add Tests

Contributing
---
Issues and pull-requests welcome. To build: `cd *dir*` then `npm install` then `grunt`.

Change Log
---

v0.0.2

* Manually Tested

v0.0.1

* Alpha Version
