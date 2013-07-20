
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

