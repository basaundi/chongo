
class Cursor
  constructor: (@col, @index, @query, @projection) ->
    @doc = null
    @started = false
    @done = false
    @i = 0
    @n = 0
    @query = {_id: @query} if typeof @query == "string"

  load: () ->
    # TODO: select best index
    # TODO: skip
    @started = true
    @match = Query(@query)
    @project = if @projection? then Projection(@projection) else (x) -> x

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
    @project(doc)

  toArray: ->
    a = []
    a.push(@next()) while @hasNext()
    a

  count: ->
    n = 0
    while @hasNext()
      n++
      @next()
    n

  update: (update) ->
    throw TypeError() unless @doc?
    oid = @doc._id
    ks = Object.keys(update)
    if ks[0]? && ks[0][0] != '$'
      @doc.data = {}
      @doc.data[k] = v for k, v of update
    else
      for k, v of update
        Update(k, v, @doc.data)
    @doc.data._id = oid
    @doc.store()
