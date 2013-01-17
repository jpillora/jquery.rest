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
  t += " " while --n
  t

class Operation
  constructor: (name, type, parent) ->
    error "name required" unless name
    error "type required" unless type
    error "parent required" unless parent
    error "cannot add: '#{name}' as it already exists" if parent[name]

    custom = if operations[name] then "" else name
    self = ->
      {url, data} = @extractUrlData type, arguments
      @client.ajax type, url+custom, data
    self.isOperation = true
    self.type = type
    return self

#resource class - represents one set of crud ops
class Resource
  constructor: (@name, @parent) ->
    error "name required" unless @name
    error "parent required" unless @parent
    if @parent[@name]
      error "cannot add: '#{name}' as it already exists"

    if @parent instanceof RestClient
      @numParents = 0
      @client = @parent
    else
      @numParents = @parent.numParents + 1
      @client = @parent.client

    @urlNoId = @parent.url + "#{@name}/"
    @url = @urlNoId + ":ID_#{@numParents}/"
    $.each operations, $.proxy @add, @    

  add: (name, type) ->
    if type
      @[name] = new Operation name, type, @
    else
      @[name] = new Resource name, @
    null
  
  show: (d=0)->
    console.log(s(d)+@name+": "+@url) if @name
    $.each @, (name,value) ->
      console.log(s(d+1)+value.type+": " +name) if value.isOperation is true
    $.each @, (name,res) ->
      if name isnt "parent" and name isnt "client" and res instanceof Resource
        res.show(d+1)

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
        error "Invalid parameter: #{arg} (#{$.type(arg)}). Must be strings and one optional plain object."

    numIds = ids.length

    if name isnt 'create' and numIds is @numParents + 1
      url = @url
    else if (name isnt 'update' and name isnt 'delete') and numIds is @numParents
      url = @urlNoId
    else
      error "Invalid number of ID parameters provided (#{numIds})"

    for id, i in ids
      url = url.replace new RegExp("\/:ID_#{i}\/"), "/#{id}/"

    {url, data}


class RestClient extends Resource
  constructor: (urlOrOpts) ->
    if $.type(urlOrOpts) is 'string'
      @url = urlOrOpts
    else if $.isPlainObject(urlOrOpts)
      @opts = urlOrOpts
      @url = @opts.url
    @url = '' unless @url
    @url = '' unless @url
    @opts = {} unless @opts


  ajax: (type, url, data, headers = {})->
    error "type missing"  unless type
    error "url missing"  unless url
    # console.log type, url, data
    if @opts.username and @opts.password
      error "You need a polyfill for 'btoa' to use basic auth." unless window.btoa
      encoded = window.btoa @opts.username + ":" + @opts.password
      headers.Authorization = "Basic #{encoded}"

    if data and @opts.stringifyData
      error "You need a polyfill for 'JSON' to use stringify." unless window.JSON
      data = window.JSON.stringify data

    $.ajax {
      url
      type
      headers
      data
      processData: false
      dataType: "json"
    }
# Public API
$.RestClient = RestClient