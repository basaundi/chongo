
arrComp = (x, v) ->
  for s in x
    return true if s == v
  return false

selectors =
  $gt:  (x, v) -> x > v
  $gte: (x, v) -> x >= v
  $lt:  (x, v) -> x < v
  $lte: (x, v) -> x <= v
  $in:  (x, v) -> (x in v)
  match: (x, v) ->
    for op, val of v
      return false unless @[op](x, val)
    return true

Query = (q) ->
  (d) ->
    for k, v of q
      x = d
      for s in k.split('.')
        x = x[s]
      if v instanceof Object
        if Object.keys(v)[0][0] == '$'
          m = selectors.match(x, v)
        else
          m = (JSON.stringify(v) == JSON.stringify(x))
      else if Array.isArray(x)
        m = arrComp(x,v)
      else
        m = (x == v)
      return false unless m
    true

class Cursor
  constructor: (@col, @index, @query) ->
    @doc = null
    @started = false
    @done = false
    @i = 0
    @n = 0

  load: () ->
    # TODO: select best index
    # TODO: skip
    @started = true
    @match = Query(@query)

  fetch: ->
    @load() unless @started
    @doc = null
    until @doc? || @i >= @index.length # TODO: limit
      oid = @index[@i++]
      @doc = new Document(@col, oid)
      @doc = null unless @match(@doc.data)
    if @doc?
      ++@n
    else
      @done = true
    @doc

  pop: ->
    # TODO: security check
    return null unless @doc?
    @index.splice(--@i, 1)
    doc = @doc
    @doc = null
    doc

  hasNext: ->
    return true if @doc?
    return false if @done
    @fetch()
    return not @done

  next: ->
    @fetch() unless @doc?
    throw new Error("No more data.") unless @doc?
    doc = @doc.data
    @doc = null
    doc

  toArray: ->
    a = []
    a.push(@next()) while @hasNext()
    a

