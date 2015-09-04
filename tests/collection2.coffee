if Meteor.isServer
  Tinytest.add 'ComputedFields - Collection2 - Basic', (test) ->
    posts = new Mongo.Collection null
    posts.attachSchema
      updateCount:
        type: Number
        optional: true
        compute: (post) ->
          @set (post.updateCount or 0) + 1

    postId = posts.insert name: 'test'
    posts.update postId, $set: name: 'passed'

    post = posts.findOne postId
    test.equal post.updateCount, 2

  Tinytest.add 'ComputedFields - Collection2 - Subobject', (test) ->
    posts = new Mongo.Collection null
    posts.attachSchema
      computed:
        type: Object
        optional: true
      'computed.updateCount':
        type: Number
        optional: true
        compute: (post) ->
          @set (post.computed?.updateCount or 0) + 1

    postId = posts.insert name: 'test'
    posts.update postId, $set: name: 'passed'

    post = posts.findOne postId
    test.equal post.computed?.updateCount, 2

  Tinytest.add 'ComputedFields - Collection2 - external dependencies', (test) ->
    posts = new Mongo.Collection null
    authors = new Mongo.Collection null
    authors.attachSchema
      name:
        type: String
      postCount:
        type: Number
        optional: true
        compute:
          dependency:
            collection: posts
            findId: (post) -> post.authorId
            update: (author, post) ->
              if @isInsert or @previous.authorId isnt author._id
                @set (author.postCount or 0) + 1
              else if @isRemove or
              (@previous.authorId is author._id and post.authorId isnt author._id)
                @set (author.postCount or 0) - 1

    authorId = authors.insert name: 'max'
    postId = posts.insert
      name: 'test'
      authorId: authorId
    author = authors.findOne authorId
    test.equal author.postCount, 1

    postId2 = posts.insert
      name: 'test2'
      authorId: authorId
    author = authors.findOne authorId
    test.equal author.postCount, 2

    posts.update postId, $set: test: 1
    author = authors.findOne authorId
    test.equal author.postCount, 2

    posts.update postId, $set: authorId: 'test123'
    author = authors.findOne authorId
    test.equal author.postCount, 1

    posts.remove postId2
    author = authors.findOne authorId
    test.equal author.postCount, 0

  Tinytest.add 'ComputedFields - Collection2 - simple computation', (test) ->
    posts = new Mongo.Collection null
    authors = new Mongo.Collection null

    authors.attachSchema
      name:
        type: String
      postCount:
        type: Number
        optional: true
        compute:
          simple:
            collection: posts
            referenceFieldName: 'authorId'
            update: (author) ->
              (author.postCount or 0) + @increment

    authorId = authors.insert name: 'max'
    postId = posts.insert
      name: 'test'
      authorId: authorId
    author = authors.findOne authorId
    test.equal author.postCount, 1

    postId2 = posts.insert
      name: 'test2'
      authorId: authorId
    author = authors.findOne authorId
    test.equal author.postCount, 2

    posts.update postId, $set: test: 1
    author = authors.findOne authorId
    test.equal author.postCount, 2

    posts.update postId, $set: authorId: 'test123'
    author = authors.findOne authorId
    test.equal author.postCount, 1

    posts.remove postId2
    author = authors.findOne authorId
    test.equal author.postCount, 0

  Tinytest.add 'ComputedFields - Collection2 - simple increment', (test) ->
    posts = new Mongo.Collection null
    authors = new Mongo.Collection null

    authors.attachSchema
      name:
        type: String
      postCount:
        type: Number
        optional: true
        compute:
          increment:
            collection: posts
            referenceFieldName: 'authorId'
            update: (author) -> @increment

    authorId = authors.insert name: 'max'
    postId = posts.insert
      name: 'test'
      authorId: authorId
    author = authors.findOne authorId
    test.equal author.postCount, 1

    postId2 = posts.insert
      name: 'test2'
      authorId: authorId
    author = authors.findOne authorId
    test.equal author.postCount, 2

    posts.update postId, $set: test: 1
    author = authors.findOne authorId
    test.equal author.postCount, 2

    posts.update postId, $set: authorId: 'test123'
    author = authors.findOne authorId
    test.equal author.postCount, 1

    posts.remove postId2
    author = authors.findOne authorId
    test.equal author.postCount, 0

  Tinytest.add 'ComputedFields - Collection2 - simple count', (test) ->
    posts = new Mongo.Collection null
    authors = new Mongo.Collection null

    authors.attachSchema
      name:
        type: String
      postCount:
        type: Number
        optional: true
        compute:
          count:
            collection: posts
            referenceFieldName: 'authorId'

    authorId = authors.insert name: 'max'
    postId = posts.insert
      name: 'test'
      authorId: authorId
    author = authors.findOne authorId
    test.equal author.postCount, 1

    postId2 = posts.insert
      name: 'test2'
      authorId: authorId
    author = authors.findOne authorId
    test.equal author.postCount, 2

    posts.update postId, $set: test: 1
    author = authors.findOne authorId
    test.equal author.postCount, 2

    posts.update postId, $set: authorId: 'test123'
    author = authors.findOne authorId
    test.equal author.postCount, 1

    posts.remove postId2
    author = authors.findOne authorId
    test.equal author.postCount, 0

  Tinytest.add 'ComputedFields - Collection2 - update multiple', (test) ->
    posts = new Mongo.Collection null
    authors = new Mongo.Collection null

    authors.attachSchema
      name:
        type: String
      postCount:
        type: Number
        optional: true
        compute:
          dependency:
            collection: posts
            findId: (post) -> post.authorIds
            update: (author, post) ->
              if @isInsert or @previous.authorId isnt author._id
                @set (author.postCount or 0) + 1
              else if @isRemove or
              (@previous.authorId is author._id and post.authorId isnt author._id)
                @set (author.postCount or 0) - 1

    author1Id = authors.insert name: 'max'
    author2Id = authors.insert name: 'luis'

    postId = posts.insert
      name: 'test'
      authorIds: [author1Id, author2Id]

    postId = posts.insert
      name: 'test'
      authorIds: [author1Id]

    author1 = authors.findOne author1Id
    author2 = authors.findOne author2Id

    test.equal author1.postCount, 2
    test.equal author2.postCount, 1

  Tinytest.add 'ComputedFields - Collection2 - no update on previous', (test) ->
    posts = new Mongo.Collection null
    authors = new Mongo.Collection null

    authors.attachSchema
      name:
        type: String
      postCount:
        type: Number
        optional: true
        compute:
          dependency:
            collection: posts
            findId: (post) -> post.authorId
            updateOnPrevious: false
            update: (author, post) ->
              if @isInsert or @previous.authorId isnt author._id
                @set (author.postCount or 0) + 1
              else if @isRemove or
              (@previous.authorId is author._id and post.authorId isnt author._id)
                @set (author.postCount or 0) - 1

    authorId = authors.insert name: 'max'
    postId = posts.insert
      name: 'test'
      authorId: authorId
    author = authors.findOne authorId
    test.equal author.postCount, 1

    postId2 = posts.insert
      name: 'test2'
      authorId: authorId
    author = authors.findOne authorId
    test.equal author.postCount, 2

    posts.update postId, $set: test: 1
    author = authors.findOne authorId
    test.equal author.postCount, 2

    posts.update postId, $set: authorId: 'test123'
    author = authors.findOne authorId
    test.equal author.postCount, 2

    posts.remove postId2
    author = authors.findOne authorId
    test.equal author.postCount, 1

if Meteor.isClient
  Tinytest.add 'ComputedFields - Collection2 - Client', (test) ->
    posts = new Mongo.Collection null
    posts.attachSchema
      updateCount:
        type: Number
        optional: true
        compute: (post) ->
          @set (post.updateCount or 0) + 1

#Test API:
#test.isFalse(v, msg)
#test.isTrue(v, msg)
#test.equalactual, expected, message, not
#test.length(obj, len)
#test.include(s, v)
#test.isNaN(v, msg)
#test.isUndefined(v, msg)
#test.isNotNull
#test.isNull
#test.throws(func)
#test.instanceOf(obj, klass)
#test.notEqual(actual, expected, message)
#test.runId()
#test.exception(exception)
#test.expect_fail()
#test.ok(doc)
#test.fail(doc)
#test.equal(a, b, msg)
