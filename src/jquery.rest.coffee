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

getNameData = (data) ->
  if $.isPlainObject data
    name = data.name or data.url
  else if 'string' is $.type data
    name = data
    data = null
  else
    error "Invalid data. Must be an object or string."
  { data, name }

#defaults
defaultOpts =
  url: ''
  cache: 0
  stringifyData: false
  dataType: 'json'
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
  flush: (key) ->
    if key then @c[key] = null else @c = {}

#represents one operation Create,Read,...
class Operation
  constructor: (name, type, parent) ->
    error "name required" unless name
    error "type required" unless type
    error "parent required" unless parent
    error "Cannot add Operation: '#{name}' already exists" if parent[name]
    custom = !operations[name] 
    type = type.toUpperCase()
    ajax = ->
      {url, data} = @extractUrlData type, arguments
      @ajax type, url+(if custom then name else ""), data
    ajax.isOperation = true
    ajax.type = type
    return ajax

#resource class - represents one set of crud ops
class Resource

  constructor: (data, parent) ->
    if parent
      @constructChild data, parent
    else
      @constructRoot data

  constructRoot: (data = '') ->
    {name, data} = getNameData data
    @url = name
    data = data or {}
    @opts = inheritExtend defaultOpts, data
    @url = @opts.url unless @url
    @urlNoId = @url
    @cache = new Cache @
    @numParents = 0
    @root = @
    @name = 'ROOT'

  constructChild: (data, parent) ->
    error "Invalid parent"  unless parent instanceof Resource
    {name, data} = getNameData data
    error "name required" unless name
    data = data or {}
    error "Cannot add Resource: '#{name}' already exists" if parent[name]

    @parent = parent
    @root = parent.root
    @opts = inheritExtend parent.opts, data
    @name = name
    @numParents = parent.numParents + 1
    @urlNoId = parent.url + "#{@name}/"
    @url = @urlNoId + ":ID_#{@numParents}/"
    #add all standard CRUD operations 
    $.each operations, $.proxy @add, @
    @del = @delete

  add: (data, type) ->
    {name, data} = getNameData data

    if type
      @[name] = new Operation name, type, @
    else
      @[name] = new Resource data or name, @
    null
  
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

    if @opts.cache
      key = @root.cache.key ajaxOpts
      req = @root.cache.get key
      return req if req

    req = $.ajax ajaxOpts

    if @opts.cache
      req.complete =>
        @root.cache.put key, req

    return req

# Public API
$.RestClient = Resource