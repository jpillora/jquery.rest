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
    @c[key] = null
    return
  put: (key, data) ->
    @c[key] =
      entry: new Date()
      data: data


#represents one operation Create,Read,...
class Operation
  constructor: (name, type, parent) ->
    error "name required" unless name
    error "type required" unless type
    error "parent required" unless parent
    error "cannot add: '#{name}' as it already exists" if parent[name]
    custom = !operations[name] 
    type = type.toUpperCase()
    self = ->
      {url, data} = @extractUrlData type, arguments
      @ajax type, url+(if custom then name else ""), data
    self.isOperation = true
    self.type = type
    return self

#resource class - represents one set of crud ops
class Resource

  constructor: (data, parent) ->
    if parent
      @constructChild data, parent
    else
      @constructRoot data

  constructRoot: (data) ->
    if $.type(data) is 'string'
      @url = data
    else if $.isPlainObject(data)
      $.extend @opts, data
    @url = @opts.url unless @url
    @urlNoId = @url
    @cache = new Cache @
    @numParents = 0
    @root = @
    @name = 'ROOT'

  constructChild: (name, parent) ->
    error "invalid parent"  unless parent instanceof Resource
    error "name required" unless name
    error "name must be string" unless $.type(name) is 'string'
    error "cannot add: '#{name}' as it already exists" if parent[name]

    @root = parent.root
    @opts = @root.opts
    @name = name

    @numParents = parent.numParents + 1

    @urlNoId = parent.url + "#{@name}/"
    @url = @urlNoId + ":ID_#{@numParents}/"
    #add all standard operations to each 
    $.each operations, $.proxy @add, @
    @del = @delete

  #defaults
  opts:
    url: ''
    cache: 0
    stringifyData: false
    dataType: 'json'
    processData: true
    crossDomain: false
    timeout: null
    username: null
    password: null

  add: (name, type) ->
    if type
      @[name] = new Operation name, type, @
    else
      @[name] = new Resource name, @
    null
  
  show: (d=0)->
    console.log(s(d)+@name+": "+@url) if @name
    $.each @, (name,value) ->
      console.log(s(d+1)+value.type+": " +name) if value.isOperation is true and name isnt 'del'
    $.each @, (name,res) =>
      if res isnt "parent" and name isnt "root" and res instanceof Resource
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
      key = @cache.key ajaxOpts
      req = @cache.get key
      return req if req

    req = $.ajax ajaxOpts

    if @opts.cache
      req.complete =>
        @cache.put key, req

    return req

# Public API
$.RestClient = Resource