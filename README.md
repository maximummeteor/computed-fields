# maximum:computed-fields [![Build Status](https://travis-ci.org/maximummeteor/computed-fields.svg)](https://travis-ci.org/maximummeteor/computed-fields)
Meteor package for automatic computation of field values in a collection

## What it does

Let's think you have two collections, authors and posts. Posts have one author.
You want to display the number of posts an author has written on the author's page. Normally in Meteor you would publish the posts for an author and do a `Posts.find({authorId: '...'}).count()`. But if an author has written a large number of posts, it can be slow.
At this point, it's better to use computed fields instead of doing the computation on-the-fly.
What if you have a field called `postCount` in the authors collection that holds the number of posts of an author and updates itself automatically?
With this package, you can achieve this with one line of code:

````javascript
  var Posts = new Mongo.Collection('posts');
  var Authors = new Mongo.Collection('authors');

  // on server side
  Authors.computedFields.add('postCount').count(Posts, 'authorId');
````

## Installation
```
    meteor add maximum:computed-fields
```

## Usage

You can add an computed field with `*collection*.computedFields.add(name, [calculation])` (on serverside only).
The first parameter `name` specify how the field should be named. It's possible to specify sub-objects with `.` (e.g. `subobject.commentsCount`)
The second parameter is optional and specifies a function with the basic computation. It will be executed on `insert`, `update` and `remove` of documents in the specified collection. It gets the affected document as the first parameter.
````javascript
  Posts.computedFields.add('commentsCount'); // returns a ComputedField instance

  Posts.computedFields.add('updateCount', function(post){
    /*  
      content of `this`:
      * isUpdate (boolean)
      * isInsert (boolean)
      * isRemove (boolean)
      * previous (object)
      * userId: (string)
      * fieldNames ([string])
      * computedField: (string)
      * set (function)
    */
    this.set(newValue); // use `set` to update the field
  });
````

It's also possible to get a computed field, after it was created
````javascript
  Posts.computedFields.get('commentsCount'); // returns the ComputedField instance
````

### ComputedField
|Method|Description|
|------|-----------|
|addDependency(`collection`, `options`)|Does a computation depending on a other collection. This method takes the other collection as the first parameter and an options-object as the second one:<ul><li>`findId(relatedDoc)`: Function to get the relation between the two collections. Must return an `_id` of the collection, in which the computed field is. Return an array of `_id`s, if you want to update multiple documents.</li><li>`update(currentDoc, relatedDoc)`: Function to update the computed field. See above for the value of `this`</li></ul> |
|simple(`collection`, `referenceFieldName`, `update`)|Does a computation depending on a other collection (a simpler approach). It takes the following parameters:<ul><li>`collection`: the other collection</li><li>`referenceFieldName`: the name of the field which contains the `_id` of the document (e.g. `authorId`).</li><li>`update(currentDoc, relatedDoc)`: function to update the computed field. Must return the new value for the computed field. See above for the value of `this`. For this function, `this` will be extended with the `increment` property. `this.increment` contains `1` if an related document was added and `-1` if a related document was removed.</li></ul>|
|increment(`collection`, `referenceFieldName`, `update`)|Same like `simple`, but the return value of the `update` function will be added to the current value instead of overwriting it. |
|count(`collection`, `referenceFieldName`)|The simplest approach. Specially for `count` properties. Works internally with `increment` and returns `this.increment`|
|rebuild()|Rebuilds the computed field. Useful for migrations.|


## Examples

### Normal computation

This is the easiest type of automatic computations. It doesn't depend on other collections.
````javascript
  //increments the field 'updateCount' every time the document gets updated (or inserted)
  Posts.computedFields.add('updateCount', function(post){
    current = post.updateCount or 0
    this.set(current + 1);
  });
````


### Computations from other collections

As you've already read above, there are three ways to do computations depending on other collections.

#### addDependency
This is the most flexible approach. Here's an example how a computed `postCount` property could be achieved with `addDependency`.
````javascript
  Authors.computedFields.add('postCount').addDependency(Posts, {
    findId: function(post) {
      return post.authorId;
    },
    update: function(author, post) {
      var currentValue = author.postCount or 0;
      if(this.isInsert || this.previous.authorId != author._id) {
        this.set(currentValue + 1);
      } else if(this.isRemove || (this.previous.authorId == author._id && post.authorId != author._id)) {
        this.set(currentValue - 1);
      }
    }
  });
````

#### simple
This approach is much simpler. Here's an example how a computed `postCount` property could be achieved with `simple`.
````javascript
  Authors.computedFields.add('postCount').simple(Posts, 'authorId', function(author, post) {
    var currentValue = author.postCount or 0;
    return currentValue + this.increment;
  });
````

#### increment
Like `simple`, but designed for incrementations/decrementations.. Here's an example how a computed `postCount` property could be achieved with `increment`.
````javascript
  Authors.computedFields.add('postCount').increment(Posts, 'authorId', function(author, post) {
    return this.increment;
  });
````

#### count
The simplest approach, designed for `count` properties. Here's an example how a computed `postCount` property could be achieved with `count`.
````javascript
  Authors.computedFields.add('postCount').count(Posts, 'authorId');
````


## License
Licensed under MIT license. Copyright (c) 2015 Max Nowack

## Contributions

Contributions are welcome. Please open issues and/or file Pull Requests.

## Maintainers

- Max Nowack ([maxnowack](https://github.com/maxnowack))
