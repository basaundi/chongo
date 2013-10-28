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
    cur = new Cursor(@, @data.sub, query)
    cur.next()

  count: (query) -> @find(query).count()

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

class Database extends Namespace
  col: (col) -> new Collection(@, col)

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

Pongo = @Pongo =
  'Connection': Connection
  'Database': Database
  'Collection': Collection
  'Update': Update
  'Compare': Compare
  'Query': Query

module?.exports = Pongo
