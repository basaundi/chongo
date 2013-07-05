describe "Connection", ->
  con = null

  beforeEach () ->
    sessionStorage.clear()
    con = new Pongo.Connection(sessionStorage)

  it "should be able to retrieve databases", ->
    db = con.db('mydb')
    expect(db.constructor).toEqual(Pongo.Database)

  describe "Database", ->
    db = null

    beforeEach () ->
      sessionStorage.clear()
      db = con.db('mydb')

    it "should be able to retrieve collections", ->
      expect(db.col).toBeDefined()
      col = db.col('mycol')
      col.insert({x: 9})
      expect(col.count()).toEqual(1)

    describe "Collection", ->
      col = null
      docs = [
        {'username':'root', 'password':'toor', 'super': true, 'uid': 0},
        {'username':'bill', 'password':'1234', 'shell': 'bash', 'uid': 1004},
        {'foo': -9}
      ]

      beforeEach () ->
        sessionStorage.clear()
        col = db.col('mycol')

      it "can do basic CRUD operations", ->
        expect(col).toBeDefined()
        expect(col.count()).toEqual(0)
        # Create
        col.insert(docs[0])
        expect(col.count()).toEqual(1)
        col.insert(docs[1])
        col.insert(docs[2])
        expect(col.count()).toEqual(3)
        # Read
        cur = col.find()
        expect(cur.next().username).toEqual('root')
        expect(cur.next().shell).toEqual('bash')
        # Update
        col.update({},{'shell':'zsh'})
        cur = col.find()
        expect(cur.next().shell).toEqual('zsh')
        # Delete
        col.remove({})
        expect(col.count()).toEqual(0)

      it "can do batch insert", ->
        col.insert(docs)
        expect(col.count()).toEqual(3)
        cur = col.find()
        expect(cur.next().username).toEqual('root')
        expect(cur.next().shell).toEqual('bash')

      it "can query", ->
        col.insert(docs)
        cur = col.find(username:'bill')
        expect(cur.next().shell).toEqual('bash')
        cur = col.find(uid:{$gt: 100})
        expect(cur.next().uid).toEqual(1004)
        
describe "Query", ->
  a = b = c = null
  beforeEach () ->
    a = {'x': 'y', 'foo': 9, 'bar': "xxx", 'ding': [2,4,8],\
             'dong': -10, 'bang': {'foo': 8}}
    b = {'x': 'y', 'foo': 0, 'bar': "yyy", 'ding': [1,3,5,7],\
             'bang': {'foo': 0, 'lst': [1,2,3]}}
    c = {'x': 'y', 'foo': 1, 'bar': "zzzz", 'ding': [1,3,5,7],\
             'bang': {'foo': 8, 'lst': [1,2,3]}}

  it "empty", ->
    m = Pongo.Query({})
    expect(m(a)).toBe(true)
    expect(m(b)).toBe(true)
    expect(m(c)).toBe(true)
    m = Pongo.Query()
    expect(m(a)).toBe(true)
    expect(m(b)).toBe(true)
    expect(m(c)).toBe(true)
    
  it "scalar equality", ->
    m = Pongo.Query('foo': 9)
    expect(m(a)).toBe(true)
    expect(m(b)).toBe(false)
    expect(m(b)).toBe(false)
    
  it "perform compound queries", ->
    m = Pongo.Query('x': 'y', 'foo': 0)
    expect(m(a)).toBe(false)
    expect(m(b)).toBe(true)
    expect(m(c)).toBe(false)
    
  it "in lists", ->
    m = Pongo.Query('ding': 4)
    expect(m(a)).toBe(true)
    expect(m(b)).toBe(false)
    expect(m(c)).toBe(false)
    
  it "documents", ->
    m = Pongo.Query('bang': {'foo': 8})
    expect(m(a)).toBe(true)
    expect(m(b)).toBe(false)
    expect(m(c)).toBe(false)
    
  it "in nested documents", ->
    m = Pongo.Query('bang.foo': 8)
    expect(m(a)).toBe(true)
    expect(m(b)).toBe(false)
    expect(m(c)).toBe(true)
    
  it "works with $in operator", ->
    m = Pongo.Query('bar': {'$in': ['xxx', 'zzzz']})
    expect(m(a)).toBe(true)
    expect(m(b)).toBe(false)
    expect(m(c)).toBe(true)
    
