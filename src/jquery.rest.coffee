'use strict'

#helpers
error = (msg) ->
  throw "ERROR: jquery.rest: #{msg}"

operations =
  'create' : 'POST'
  'read'   : 'GET'
  'update' : 'PUT'
  'delete' : 'DELETE'

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
  $.extend new F(), b

#defaults
defaultOpts =
  url: ''
  cache: 0
  cacheTypes: ['GET']
  stringifyData: false
  dataType: 'json'
  disablePut: false
  processData: true
  crossDomain: false
  timeout: null
  username: null
  password: null

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

#represents one operation Create,Read,...
class Operation
  constructor: (data) ->
    {name, type, parent} = data
    error "name required" unless name
    error "type required" unless type
    error "parent required" unless parent
    error "Cannot add Operation: '#{name}' already exists" if parent[name]

    custom = !operations[name] 
    type = type.toUpperCase()

    fn = ->
      r = @extractUrlData type, arguments
      r.url += data.url or name if custom
      @ajax.call fn, type, r.url, r.data

    fn.isOperation = true
    fn.type = type
    fn.root = parent.root
    fn.opts = inheritExtend parent.opts, data

    return fn

#resource class - represents one set of crud ops
class Resource

  constructor: (data = {}) ->
    if data.parent
      @constructChild data
    else
      @constructRoot data

  add: (data, type) ->
    data = {name: data} if 'string' is $.type data
    error "Invalid data. Must be an object or string." unless $.isPlainObject data
    data.type = type if type
    data.parent = @
    @[data.name] = if data.type then new Operation(data) else new Resource(data) 

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
    #add all standard CRUD operations 
    $.each operations, $.proxy @add, @
    @del = @delete

  error: (msg) ->
    error "Cannot add Resource: " + msg
  
  show: (d=0)->
    error "Recurrsion Fail" if d > 15
    console.log(s(d)+@name+": "+@url) if @name
    $.each @, (name,value) ->
      console.log(s(d+1)+value.type+": " +name) if value.isOperation is true and name isnt 'del'
    $.each @, (name,res) =>
      if name isnt "parent" and name isnt "root" and res instanceof Resource
        res.show(d+1)
    null

  toString: -> @name

  extractUrlData: (name, args) ->
    ids = []
    data = null
    for arg in args
      if $.type(arg) is 'string'
        ids.push(arg)
      else if $.isPlainObject(arg) and data is null
        data = arg 
      else
        error "Invalid parameter: #{arg} (#{$.type(arg)})." + 
              " Must be strings (IDs) and one optional plain object (data)."

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

    if type is 'PUT' and @opts.disablePut
      type = 'POST'

    ajaxOpts = {
      url
      type
      headers
      data
      timeout: @opts.timeout
      crossDomain: @opts.crossDomain
      processData: @opts.processData
      dataType: @opts.dataType
    }

    useCache = @opts.cache and @opts.cacheTypes.indexOf(type) >= 0

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
$.RestClient = Resource