get = Ember.get
set = Ember.set
getPath = Ember.getPath
DS.WebSocketAdapter = DS.Adapter.extend(
  DEFAULT_OPTIONS =
    protocol: 'ws'
    host: '0.0.0.0'
    port: 7070

  config: (@url) ->
    if WebSocket?
      @socket = new WebSocket(@url)    
    else
      @socket = new MozWebSocket(@url)
      
    @socket.onopen = ->
      @initMessage
    
    @socket.onmessage = (message) =>
      @process_response(message) if message
  
  initMessage: ->
    # Send something to the server to start
  
  send: (hash) ->
    @socket.send(JSON.stringify(hash))
  
  createRecord: (store, type, model) ->
    root = @rootForType(type)
    data = 
      root: get(model, "data")
      action: "create"
      model: model
    @send data
  
  recordWasCreated: (json) ->
    @sideload store, type, json, root
    store.didCreateRecord model, json[root]

  createRecords: (store, type, models) ->
    return @_super(store, type, models)  if get(this, "bulkCommit") is false
    root = @rootForType(type)
    plural = @pluralize(root)
    data = {}
    data[plural] = models.map((model) ->
      get model, "data"
    )
    @ajax "/" + @pluralize(root), "POST",
      data: data
      success: (json) ->
        @sideload store, type, json, plural
        store.didCreateRecords type, models, json[plural]

  updateRecord: (store, type, model) ->
    id = get(model, "id")
    root = @rootForType(type)
    data = {}
    data[root] = get(model, "data")
    url = [ "", @pluralize(root), id ].join("/")
    @ajax url, "PUT",
      data: data
      success: (json) ->
        @sideload store, type, json, root
        store.didUpdateRecord model, json[root]

  updateRecords: (store, type, models) ->
    return @_super(store, type, models)  if get(this, "bulkCommit") is false
    root = @rootForType(type)
    plural = @pluralize(root)
    data = {}
    data[plural] = models.map((model) ->
      get model, "data"
    )
    @ajax "/" + @pluralize(root) + "/bulk", "PUT",
      data: data
      success: (json) ->
        @sideload store, type, json, plural
        store.didUpdateRecords models, json[plural]

  deleteRecord: (store, type, model) ->
    id = get(model, "id")
    root = @rootForType(type)
    url = [ "", @pluralize(root), id ].join("/")
    @ajax url, "DELETE",
      success: (json) ->
        @sideload store, type, json  if json
        store.didDeleteRecord model

  deleteRecords: (store, type, models) ->
    return @_super(store, type, models)  if get(this, "bulkCommit") is false
    root = @rootForType(type)
    plural = @pluralize(root)
    data = {}
    data[plural] = models.map((model) ->
      get model, "id"
    )
    @ajax "/" + @pluralize(root) + "/bulk", "DELETE",
      data: data
      success: (json) ->
        @sideload store, type, json  if json
        store.didDeleteRecords models

  find: (store, type, id) ->
    root = @rootForType(type)
    url = [ "", @pluralize(root), id ].join("/")
    @ajax url, "GET",
      success: (json) ->
        store.load type, json[root]
        @sideload store, type, json, root

  findMany: (store, type, ids) ->
    root = @rootForType(type)
    plural = @pluralize(root)
    @ajax "/" + plural, "GET",
      data:
        ids: ids

      success: (json) ->
        store.loadMany type, ids, json[plural]
        @sideload store, type, json, plural

  findAll: (store, type) ->
    root = @rootForType(type)
    plural = @pluralize(root)
    @ajax "/" + plural, "GET",
      success: (json) ->
        store.loadMany type, json[plural]
        @sideload store, type, json, plural

  findQuery: (store, type, query, modelArray) ->
    root = @rootForType(type)
    plural = @pluralize(root)
    @ajax "/" + plural, "GET",
      data: query
      success: (json) ->
        modelArray.load json[plural]
        @sideload store, type, json, plural

  plurals: {}
  pluralize: (name) ->
    @plurals[name] or name + "s"

  rootForType: (type) ->
    return type.url  if type.url
    parts = type.toString().split(".")
    name = parts[parts.length - 1]
    name.replace(/([A-Z])/g, "_$1").toLowerCase().slice 1

  send: (action, type, hash) ->
    hash.url = url
    hash.type = type
    hash.dataType = "json"
    hash.contentType = "application/json"
    hash.context = this
    hash.data = JSON.stringify(hash.data)  if hash.data
    jQuery.ajax hash

  sideload: (store, type, json, root) ->
    sideloadedType = undefined
    mappings = undefined
    for prop of json
      continue unless json.hasOwnProperty(prop)
      continue if prop is root
      sideloadedType = type.typeForAssociation(prop)
      unless sideloadedType
        mappings = get(this, "mappings")
        ember_assert "Your server returned a hash with the key " + prop + " but you have no mappings", !!mappings
        sideloadedType = get(get(this, "mappings"), prop)
        ember_assert "Your server returned a hash with the key " + prop + " but you have no mapping for it", !!sideloadedType
      @loadValue store, sideloadedType, json[prop]

  loadValue: (store, type, value) ->
    if value instanceof Array
      store.loadMany type, value
    else
      store.load type, value
)