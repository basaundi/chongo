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
  find: () ->
    new Cursor(@, @data.sub)

  insert: (doc) ->
    doc._id = new ObjectId() unless doc._id?
    doc = new Document(@, new ObjectId(), doc)
    doc.store()
    @data.sub.push(doc._id.valueOf())
    # TODO: ensure order
    # TODO: insert in other indexes
    @store()

  update: (spec, new_doc) ->
    cur = @find(spec)
    doc = cur.fetch()
    new_doc._id = doc._id
    doc.data = new_doc
    doc.store()
    # TODO: POP from all indexes and reinsert
    # TODO: Do not re-store if indexes where not modified
    @store

  remove: (spec) ->
    cur = @find(spec)
    while cur.hasNext()
      # TODO: POP from all indexes
      doc = cur.pop()
      doc.destroy()
    @store

  count: -> @data.sub.length

class Database extends Namespace
  col: (col) -> new Collection(@, col)

class Connection
  constructor: (@store) ->
    @ns = '$'
    @data = @get('.local.system.pongo')
    unless @data? # First time using Pongo
      @data = {}
      @data.hostname = ObjectId.hostname
      @set('.local.system.pongo', @data)

  db: (db) -> new Database(@, db)

  get: (reg) ->
    console.log 'Getting registry ', reg
    JSON.parse(@store.getItem(@ns+reg))
  set: (reg, v) ->
    console.log 'Setting registry ', reg, ' to value ', v
    @store.setItem(@ns+reg, JSON.stringify(v))
  del: (reg) ->
    @store.removeItem(@ns+reg)

Pongo = @Pongo =
  'Connection': Connection
  'Database': Database
  'Collection': Collection

module?.exports = Pongo
