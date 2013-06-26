###
class SimpleIndex extends Array
  insert: (x) ->
    @.push(x._id)
    if x._id > @max
      @max = x._id
    else # Uncommon for ObjectId
      @.sort()
  ###

###
IndexedCollection =
  # Indexes #
  create_index: (key_or_list) ->
    throw 'Not implemented'

  ensure_index: (key_or_list) ->
    throw 'Not implemented'

  drop_index: (index_name) ->
    throw 'Not implemented'

  drop_indexes: () ->
    throw 'Not implemented'

class SimpleIndex
  constructor: (arr) ->
    @arr = arr

  insert: (x) ->
    @arr.push(x._id)
    @length = @arr.length
    if x._id > @max
      @max = x._id
    else # Uncommon for ObjectId
      @arr.sort()

class Collection
  constructor: (@database, @name, create=false) ->
    @ns = @database.name + '.' + @name
    @main_index = @database.connection.get(@ns) || []
    @main_index = new SimpleIndex(@main_index)

  # CRUD #
  save: (to_save) ->
    type_name = Object.prototype.toString.call(to_save)
    if type_name isnt '[object Object]'
      throw new TypeError("cannot save object of type #{type_name}")
    if '_id' not in to_save
      return @insert(to_save)
    @update({'_id': to_save['_id']}, to_save, True)
    to_save['id'] || null

  insert: (doc_or_docs) ->
    docs = doc_or_docs
    if not Array.isArray(docs)
      return_one = true
      docs = [docs]

    for doc in docs
      @_fix_and_insert(doc)

    if return_one
      return docs[0]._id || null
    else
      return (doc._id for doc in docs)

  update: (query, update, upsert=False, multi=False) ->
    document = @database.fix_incoming(update, @)
    # TODO:

  remove: (query, just_one=false) ->
    throw 'Not implemented'

  find: (spec=null, fields = null, skip = 0, limit = 0) ->
    throw 'Not implemented'

  findOne: (spec_or_id=null) ->
    throw 'Not implemented'

  find_and_modify: (query={}, update=null, upsert=false, sort=null) ->
    throw 'Not implemented'

  # cursor op #
  count: () -> return @main_index.length

  distinct: (key) ->
    # TODO: Maybe cache?
    throw 'Not implemented'

  # management #
  rename: (new_name) ->
    # TODO: rename documents and indexes
    throw 'Not implemented'

  drop: ()->
    # TODO: delete documents and indexes
    throw 'Not implemented'

  # mapReduce #
  map_reduce: (map, reduce, out) ->
    throw 'Not implemented'

  inline_map_reduce: (map, reduce) ->
    throw 'Not implemented'


class Database
  constructor: (@connection, @name) ->

  col: (collection) ->
    new Collection(@, @col)

  collection_names: ()->
    try
      collections = @connection.get(@name, 'system.namespaces')
    catch e # TypeError: the collection does not exist.
      collections = []
    collections

  drop_collection: (col)->
    # FIXME: Drop items and indexes
    @connection.del(@name, col)

class ObjectId_ extends Number
  @inc: ~~(Math.random() * 0xFFFFFF)
  @getInc: () ->
    v = @inc
    @inc = (@inc + 1) % 0xFFFFFF
    v

  @generate: (hostname, pid) ->
    v  = ((new Date).getTime() / 1000) << 8
    v += hostname << 5
    v += pid << 3
    v += @getInc()

  toString: () -> 'ObjectId("' + @valueOf() +'")'
  valueOf: () -> super.toString(16)
  generationTime: () ->
    throw 'Not implemented'

class Connection
  constructor: (@storage) ->
    @startup_log = @get('local', 'startup_log')
    if not @startup_log?
      @startup_log = { 'hostname' : ~~(Math.random() * 0xFFFFFF) }
    else
      @startup_log = @startup_log[0]
    @startup_log.pid = ~~(Math.random() * 0xFFFF)
    @set('local', 'startup_log', [@startup_log])

  get: (db, collection) ->
    JSON.parse(@storage.getItem(db, collection))

  set: (db, collection, v) ->
    @storage.setItem(db, collection, JSON.stringify(v))

  del: (db, collection) ->
    @storage.removeItem(db, collection)

  db: (name)->
    new Database(@, name)

  database_names: ()->
    try
      databases = @connection.get('local', 'system.databases')
    catch e # TypeError: the collection does not exist.
      databases = []
    databases

  drop_database: (db) ->
    # TODO: drop all collections with indexes.
    throw 'Not implemented'

  copy_database: (from_name, to_name) ->
    # TODO: copy all collections.
    # TODO: copy_collection.
    throw 'Not implemented'

  ObjectId: (hex=null)->
    if hex?
      v = parseInt(hex, 16)
      v.prototype = ObjectId_
    else v = ObjectId_.generate(@startup_log.hostname, @startup_log.pid)
    v
###
