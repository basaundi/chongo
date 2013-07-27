
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
  ## [comparison]
  # Matches values that are greater than the value specified in the query.
  $gt:  (v,q) -> v >  q
  # Matches values that are equal to or greater than the value specified in the
  #  query.
  $gte: (v,q) -> v >= q
  # Matches any of the values that exist in an array specified in the query.
  $in:  (v,q) -> v in q
  # Matches values that are less than the value specified in the query.
  $lt:  (v,q) -> v <  q
  # Matches values that are less than or equal to the value specified in the
  #  query.
  $lte: (v,q) -> v <= q
  # Matches all values that are not equal to the value specified in the query.
  $ne:  (v,q) -> v != q
  # Matches values that do not exist in an array specified to the query.
  $nin: (v,q) -> v not in q
  # Matches arrays that contain all elements specified in the query.
  $all: (v,q) ->
    for x in v
      return false if x not in q
    true

  ## [element]
  # Matches documents that have the specified field.
  $exists: (v,q) -> v? == q
  # Performs a modulo operation on the value of a field and selects documents
  #  with a specified result.
  $mod: (v,q) -> (v % q[0]) == q[1]
  # TODO: $type: Selects documents if a field is of the specified type.

  ## [array]
  # Selects documents if the array field is a specified size.
  $size: (v,q) -> v.length == q
  # Selects documents if element in the array field matches all the specified
  #  $elemMatch condition.
  $elemMatch: (v,q) ->
    for x in v
      return true if s1.$m(x,q)
    false

  # Match
  $m: (v,q) ->
    for op, qv of q
      return false unless @[op](v,qv)
    return true

  ## [javascript]
  # TODO: $where: # Matches documents that satisfy a JavaScript expression.
  # TODO: $regex: # Selects documents where values match a specified regular expression.

  ## [geospatial]
  # TODO: $geoWithin: # Selects geometries within a bounding GeoJSON geometry.
  # TODO: $geoIntersects: # Selects geometries that intersect with a GeoJSON geometry.
  # TODO: $near: # Returns geospatial objects in proximity to a point.
  # TODO: $nearSphere: # Returns geospatial objects in proximity to a point on a sphere.

s1[k] = v for k,v of {
  ## [logical]
  # Joins query clauses with a logical OR returns all documents that match the
  #  conditions of either clause.
  $or:  (v,q) ->
    for xq in q
      return true if @$m(v,xq)
    false
  # Joins query clauses with a logical AND returns all documents that match the
  #  conditions of both clauses.
  $and: (v,q) ->
    for xq in q
      return false unless @$m(v,xq)
    true
  # Inverts the effect of a query expression and returns documents that do not
  #  match the query expression.
  $not: (v,q) ->
    return not @$m(v,q)
  # Joins query clauses with a logical NOR returns all documents that fail to
  #  match both clauses.
  $nor: (v,q) ->
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

type_order = (x) ->
  # TODO: Handle Datetime and BinData
  to = typeof x
  return 2 if x == null
  return 3 if to == 'number'
  return 4 if to == 'string'
  return 9 if to == 'boolean'
  return 8 if x instanceof ObjectId
  return 11 if x instanceof RegExp
  return 6 if x instanceof Array
  return 5 # if x instanceof Object

zero = -> 0

simple_cmp = (a, b) ->
    return -1 if a < b
    return  1 if a > b
    0

deep_cmp = (a, b) ->
    simple_cmp(JSON.stringify(a), JSON.stringify(b))

# Compare two variables of the same type
cmp_type = [
  null,
  zero,        # 1  MinKey (internal type)
  zero,        # 2  null
  simple_cmp,  # 3  Number
  simple_cmp,  # 4  String
  deep_cmp,    # 5  Object
  deep_cmp,    # 6  Array
  simple_cmp,  # 7  BinData
  simple_cmp,  # 8  ObjectId
  simple_cmp,  # 9  Boolean
  simple_cmp,  # 10 Date
  simple_cmp,  # 11 RegExp
  zero,        # 12 MaxKey
]

# Compare two variables of any type
cmp = (a, b) ->
  at = type_order(a)
  bt = type_order(b)
  return -1 if at < bt
  return  1 if at > bt
  cmp_type[at](a, b)

Compare = (c) ->
  (a,b) ->
    for k, v of c
      x = a[k] || null
      y = b[k] || null
      mod = if v < 0 then -1 else 1
      r = cmp(x, y)
      return r if r
    return 0

u1 =
  ## [fields]
  # Increments the value of the field by the specified amount.
  $inc: (d, k, upd) -> dotSet(d, k, upd + dotGet(d, k))
  # Renames a field.
  $rename: (d, k, upd) ->
    dotSet(d, upd, dotGet(d, k))
    dotDel(d, k)
  # Sets the value of a field upon documentation creation during an upsert.
  #  Has no effect on update operations that modify existing documents.
  $setOnInsert: (d, k, upd, insert) ->
    return unless insert
    dotSet(d, k, upd)
  # Sets the value of a field in an existing document.
  $set: (d, k, upd) -> dotSet(d, k, upd)
  # Removes the specified field from an existing document.
  $unset: (d, k, upd) -> dotDel(d, k)
  # [Array][operators]
  # TODO: $: # Acts as a placeholder to update the first element that matches the query condition in an update.
  # Adds elements to an existing array only if they do not already exist in the
  #  set.
  $addToSet: (d, k, upd) ->
    l = dotGet(d, k)
    # $each 	append multiple items for array updates.
    if upd.$each?
      for x in upd.$each
        l.push(x) unless upd in l
    else
      l.push(upd) unless upd in l

  # Removes the first or last item of an array.
  $pop: (d, k, upd) ->
    l = dotGet(d, k)
    if upd < 0
      l.shift()
    else
      l.pop()

  # Removes multiple values from an array.
  $pullAll: (d, k, upd) ->
    l = dotGet(d, k)
    for i in [0...l.length]
      if l[i] in upd
        l.splice(i, 1)
        i -= 1

  # Removes items from an array that match a query statement.
  $pull: (d, k, upd) ->
    l = dotGet(d, k)
    q = Query(upd)
    for i in [0...l.length]
      if q(l[i])
        l.splice(i, 1)
        i -= 1

  # Adds an item to an array.
  $push: (d, k, upd) ->
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
      l.splice(0, l.length + upd.$slice)
    else
      l.push(upd)

Update = (op, update, data) ->
  for k, v of update
    u1[op](data, k, v, false)
