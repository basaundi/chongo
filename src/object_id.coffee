class ObjectId
  @inc: ~~(Math.random() * 0xFFFFFF)
  @hostname: @inc
  @pid: ~~(Math.random() * 0xFFFFFF)
  @getInc: () ->
    v = @inc
    @inc = (@inc + 1) % 0xFFFFFF
    v

  constructor: (hex=null)->
    if hex?
      @v = hex
    else
      @v = @constructor.generate()

  @generate: ->
    v  = @_pad("00000000", (~~((new Date).getTime() / 1000)))
    v += @_pad("000000", @hostname)
    v += @_pad("0000", @pid)
    v += @_pad("000000", @getInc())
    v

  toString: -> 'ObjectId("' + @v +'")'
  valueOf: -> @v
  @_pad: (f,v) ->
    t = v.toString(16)
    (f+t).substring(t.length)
