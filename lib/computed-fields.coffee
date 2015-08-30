class ComputedFields
  fields: {}
  constructor: (@collection) ->
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
    return unless @updateMethod?
    callUpdate = (method) -> (userId, doc, fieldNames) ->
      thisValue = field._getThis this, doc, userId, fieldNames, method
      field.updateMethod.call thisValue, @transform()
    @collection.after.insert callUpdate 'insert'
    @collection.after.update callUpdate 'update'
  _getThis: (hook, doc, userId, fieldNames, type) ->
    isUpdate: type is 'update'
    isInsert: type is 'insert'
    isRemove: type is 'remove'
    set: (value) =>
      field = {}
      field[@name] = value
      @collection.direct.update doc._id, $set: field

  addDependency: (collection, options) ->
    check collection, Match.Any
    check options,
      findId: Function
      update: Function
    field = this
    findDoc = (doc) ->
      _id = options.findId(doc)
      field.collection.findOne _id: _id
    callUpdate = (method) -> (userId, doc, fieldNames) ->
      fieldDoc = findDoc doc
      thisValue = field._getThis this, fieldDoc, userId, fieldNames, method
      options.update.call thisValue, fieldDoc, @transform()
    collection.after.insert callUpdate 'insert'
    collection.after.update callUpdate 'update'
    collection.after.remove callUpdate 'remove'

Meteor.addCollectionExtension (name, options) ->
  @computedFields = new ComputedFields this
