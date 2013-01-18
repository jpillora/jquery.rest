(function() {
  'use strict';

  var Cache, Operation, Resource, defaultOpts, encode64, error, inheritExtend, operations, s, stringify;

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

  inheritExtend = function(a, b) {
    var F;
    F = function() {};
    F.prototype = a;
    return $.extend(new F(), b);
  };

  defaultOpts = {
    url: '',
    cache: 0,
    cacheTypes: ['GET'],
    stringifyData: false,
    dataType: 'json',
    disablePut: false,
    processData: true,
    crossDomain: false,
    timeout: null,
    username: null,
    password: null
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
    };

    Cache.prototype.put = function(key, data) {
      return this.c[key] = {
        entry: new Date(),
        data: data
      };
    };

    Cache.prototype.clear = function(regexp) {
      var _this = this;
      if (regexp) {
        return $.each(this.c, function(k, v) {
          if (k.match(regexp)) {
            return delete _this.c[k];
          }
        });
      } else {
        return this.c = {};
      }
    };

    return Cache;

  })();

  Operation = (function() {

    function Operation(data) {
      var custom, fn, name, parent, type;
      name = data.name, type = data.type, parent = data.parent;
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
        error("Cannot add Operation: '" + name + "' already exists");
      }
      custom = !operations[name];
      type = type.toUpperCase();
      fn = function() {
        var r;
        r = this.extractUrlData(type, arguments);
        if (custom) {
          r.url += data.url || name;
        }
        return this.ajax.call(fn, type, r.url, r.data);
      };
      fn.isOperation = true;
      fn.type = type;
      fn.root = parent.root;
      fn.opts = inheritExtend(parent.opts, data);
      return fn;
    }

    return Operation;

  })();

  Resource = (function() {

    function Resource(data) {
      if (data == null) {
        data = {};
      }
      if (data.parent) {
        this.constructChild(data);
      } else {
        this.constructRoot(data);
      }
    }

    Resource.prototype.add = function(data, type) {
      if ('string' === $.type(data)) {
        data = {
          name: data
        };
      }
      if (!$.isPlainObject(data)) {
        error("Invalid data. Must be an object or string.");
      }
      if (type) {
        data.type = type;
      }
      data.parent = this;
      return this[data.name] = data.type ? new Operation(data) : new Resource(data);
    };

    Resource.prototype.constructRoot = function(data) {
      if (data == null) {
        data = {};
      }
      if ('string' === $.type(data)) {
        this.url = data;
        data = {};
      }
      this.opts = inheritExtend(defaultOpts, data);
      if (!this.url) {
        this.url = this.opts.url;
      }
      this.urlNoId = this.url;
      this.cache = new Cache(this);
      this.numParents = 0;
      this.root = this;
      return this.name = data.name || 'ROOT';
    };

    Resource.prototype.constructChild = function(data) {
      this.parent = data.parent, this.name = data.name;
      if (!(this.parent instanceof Resource)) {
        this.error("Invalid parent");
      }
      if (!this.name) {
        this.error("name required");
      }
      if (this.parent[this.name]) {
        this.error("'" + name + "' already exists");
      }
      this.root = this.parent.root;
      this.opts = inheritExtend(this.parent.opts, data);
      this.numParents = this.parent.numParents + 1;
      this.urlNoId = this.parent.url + ("" + (data.url || this.name) + "/");
      this.url = this.urlNoId + (":ID_" + this.numParents + "/");
      $.each(operations, $.proxy(this.add, this));
      return this.del = this["delete"];
    };

    Resource.prototype.error = function(msg) {
      return error("Cannot add Resource: " + msg);
    };

    Resource.prototype.show = function(d) {
      var _this = this;
      if (d == null) {
        d = 0;
      }
      if (d > 15) {
        error("Recurrsion Fail");
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
        if (name !== "parent" && name !== "root" && res instanceof Resource) {
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
      url = null;
      if (canUrl && numIds === this.numParents) {
        url = this.url;
      }
      if (canUrlNoId && numIds === this.numParents - 1) {
        url = this.urlNoId;
      }
      if (url === null) {
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
      var ajaxOpts, encoded, key, req, useCache,
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
      if (type === 'PUT' && this.opts.disablePut) {
        type = 'POST';
      }
      ajaxOpts = {
        url: url,
        type: type,
        headers: headers,
        data: data,
        timeout: this.opts.timeout,
        crossDomain: this.opts.crossDomain,
        processData: this.opts.processData,
        dataType: this.opts.dataType
      };
      useCache = this.opts.cache && this.opts.cacheTypes.indexOf(type) >= 0;
      if (useCache) {
        key = this.root.cache.key(ajaxOpts);
        req = this.root.cache.get(key);
        if (req) {
          return req;
        }
      }
      req = $.ajax(ajaxOpts);
      if (useCache) {
        req.complete(function() {
          return _this.root.cache.put(key, req);
        });
      }
      return req;
    };

    return Resource;

  })();

  $.RestClient = Resource;

}).call(this);
