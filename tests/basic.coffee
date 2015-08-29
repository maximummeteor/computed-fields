Tinytest.add 'ComputedFields - Basic', (test) ->
  posts = new Mongo.Collection null
  posts.computedFields.add 'updateCount', (post) ->
    @set (post.updateCount or 0) + 1
  postId = posts.insert name: 'test'
  posts.update postId, $set: name: 'passed'

  post = posts.findOne postId
  test.equal post.updateCount, 2

Tinytest.add 'computedFields - external dependencies', (test) ->
  posts = new Mongo.Collection null
  authors = new Mongo.Collection null

  authors.computedFields.add('postCount').addDependency posts,
    findId: (post) -> post.authorId
    update: (author, post) ->
      return if @isUpdate
      inc = 1
      inc = inc * -1 if @isRemove
      @set author.postCount + inc

  authorId = authors.insert name: 'max'
  posts.insert
    name: 'test'
    authorId: authorId

  author = authors.findOne authorId
  test.equal author.postCount, 1

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
