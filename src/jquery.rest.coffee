'use strict'

#helpers
error = (msg) ->
  throw "ERROR: jquery.rest: #{msg}"

operations =
  'create' : 'POST'
  'read'   : 'GET'
  'update' : 'PUT'
  'delete' : 'DELETE'

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

    #build operations
    $.each operations, (op, type) =>
      @[op] = ->
        {url, data} = @extractUrlData type, arguments
        @client.ajax type, url, data

  add: (name) ->
    @[name] = new Resource name, @
  
  show: ()->
    console.log "#{@name}: #{@url}"
    $.each @, (name,res) ->
      if name isnt "parent" and res instanceof Resource
        res.show()

  toString: -> @name

  extractUrlData: (type, args) ->
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

    if type isnt 'POST' and numIds is @numParents + 1
      url = @url
    else if (type is 'GET' or type is 'POST') and numIds is @numParents
      url = @urlNoId
    else
      error "Invalid number of ID parameters provided (#{numIds})"

    for id, i in ids
      url = url.replace new RegExp("\/:ID_#{i}\/"), "/#{id}/"

    {url, data}

class RestClient
  constructor: (urlOrOpts) ->
    if $.type(urlOrOpts) is 'string'
      @url = urlOrOpts
    else if $.isPlainObject(urlOrOpts)
      @opts = urlOrOpts
      @url = @opts.url
    @url = '' unless @url

  add: (name) -> @[name] = new Resource name, @
  remove: (name) -> delete @[name]
  show: ->
    $.each @, (name,res) ->
      res.show() if res instanceof Resource
  ajax: (type, url, data = {}, headers = {})->
    throw "type missing"  unless type
    throw "url missing"  unless url
    # console.log type, url, data
    if @username and @password
      throw "You need a polyfill for 'btoa' to use basic auth." unless window.btoa
      headers.Authorize = window.btoa @username + ":" + @password

    $.ajax {
      url
      type
      headers
      data
      dataType: "json"
    }

# Public API
$.RestClient = RestClient