/*! jQuery REST Client - v0.0.1 - 2013-01-18
* https://github.com/jpillora/jquery.rest
* Copyright (c) 2013 Jaime Pillora; Licensed MIT */

(function() {
  'use strict';

  var Operation, Resource, RestClient, error, operations, s,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

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
    while (--n) {
      t += " ";
    }
    return t;
  };

  Operation = (function() {

    function Operation(name, type, parent) {
      var self;
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
      type = type.toUpperCase();
      self = function() {
        var data, url, _ref;
        _ref = this.extractUrlData(type, arguments), url = _ref.url, data = _ref.data;
        return this.client.ajax(type, url + custom, data);
      };
      self.isOperation = true;
      self.type = type;
      return self;
    }

    return Operation;

  })();

  Resource = (function() {

    function Resource(name, parent) {
      this.name = name;
      this.parent = parent;
      if (!this.name) {
        error("name required");
      }
      if (!this.parent) {
        error("parent required");
      }
      if (this.parent[this.name]) {
        error("cannot add: '" + name + "' as it already exists");
      }
      if (this.parent instanceof RestClient) {
        this.numParents = 0;
        this.client = this.parent;
      } else {
        this.numParents = this.parent.numParents + 1;
        this.client = this.parent.client;
      }
      this.urlNoId = this.parent.url + ("" + this.name + "/");
      this.url = this.urlNoId + (":ID_" + this.numParents + "/");
      $.each(operations, $.proxy(this.add, this));
    }

    Resource.prototype.add = function(name, type) {
      if (type) {
        this[name] = new Operation(name, type, this);
      } else {
        this[name] = new Resource(name, this);
      }
      return null;
    };

    Resource.prototype.show = function(d) {
      if (d == null) {
        d = 0;
      }
      if (this.name) {
        console.log(s(d) + this.name + ": " + this.url);
      }
      $.each(this, function(name, value) {
        if (value.isOperation === true) {
          return console.log(s(d + 1) + value.type + ": " + name);
        }
      });
      return $.each(this, function(name, res) {
        if (name !== "parent" && name !== "client" && res instanceof Resource) {
          return res.show(d + 1);
        }
      });
    };

    Resource.prototype.toString = function() {
      return this.name;
    };

    Resource.prototype.extractUrlData = function(name, args) {
      var arg, data, i, id, ids, numIds, url, _i, _j, _len, _len1;
      ids = [];
      data = null;
      for (_i = 0, _len = args.length; _i < _len; _i++) {
        arg = args[_i];
        if ($.type(arg) === 'string') {
          ids.push(arg);
        } else if ($.isPlainObject(arg) && data === null) {
          data = arg;
        } else {
          error("Invalid parameter: " + arg + " (" + ($.type(arg)) + "). Must be strings and one optional plain object.");
        }
      }
      numIds = ids.length;
      if (name !== 'create' && numIds === this.numParents + 1) {
        url = this.url;
      } else if ((name !== 'update' && name !== 'delete') && numIds === this.numParents) {
        url = this.urlNoId;
      } else {
        error("Invalid number of ID parameters provided (" + numIds + ")");
      }
      for (i = _j = 0, _len1 = ids.length; _j < _len1; i = ++_j) {
        id = ids[i];
        url = url.replace(new RegExp("\/:ID_" + i + "\/"), "/" + id + "/");
      }
      return {
        url: url,
        data: data
      };
    };

    return Resource;

  })();

  RestClient = (function(_super) {

    __extends(RestClient, _super);

    function RestClient(urlOrOpts) {
      if ($.type(urlOrOpts) === 'string') {
        this.url = urlOrOpts;
      } else if ($.isPlainObject(urlOrOpts)) {
        this.opts = urlOrOpts;
        this.url = this.opts.url;
      }
      if (!this.url) {
        this.url = '';
      }
      if (!this.url) {
        this.url = '';
      }
      if (!this.opts) {
        this.opts = {};
      }
    }

    RestClient.prototype.ajax = function(type, url, data, headers) {
      var encoded;
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
        if (!window.btoa) {
          error("You need a polyfill for 'btoa' to use basic auth.");
        }
        encoded = window.btoa(this.opts.username + ":" + this.opts.password);
        headers.Authorization = "Basic " + encoded;
      }
      if (data && this.opts.stringifyData) {
        if (!window.JSON) {
          error("You need a polyfill for 'JSON' to use stringify.");
        }
        data = window.JSON.stringify(data);
      }
      return $.ajax({
        url: url,
        type: type,
        headers: headers,
        data: data,
        processData: false,
        dataType: "json"
      });
    };

    return RestClient;

  })(Resource);

  $.RestClient = RestClient;

}).call(this);
