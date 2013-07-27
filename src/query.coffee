
dotGet = (d, k) ->
  x = d
  for s in k.split('.')
    x = x[s] if x?
  x

dotSet = (d, k, v) ->
  x = d
  for s in k.split('.')
    x[s] = {} unless x[s]?
    p = x
    x = x[s]
  p[s] = v

dotDel = (d, k) ->
  x = d
  for s in k.split('.')
    x[s] = {} unless x[s]?
    p = x
    x = x[s]
  delete p[s]

s1 = {}
s2 =
  # [comparison]
  $gt:  (v,q) -> v >  q # Matches values that are greater than the value specified in the query.
  $gte: (v,q) -> v >= q # Matches values that are equal to or greater than the value specified in the query.
  $in:  (v,q) -> v in q # Matches any of the values that exist in an array specified in the query.
  $lt:  (v,q) -> v <  q # Matches values that are less than the value specified in the query.
  $lte: (v,q) -> v <= q # Matches values that are less than or equal to the value specified in the query.
  $ne:  (v,q) -> v != q # Matches all values that are not equal to the value specified in the query.
  $nin: (v,q) -> v not in q # Matches values that do not exist in an array specified to the query.
  $all: (v,q) -> # Matches arrays that contain all elements specified in the query.
    for x in v
      return false if x not in q
    true

  # [element]
  $exists: (v,q) -> v? == q # Matches documents that have the specified field.
  $mod: (v,q) -> (v % q[0]) == q[1]# Performs a modulo operation on the value of a field and selects documents with a specified result.
  #TODO: $type: () # Selects documents if a field is of the specified type.

  # [array]
  $size: (v,q) -> v.length == q # Selects documents if the array field is a specified size.
  $elemMatch: (v,q) -> # Selects documents if element in the array field matches all the specified $elemMatch condition.
    for x in v
      return true if s1.$m(x,q)
    false

  $m: (v,q) ->
    for op, qv of q
      return false unless @[op](v,qv)
    return true

  # [javascript]
  # TODO: $where: # Matches documents that satisfy a JavaScript expression.
  # TODO: $regex: # Selects documents where values match a specified regular expression.

  # [geospatial]
  # TODO: $geoWithin: # Selects geometries within a bounding GeoJSON geometry.
  # TODO: $geoIntersects: # Selects geometries that intersect with a GeoJSON geometry.
  # TODO: $near: # Returns geospatial objects in proximity to a point.
  # TODO: $nearSphere: # Returns geospatial objects in proximity to a point on a sphere.

s1[k] = v for k,v of {
  # [logical]
  $or:  (v,q) -> # Joins query clauses with a logical OR returns all documents that match the conditions of either clause.
    for xq in q
      return true if @$m(v,xq)
    false
  $and: (v,q) -> # Joins query clauses with a logical AND returns all documents that match the conditions of both clauses.
    for xq in q
      return false unless @$m(v,xq)
    true
  $not: (v,q) -> # Inverts the effect of a query expression and returns documents that do not match the query expression.
    return not @$m(v,q)
  $nor: (v,q) -> # Joins query clauses with a logical NOR returns all documents that fail to match both clauses.
    for xq in q
      return false if @$m(v,xq)
    true
  $m:   (d,q) ->
    for k, v of q
      if k of @ # $or, $and, etc.
        m = @[k](d,v)
      else # Regular query
        x = dotGet(d, k)

        if v instanceof RegExp # Regular expresion
          m = v.test(x)
        else if v instanceof Object
          if Object.keys(v)[0][0] == '$' # Operators
            m = s2.$m(x, v)
          else # Object
            m = (JSON.stringify(v) == JSON.stringify(x))
        else if Array.isArray(x) # Array
          m = v in x
        else # Scalar
          m = (x == v)

      return false unless m
    true
}

Query = (q) ->
  (d) -> s1.$m(d,q)

Compare = (c) ->
  (a,b) ->
    for k, v of c
      mod = if v < 0 then -1 else 1
      return -1 * mod if a[k] < b[k]
      return  1 * mod if a[k] > b[k]
    return 0

u1 =
  # [fields]
  $inc: (d, k, upd) -> dotSet(d, k, upd + dotGet(d, k)) # Increments the value of the field by the specified amount.
  $rename: (d, k, upd) -> # Renames a field.
    dotSet(d, upd, dotGet(d, k))
    dotDel(d, k)
  $setOnInsert: (d, k, upd, insert) ->	# Sets the value of a field upon documentation creation during an upsert. Has no effect on update operations that modify existing documents.
    return unless insert
    dotSet(d, k, upd)
  $set: (d, k, upd) -> dotSet(d, k, upd) #Sets the value of a field in an existing document.
  $unset: (d, k, upd) -> dotDel(d, k) # Removes the specified field from an existing document.
  # [Array][operators]
  # TODO: $ 	Acts as a placeholder to update the first element that matches the query condition in an update.
  $addToSet: (d, k, upd) -> # Adds elements to an existing array only if they do not already exist in the set.
    l = dotGet(d, k)
    # $each 	append multiple items for array updates.
    if upd.$each?
      for x in upd.$each
        l.push(x) unless upd in l
    else
      l.push(upd) unless upd in l

  $pop: (d, k, upd) -> # Removes the first or last item of an array.
    l = dotGet(d, k)
    if upd < 0
      l.shift()
    else
      l.pop()

  $pullAll: (d, k, upd) -> #Removes multiple values from an array.
    l = dotGet(d, k)
    for i in [0...l.length]
      if l[i] in upd
        l.splice(i, 1)
        i -= 1

  $pull: (d, k, upd) -> # Removes items from an array that match a query statement.
    l = dotGet(d, k)
    q = Query(upd)
    for i in [0...l.length]
      if q(l[i])
        l.splice(i, 1)
        i -= 1

  $push: (d, k, upd) -> # Adds an item to an array.
    l = dotGet(d, k)
    # $each 	append multiple items for array updates.
    if upd.$each?
      for x in upd.$each
        l.push(x)
      # $sort 	reorder documents stored in an array.
      if upd.$sort?
        c = Compare(upd.$sort)
        l.sort(c)
      # $slice 	limit the size of updated arrays.
      l.splice($upd.$slice, l.length)
    else
      l.push(upd)

Update = (op, update, data) ->
  for k, v of update
    u1[op](data, k, v, false)
