(function() {
  'use strict';

  var Cache, Operation, Resource, encode64, error, operations, s, stringify;

  error = function(msg) {
    throw "ERROR: jquery.rest: " + msg;
  };

  operations = {
    'create': 'POST',
    'read': 'GET',
    'update': 'PUT',
    'delete': 'DELETE'
  };

  s = function(n) {
    var t;
    t = "";
    n *= 2;
    while ((n--) > 0) {
      t += " ";
    }
    return t;
  };

  encode64 = function(s) {
    if (!window.btoa) {
      error("You need a polyfill for 'btoa' to use basic auth.");
    }
    return window.btoa(s);
  };

  stringify = function(obj) {
    if (!window.JSON) {
      error("You need a polyfill for 'JSON' to use stringify.");
    }
    return window.JSON.stringify(obj);
  };

  Cache = (function() {

    function Cache(parent) {
      this.parent = parent;
      this.c = {};
    }

    Cache.prototype.valid = function(date) {
      var diff;
      diff = new Date().getTime() - date.getTime();
      return diff <= this.parent.opts.cache * 1000;
    };

    Cache.prototype.key = function(obj) {
      return stringify(obj);
    };

    Cache.prototype.get = function(key) {
      var result;
      result = this.c[key];
      if (!result) {
        return;
      }
      if (this.valid(result.entry)) {
        return result.data;
      }
      this.c[key] = null;
    };

    Cache.prototype.put = function(key, data) {
      return this.c[key] = {
        entry: new Date(),
        data: data
      };
    };

    return Cache;

  })();

  Operation = (function() {

    function Operation(name, type, parent) {
      var custom, self;
      if (!name) {
        error("name required");
      }
      if (!type) {
        error("type required");
      }
      if (!parent) {
        error("parent required");
      }
      if (parent[name]) {
        error("cannot add: '" + name + "' as it already exists");
      }
      custom = !operations[name];
      type = type.toUpperCase();
      self = function() {
        var data, url, _ref;
        _ref = this.extractUrlData(type, arguments), url = _ref.url, data = _ref.data;
        return this.ajax(type, url + (custom ? name : ""), data);
      };
      self.isOperation = true;
      self.type = type;
      return self;
    }

    return Operation;

  })();

  Resource = (function() {

    function Resource(data, parent) {
      if (parent) {
        this.constructChild(data, parent);
      } else {
        this.constructRoot(data);
      }
    }

    Resource.prototype.constructRoot = function(data) {
      if ($.type(data) === 'string') {
        this.url = data;
      } else if ($.isPlainObject(data)) {
        $.extend(this.opts, data);
      }
      if (!this.url) {
        this.url = this.opts.url;
      }
      this.urlNoId = this.url;
      this.cache = new Cache(this);
      this.numParents = 0;
      this.root = this;
      return this.name = 'ROOT';
    };

    Resource.prototype.constructChild = function(name, parent) {
      if (!(parent instanceof Resource)) {
        error("invalid parent");
      }
      if (!name) {
        error("name required");
      }
      if ($.type(name) !== 'string') {
        error("name must be string");
      }
      if (parent[name]) {
        error("cannot add: '" + name + "' as it already exists");
      }
      this.root = parent.root;
      this.opts = this.root.opts;
      this.name = name;
      this.numParents = parent.numParents + 1;
      this.urlNoId = parent.url + ("" + this.name + "/");
      this.url = this.urlNoId + (":ID_" + this.numParents + "/");
      $.each(operations, $.proxy(this.add, this));
      return this.del = this["delete"];
    };

    Resource.prototype.opts = {
      url: '',
      cache: 0,
      stringifyData: false,
      username: null,
      password: null
    };

    Resource.prototype.add = function(name, type) {
      if (type) {
        this[name] = new Operation(name, type, this);
      } else {
        this[name] = new Resource(name, this);
      }
      return null;
    };

    Resource.prototype.show = function(d) {
      var _this = this;
      if (d == null) {
        d = 0;
      }
      if (this.name) {
        console.log(s(d) + this.name + ": " + this.url);
      }
      $.each(this, function(name, value) {
        if (value.isOperation === true && name !== 'del') {
          return console.log(s(d + 1) + value.type + ": " + name);
        }
      });
      $.each(this, function(name, res) {
        if (res !== "parent" && name !== "root" && res instanceof Resource) {
          return res.show(d + 1);
        }
      });
      return null;
    };

    Resource.prototype.toString = function() {
      return this.name;
    };

    Resource.prototype.extractUrlData = function(name, args) {
      var arg, canUrl, canUrlNoId, data, i, id, ids, msg, numIds, url, _i, _j, _len, _len1;
      ids = [];
      data = null;
      for (_i = 0, _len = args.length; _i < _len; _i++) {
        arg = args[_i];
        if ($.type(arg) === 'string') {
          ids.push(arg);
        } else if ($.isPlainObject(arg) && data === null) {
          data = arg;
        } else {
          error(("Invalid parameter: " + arg + " (" + ($.type(arg)) + ").") + " Must be strings (IDs) and one optional plain object (data).");
        }
      }
      numIds = ids.length;
      canUrl = name !== 'create';
      canUrlNoId = name !== 'update' && name !== 'delete';
      if (canUrl && numIds === this.numParents) {
        url = this.url;
      }
      if (canUrlNoId && numIds === this.numParents - 1) {
        url = this.urlNoId;
      }
      if (!url) {
        if (canUrlNoId) {
          msg = this.numParents - 1;
        }
        if (canUrl) {
          msg = (msg ? msg + ' or ' : '') + this.numParents;
        }
        error("Invalid number of ID parameters, required " + msg + ", provided " + numIds);
      }
      for (i = _j = 0, _len1 = ids.length; _j < _len1; i = ++_j) {
        id = ids[i];
        url = url.replace(new RegExp("\/:ID_" + (i + 1) + "\/"), "/" + id + "/");
      }
      return {
        url: url,
        data: data
      };
    };

    Resource.prototype.ajax = function(type, url, data, headers) {
      var ajaxOpts, encoded, key, req,
        _this = this;
      if (headers == null) {
        headers = {};
      }
      if (!type) {
        error("type missing");
      }
      if (!url) {
        error("url missing");
      }
      if (this.opts.username && this.opts.password) {
        encoded = encode64(this.opts.username + ":" + this.opts.password);
        headers.Authorization = "Basic " + encoded;
      }
      if (data && this.opts.stringifyData) {
        data = stringify(data);
      }
      ajaxOpts = {
        url: url,
        type: type,
        headers: headers,
        data: data,
        processData: false,
        dataType: "json"
      };
      if (this.opts.cache) {
        key = this.cache.key(ajaxOpts);
        req = this.cache.get(key);
        if (req) {
          return req;
        }
      }
      req = $.ajax(ajaxOpts);
      if (this.opts.cache) {
        req.complete(function() {
          return _this.cache.put(key, req);
        });
      }
      return req;
    };

    return Resource;

  })();

  $.RestClient = Resource;

}).call(this);
