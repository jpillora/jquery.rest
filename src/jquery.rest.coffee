'use strict'

#helpers
error = (msg) ->
  throw "ERROR: jquery.rest: #{msg}"

s = (n) ->

  t = ""; n *= 2;
  t += " " while (n--)>0
  t

encode64 = (s) ->
  error "You need a polyfill for 'btoa' to use basic auth." unless window.btoa
  window.btoa s

stringify = (obj) ->
  error "You need a polyfill for 'JSON' to use stringify." unless window.JSON
  window.JSON.stringify obj

inheritExtend = (a, b) ->
  F = () ->
  F.prototype = a
  $.extend true, new F(), b

#defaults
defaultOpts =
  url: ''
  cache: 0
  cachableTypes: ['GET']
  stringifyData: false
  password: null
  username: null
  verbs:
    'create' : 'POST'
    'read'   : 'GET'
    'update' : 'PUT'
    'delete' : 'DELETE'
  ajax:
    dataType: 'json'

#ajax cache with timeouts
class Cache
  constructor: (@parent) ->
    @c = {}
  valid: (date) ->
    diff = new Date().getTime() - date.getTime()
    return diff <= @parent.opts.cache*1000
  key: (obj) ->
    stringify obj
  get: (key) ->
    result = @c[key]
    unless result
      return 
    if @valid result.entry
      return result.data
    return
  put: (key, data) ->
    @c[key] =
      entry: new Date()
      data: data
  clear: (regexp) ->
    if regexp
      $.each @c, (k,v) =>
        delete @c[k] if k.match regexp
    else
      @c = {}

#represents one verb Create,Read,...
class Verb
  constructor: (data) ->
    {@name, type, @parent, @url} = data
    error "name required" unless @name
    error "type required" unless type
    error "parent required" unless @parent
    error "Cannot add Verb: '#{name}' already exists" if @parent[@name]

    @type = type.toUpperCase()
    @opts = inheritExtend @parent.opts, data
    @root = @parent.root
    @custom = !defaultOpts.verbs[@name]
    @call = $.proxy @call, @
    @call.instance = @

  call: ->
    #will execute in the context of the parent resource
    r = @parent.extractUrlData @type, arguments
    r.url += @url or @name if @custom
    @parent.ajax.call @, @type, r.url, r.data

  show: (d) ->
    console.log s(d) + @name + ": " + @type

#resource class - represents one set of crud ops
class Resource

  constructor: (data = {}) ->
    if data.parent
      @constructChild data
    else
      @constructRoot data

  constructRoot: (data = {}) ->
    if 'string' is $.type data
      @url = data
      data = {}
    @opts = inheritExtend defaultOpts, data
    @url = @opts.url unless @url
    @urlNoId = @url
    @cache = new Cache @
    @numParents = 0
    @root = @
    @name = data.name || 'ROOT'

  constructChild: (data) ->
    {@parent, @name} = data
    @error "Invalid parent"  unless @parent instanceof Resource
    @error "name required" unless @name
    @error "'#{name}' already exists" if @parent[@name]

    @root = @parent.root
    @opts = inheritExtend @parent.opts, data
    @numParents = @parent.numParents + 1
    @urlNoId = @parent.url + "#{data.url || @name}/"
    @url = @urlNoId + ":ID_#{@numParents}/"
    #add all verbs defined for this resource 
    $.each @.opts.verbs, $.proxy @addVerb, @
    @del = @delete if @delete


  add: (data) ->
    data = {name: data} if 'string' is $.type data
    error "Invalid data. Must be an object or string." unless $.isPlainObject data
    data.parent = @
    @[data.name] = new Resource data 

  addVerb: (data, type) ->
    return if type is null
    data = {name: data} if 'string' is $.type data
    error "Invalid data. Must be an object or string." unless $.isPlainObject data
    data.type = type if type
    data.parent = @
    @[data.name] = new Verb(data).call

  error: (msg) ->
    error "Cannot add Resource: " + msg
  
  show: (d=0)->
    error "Recurrsion Fail" if d > 15
    console.log(s(d)+@name+": "+@url) if @name
    $.each @, (name, fn) ->
      fn.instance.show(d+1) if fn.instance instanceof Verb and name isnt 'del'
    $.each @, (name,res) =>
      if name isnt "parent" and name isnt "root" and res instanceof Resource
        res.show(d+1)
    null

  toString: ->
    @name

  extractUrlData: (name, args) ->
    ids = []
    data = null
    for arg in args
      t = $.type(arg)
      if t is 'string' or t is 'number'
        ids.push(arg)
      else if $.isPlainObject(arg) and data is null
        data = arg 
      else
        error "Invalid parameter: #{arg} (#{t})." + 
              " Must be strings or ints (IDs) followed by one optional plain object (data)."

    numIds = ids.length

    canUrl = name isnt 'create'
    canUrlNoId = name isnt 'update' and name isnt 'delete'
    
    url = null
    url = @url if canUrl and numIds is @numParents
    url = @urlNoId if canUrlNoId and numIds is @numParents - 1
    
    if url is null
      msg = (@numParents - 1) if canUrlNoId
      msg = ((if msg then msg+' or ' else '') + @numParents) if canUrl
      error "Invalid number of ID parameters, required #{msg}, provided #{numIds}"

    for id, i in ids
      url = url.replace new RegExp("\/:ID_#{i+1}\/"), "/#{id}/"

    {url, data}

  ajax: (type, url, data, headers = {})->
    error "type missing"  unless type
    error "url missing"  unless url
    # console.log type, url, data
    if @opts.username and @opts.password
      encoded = encode64 @opts.username + ":" + @opts.password
      headers.Authorization = "Basic #{encoded}"

    if data and @opts.stringifyData
      data = stringify data

    ajaxOpts = { url, type, headers }
    ajaxOpts.data = data if data
    #add this verb's/resource's defaults
    ajaxOpts = $.extend true, {}, @opts.ajax, ajaxOpts 

    useCache = @opts.cache and $.inArray(type, @opts.cachableTypes) >= 0

    if useCache
      key = @root.cache.key ajaxOpts
      req = @root.cache.get key
      return req if req

    req = $.ajax ajaxOpts

    if useCache
      req.complete =>
        @root.cache.put key, req

    return req

# Public API
Resource.defaults = defaultOpts

$.RestClient = Resource