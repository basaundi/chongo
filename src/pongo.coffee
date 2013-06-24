
class Collection
  constructor: (@storage, @db, @col) ->
    @ns = @db + '.' + @col

class Database
  constructor: (@connection, @db) ->
    @storage = @connection.storage
    try
      @collections = @storage.getItem(@db+'system.namespaces').split(',')
    catch e # TypeError: the collection does not exist.
      @collections = []
  
  col: (collection) ->
    new Collection(@storage, @db, @col)

class Connection
  constructor: (@storage) ->
    @db_names = @storage.db_names
  
  db: (name)->
    new Database(@, name)

Pongo = @Pongo =
  'Connection': Connection
  'Database': Database
  'Collection': Collection
  
module?.exports = Pongo
