class Namespace
  constructor: (@con, @_id, @data) ->
    @ns = '.'
    @load() unless @data?

  load: -> @data = @get('') || {'sub': []}
  store: -> @set('', @data)
  destroy: -> @del('')
  get: (reg) -> @con.get(@ns+@_id+reg)
  set: (reg, v) -> @con.set(@ns+@_id+reg, v)
  del: (reg) -> @con.del(@ns+@_id+reg)

class Document extends Namespace
  constructor: (@con, @_id, @data) ->
    @ns = '.$$'
    @load() unless @data?

class Collection extends Namespace
  find: (query) ->
    new Cursor(@, @data.sub, query)

  findOne: (query) ->
    return new Document(@, query).data if typeof query == "string"
    cur = new Cursor(@, @data.sub, query)
    cur.next()

  count: (query) -> @find(query).count()

  save: (to_save) ->
    type_name = Object.prototype.toString.call(to_save)
    if type_name isnt '[object Object]'
      throw new TypeError("cannot save object of type #{type_name}")
    if '_id' not in to_save
      return @insert(to_save)
    @update({'_id': to_save['_id']}, to_save, True)
    to_save['id'] || null

  insert: (doc) ->
    if Array.isArray(doc)
      res = @insert(d) for d in doc
      return res
    doc._id = new ObjectId().valueOf() unless doc._id?
    doc = new Document(@, doc._id, doc)
    doc.store()
    @data.sub.push(doc._id.valueOf())
    # TODO: ensure order
    # TODO: insert in other indexes
    @store()
    doc._id

  update: (spec, new_doc, options = null) ->
    cur = @find(spec)
    if options? && options.multi
      while cur.hasNext()
        cur.update(new_doc)
        cur.fetch()
    else
      cur.fetch()
      cur.update(new_doc)
    # TODO: POP from all indexes and reinsert
    # TODO: Do not re-store if indexes where not modified
    @store()

  remove: (spec) ->
    cur = @find(spec)
    while cur.hasNext()
      # TODO: POP from all indexes
      doc = cur.pop()
      doc.destroy()
    @store()

  count: -> @data.sub.length

  col: (col) ->
    throw TypeError if typeof col != "string"
    throw RangeError if not /^[^.$\0]+(\.[^.$\0]+)*$/.test(col)
    return new Collection(@, col)

  drop: Collection::destroy

class Database extends Namespace
  col: (col) ->
    c = Collection::col.call(@ ,col)
    @data.sub.push(col)
    return c

  getCollectionNames: -> @data.sub

class Connection
  constructor: (@store) ->
    @ns = '$'
    @data = @get('.local.system.chongo')
    unless @data? # First time using Chongo
      @data = {}
      @data.hostname = ObjectId.hostname
      @set('.local.system.chongo', @data)

  db: (db) -> new Database(@, db)

  get: (reg) ->
    console.log 'Getting registry ', reg
    v = @store.getItem(@ns+reg)
    v && JSON.parse(v)
  set: (reg, v) ->
    console.log 'Setting registry ', reg, ' to value ', v
    @store.setItem(@ns+reg, JSON.stringify(v))
  del: (reg) ->
    @store.removeItem(@ns+reg)

Chongo = @Chongo =
  'Connection': Connection
  'Database': Database
  'Collection': Collection
  'Update': Update
  'Compare': Compare
  'Query': Query

module?.exports = Chongo
