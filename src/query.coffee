
s2 =
  # [comparison]
  $all: (v,q) -> # Matches arrays that contain all elements specified in the query.
    for x in v
      return false if x not in q
    true
  $gt:  (v,q) -> v >  q # Matches values that are greater than the value specified in the query.
  $gte: (v,q) -> v >= q # Matches values that are equal to or greater than the value specified in the query.
  $in:  (v,q) -> v in q # Matches any of the values that exist in an array specified in the query.
  $lt:  (v,q) -> v <  q # Matches values that are less than the value specified in the query.
  $lte: (v,q) -> v <= q # Matches values that are less than or equal to the value specified in the query.
  $ne:  (v,q) -> v != q # Matches all values that are not equal to the value specified in the query.
  $nin: (v,q) -> v not in q # Matches values that do not exist in an array specified to the query.
  $m:   (v,q) ->
    for op, qv of q
      return false unless @[op](v,qv)
    return true

###
  # [element]
  $exists: # Matches documents that have the specified field.
  $mod: # Performs a modulo operation on the value of a field and selects documents with a specified result.
  $type: # Selects documents if a field is of the specified type.

  # [javascript]
  $where: # Matches documents that satisfy a JavaScript expression.
  $regex: # Selects documents where values match a specified regular expression.

  # [geospatial]
  $geoWithin: # Selects geometries within a bounding GeoJSON geometry.
  $geoIntersects: # Selects geometries that intersect with a GeoJSON geometry.
  $near: # Returns geospatial objects in proximity to a point.
  $nearSphere: # Returns geospatial objects in proximity to a point on a sphere.

  # [array]
  $elemMatch: # Selects documents if element in the array field matches all the specified $elemMatch condition.
  $size: # Selects documents if the array field is a specified size.
###

s1 =
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
        x = d
        for s in k.split('.')
          x = x[s] if x?
        if v instanceof Object
          if Object.keys(v)[0][0] == '$'
            m = s2.$m(x, v)
          else
            m = (JSON.stringify(v) == JSON.stringify(x))
        else if Array.isArray(x)
          m = v in x
        else
          m = (x == v)
      return false unless m
    true

Query = (q) ->
  (d) -> s1.$m(d,q)
