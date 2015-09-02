class ComputedFields
  constructor: (@collection) -> @fields = {}
  add: (name, updateMethod) ->
    check name, String
    check updateMethod, Match.Optional Function
    unless @fields[name]?
      @fields[name] = new ComputedField @collection, name, updateMethod
    return @fields[name]

  get: (name) ->
    check name, String
    @fields[name] or @add(name)


class ComputedField
  constructor: (@collection, @name, @updateMethod) ->
    field = this
    @_dependencies = []
    return unless @updateMethod?
    addHooks collection, (type, userId, doc, fieldNames) ->
      thisValue = field._getThis this, doc, userId, fieldNames, type
      field.updateMethod.call thisValue, @transform()

  _getThis: (hook, doc, userId, fieldNames, type) ->
    unless hook?
      hook =
        transform: (obj) -> obj
        previous: {}

    isUpdate: type is 'update'
    isInsert: type is 'insert'
    isRemove: type is 'remove'
    previous: hook.transform hook.previous
    userId: userId
    fieldNames: fieldNames
    set: (value) =>
      field = {}
      field[@name] = value
      @collection.direct.update doc._id, $set: field

  rebuild: ->
    field = this
    if @updateMethod?
      @collection.find().forEach (doc) ->
        thisValue = field._getThis null, doc, null, [], 'insert'
        field.updateMethod.call thisValue, @transform()

    for dependency in @_dependencies
      dependency.collection.find().forEach (doc) ->
        return unless fieldDoc = dependency.findDoc doc

        thisValue = field._getThis null, fieldDoc, null, [], 'insert'
        dependency.update.call thisValue, fieldDoc, doc

  addDependency: (collection, options) ->
    check collection, Match.Any
    check options,
      findId: Function
      update: Function

    field = this
    findDoc = (doc) ->
      _id = options.findId(doc)
      field.collection.findOne _id: _id

    @_dependencies.push _.extend _.clone(options),
      collection: collection
      findDoc: findDoc

    addHooks collection, (type, userId, doc, fieldNames) ->
      callUpdate = (fieldDoc) ->
        thisValue = field._getThis this, fieldDoc, userId, fieldNames, type
        options.update.call thisValue, fieldDoc, @transform()

      if doc? and currentDoc = findDoc @transform()
        callUpdate.call this, currentDoc
      if @previous? and previousDoc = findDoc @transform(@previous)
        callUpdate.call this, previousDoc
    return this

  simple: (collection, fieldName, setMethod) ->
    field = this
    @addDependency collection,
      findId: (externalDoc) -> externalDoc[fieldName]
      update: (doc, externalDoc) ->
        if @isInsert or @previous[fieldName] isnt doc._id
          increment = 1
        else if @isRemove or
        (@previous[fieldName] is doc._id and externalDoc[fieldName] isnt doc._id)
          increment = -1
        else return

        _this = _.extend this, increment: increment
        value = setMethod.call _this, doc, externalDoc
        @set value
    return this
  increment: (collection, fieldName, incMethod) ->
    field = this
    @simple collection, fieldName, (doc, externalDoc) ->
      (doc[field.name] or 0) + incMethod.call this, doc, externalDoc
    return this
  count: (collection, fieldName) ->
    @increment collection, fieldName, (doc, externalDoc) -> @increment

addHooks = (collection, method) ->
  callMethod = (type) -> (userId, doc, fieldNames) ->
    method.call this, type, userId, doc, fieldNames
  collection.after.insert callMethod 'insert'
  collection.after.update callMethod 'update'
  collection.after.remove callMethod 'remove'

Meteor.addCollectionExtension (name, options) ->
  @computedFields = new ComputedFields this
