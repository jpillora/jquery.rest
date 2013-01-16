(function() {
  'use strict';

  var Resource, RestClient, error, operations;

  error = function(msg) {
    throw "ERROR: jquery.rest: " + msg;
  };

  operations = {
    'create': 'POST',
    'read': 'GET',
    'update': 'PUT',
    'delete': 'DELETE'
  };

  Resource = (function() {

    function Resource(name, parent) {
      var _this = this;
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
      $.each(operations, function(op, type) {
        return _this[op] = function() {
          var data, url, _ref;
          _ref = this.extractUrlData(type, arguments), url = _ref.url, data = _ref.data;
          return this.client.ajax(type, url, data);
        };
      });
    }

    Resource.prototype.add = function(name) {
      return this[name] = new Resource(name, this);
    };

    Resource.prototype.show = function() {
      console.log("" + this.name + ": " + this.url);
      return $.each(this, function(name, res) {
        if (name !== "parent" && res instanceof Resource) {
          return res.show();
        }
      });
    };

    Resource.prototype.toString = function() {
      return this.name;
    };

    Resource.prototype.extractUrlData = function(type, args) {
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
      if (type !== 'POST' && numIds === this.numParents + 1) {
        url = this.url;
      } else if ((type === 'GET' || type === 'POST') && numIds === this.numParents) {
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

  RestClient = (function() {

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
      if (!this.opts) {
        this.opts = {};
      }
    }

    RestClient.prototype.add = function(name) {
      return this[name] = new Resource(name, this);
    };

    RestClient.prototype.remove = function(name) {
      return delete this[name];
    };

    RestClient.prototype.show = function() {
      return $.each(this, function(name, res) {
        if (res instanceof Resource) {
          return res.show();
        }
      });
    };

    RestClient.prototype.ajax = function(type, url, data, headers) {
      var encoded;
      if (data == null) {
        data = {};
      }
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
      return $.ajax({
        url: url,
        type: type,
        headers: headers,
        data: data,
        dataType: "json"
      });
    };

    return RestClient;

  })();

  $.RestClient = RestClient;

}).call(this);
