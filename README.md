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

Basic API
``` javascript
var client = new $.RestClient('/rest/api/');

client.add('foo');

client.foo.read();
// GET /rest/api/foo/
client.foo.read(42);
// GET /rest/api/foo/42/
```

Retrieving Results (Uses [jQuery's $.Deferred](http://api.jquery.com/category/deferred-object/))
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


More Examples
---

##### Nested Resources
``` javascript

var client = new $.RestClient('/rest/api/');

client.add('foo');
client.foo.add('baz');

client.foo.read();
// GET /rest/api/foo/
client.foo.read(42);
// GET /rest/api/foo/42/

client.foo.baz.read();
// GET /rest/api/foo/{ID Placeholder}/baz/
// ERROR ! Invalid number of arguments
client.foo.baz.read(42);
// GET /rest/api/foo/42/baz/
client.foo.baz.read(42,21);
// GET /rest/api/foo/42/baz/21/

```


##### Basic CRUD Verbs
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
client.foo.read(42);

// U
client.foo.update(42, {my:"updates"});
// PUT /rest/api/42/   my=updates

// D
client.foo.delete(42);
client.foo.del(42); // if JSLint is complaining...
```

##### Adding Custom Verbs
``` javascript

var client = new $.RestClient('/rest/api/');

client.add('foo');
client.foo.addVerb('bang', 'PATCH');

client.foo.patch({my:"data"});
//PATCH /foo/bang/   my=data
client.foo.patch(42,{my:"data"});
//PATCH /foo/42/bang/   my=data
```

##### Basic Authentication
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

##### Caching
``` javascript
var client = new $.RestClient({
  url: '/rest/api/',
  cache: 5 //This will cache requests for 5 seconds
  cachableTypes: ["GET"] //This defines what method types can be cached (this is already set by default)
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

##### Override Options
``` javascript

var client = new $.RestClient();

client.add({
  name: 'foo',
  stringifyData: true,
  cache: 5
});

client.foo.add({
  name: 'bar',
  cache: 10,
});

client.foo.create({a:1});
// POST /foo/ (stringifies data and uses a cache timeout of 5)

client.bar.create(42,{a:2});
// POST /foo/42/bar/ (still stringifies data though now uses a cache timeout of 10)

```

##### Show API Example
``` javascript
var client = new $.RestClient('/rest/api/');

client.add('foo');
client.add('bar');
client.foo.add('baz');

client.show();

```
Console should say:
```
ROOT: /rest/api/
  foo: /rest/api/foo/:ID_1/
    create: POST
    read: GET
    update: PUT
    delete: DELETE
    baz: /rest/api/foo/:ID_1/baz/:ID_2/
      create: POST
      read: GET
      update: PUT
      delete: DELETE
  bar: /rest/api/bar/:ID_1/
    create: POST
    read: GET
    update: PUT
    delete: DELETE 
```


##### Global/Singleton Example
``` javascript

$.client = new $.RestClient('/rest/api/');

// in another file...

$.client.add('foo');

// Note: not great practise though, use RequireJS !

```

API
---

Note: This API is subject to change.

#### new $.RestClient( ... )

Instaniates a new resource:

* `options` is an options object.
* `url` is a string representing the base url for all resources.

#### `client`.add( ... )

Instaniates a new nested resource on `client`:

* `options` is an options object. *Must* contain a `name` property.
* `name` is a string representing the name for this resource.

Newly created nested resources iterate through their `options.verbs` and addVerb on each (Note: the URL will always be blank for these verbs, essentially using the `client`s url, though with differing HTTP method types).

#### `client`.addVerb( ... )

Instaniates a new verb on `client`:

* `options` is an options object. *Must* contain a `name` and `type` property.
* `name`, `type` strings representing the name for this verb and type is the HTTP method type used.

Newly created verbs are functions on the `client`.

Options
---

All of the `options` arguments mentioned above are all the same except extra properties must be provided for required arguments.

*Important*: All classes inherit their parent's options !

See defaults [here](https://github.com/jpillora/jquery.rest/blob/gh-pages/src/jquery.rest.coffee#L26)

#### cache

A number reprenting the number of seconds to used previously cached requests. When set to `0`, no requests are stored.

### cachableTypes

An array of strings reprenting the HTTP method types that can be cached. Is only "GET" by default. 

#### verbs

A plain object used as a *name* to *HTTP method type* mapping

The base url to use for all requests

E.g. to change update from a PUT to a POST, set `verbs` to `{ update: "POST" }`

### url

A string representing the URL for the given resource or verb.

Note: for nested resources and verbs, the name is used as the url though if this option is set, this default behaviour will be overriden.

### stringifyData

When set, will pass all POST data through `JSON.stringify` (polyfill required for IE<=8).

### username and password

When both username and password are set, all ajax requests will add an 'Authorization' header. Encoded using `btoa` (pollyfill required not non-webkit).

### ajax

It is [jQuery's Ajax Options](http://api.jquery.com/jQuery.ajax/)

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
