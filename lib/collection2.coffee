return unless Package['aldeed:collection2']? # check for collection2 package

dependency =
  collection: Match.Any
  findId: Function
  update: Function
  updateOnPrevious: Match.Optional Boolean

dependencies = dependencies: [dependency]

simple = simple:
  collection: Match.Any
  referenceFieldName: String
  update: Function

increment = increment:
  collection: Match.Any
  referenceFieldName: String
  update: Function

count = count:
  collection: Match.Any
  referenceFieldName: String


SimpleSchema = Package['aldeed:simple-schema'].SimpleSchema
SimpleSchema.extendOptions
  compute: Match.Optional Match.OneOf Function, dependencies, (dependency: dependency), simple, increment, count

return unless Meteor.isServer

Mongo = Package['mongo'].Mongo
attachSchema = Mongo.Collection::attachSchema
Mongo.Collection::attachSchema = (ss, options) ->
  attachSchema.call this, ss, options

  unless ss instanceof SimpleSchema
    ss = new SimpleSchema ss

  for name, def of ss.schema() when def.compute?
    definition = def.compute

    if _.isFunction definition
      field = @computedFields.add name, definition
    else
      field = @computedFields.add name

    if definition.dependencies
      for dep in definition.dependencies
        collection = dep.collection
        delete dep.collection
        field.addDependency collection, dep

    if definition.dependency
      collection = definition.dependency.collection
      delete definition.dependency.collection
      field.addDependency collection, definition.dependency

    if definition.simple
      field.simple definition.simple.collection,
        definition.simple.referenceFieldName
        definition.simple.update

    if definition.increment
      field.increment definition.increment.collection,
        definition.increment.referenceFieldName
        definition.increment.update

    if definition.count
      field.count definition.count.collection,
        definition.count.referenceFieldName
