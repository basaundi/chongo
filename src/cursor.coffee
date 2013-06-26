
class Cursor
  constructor: (@col, @index, @spec) ->
    @doc = null
    @started = false
    @done = false
    @i = 0
    @n = 0

  load: () ->
    # TODO: select best index
    # TODO: prepare matching function
    # TODO: skip
    @started = true

  fetch: ->
    @load() unless @started
    @doc = null
    until @doc? || @i >= @index.length # TODO: limit
      oid = @index[@i++]
      @doc = new Document(@col, oid)
      # TODO: match with spec
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
    doc = @doc.data
    @doc = null
    doc
