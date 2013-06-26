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
        {'username':'root', 'password':'toor', 'super': true},
        {'username':'bill', 'password':'1234', 'shell': 'bash'},
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

