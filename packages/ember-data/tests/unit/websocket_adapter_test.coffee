require "ember-data/adapters/websocket_adapter"
get = Ember.get
set = Ember.set
adapter   = undefined
store     = undefined
wsUrl    = undefined
wsAction  = undefined
wsHash    = undefined
Person    = undefined
person    = undefined
people    = undefined
Role      = undefined
role      = undefined
roles     = undefined
Group     = undefined
group     = undefined

module "the Websocket adapter",
  setup: ->
    wsHost    = `undefined`
    wsAction  = `undefined`
    wsHash    = `undefined`
    
    adapter = DS.WebsocketAdapter.create(
      url: wsUrl
      
      send: (action, hash) ->
        self      = this
        wsAction  = action
        wsHash    = hash
        if success
          hash.success = (json) ->
            success.call self, json

      plurals:
        person: "people"
    )
    
    store = DS.Store.create(adapter: adapter)
    Person = DS.Model.extend(name: DS.attr("string"))
    
    Person.toString = -> "App.Person"

    Group = DS.Model.extend(
      name: DS.attr("string")
      people: DS.hasMany(Person)
    )
    
    Group.toString = -> "App.Group"

    Role = DS.Model.extend(
      name: DS.attr("string")
      primaryKey: "_id"
    )
    
    Role.toString = -> "App.Role"

  teardown: ->
    adapter.destroy()
    store.destroy()
    person.destroy()  if person

expectUrl = (url, desc) ->
  equal wsUrl, url, "the URL is " + desc

expectAction = (action) ->
  equal action, wsHash.data.action, "the action is " + action

expectModel = (model) ->
  equal model, wsHash.data.model, "the model is " + model

expectData = (hash) ->
  deepEqual hash, wsHash.data, "the hash was passed along"

expectState = (state, value, p) ->
  p = p or person
  value = true  if value is `undefined`
  flag = "is" + state.charAt(0).toUpperCase() + state.substr(1)
  equal get(p, flag), value, "the person is " + (if value is false then "not " else "") + state

expectStates = (state, value) ->
  people.forEach (person) ->
    expectState state, value, person

test "creating a person makes a hash with action: 'create', model: 'person'", ->
  set adapter, "bulkCommit", false
  person = store.createRecord Person, {name: "Tom Dale"}
  expectState "new"
  store.commit()
  expectState "saving"
  expectModel "person"
  expectAction "create"
  expectData person:
    name: "Tom Dale"

  wsHash.success person:
    id: 1
    name: "Tom Dale"

  expectState "saving", false
  equal person, store.find(Person, 1), "it is now possible to retrieve the person by the ID supplied"

