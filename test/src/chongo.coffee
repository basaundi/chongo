describe "Connection", ->
  con = null

  beforeEach () ->
    sessionStorage.clear()
    con = new Chongo.Connection(sessionStorage)

  it "should be able to retrieve databases", ->
    db = con.db('mydb')
    expect(db.constructor).toEqual(Chongo.Database)

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

      it "performs partial updates", ->
        col.insert(docs)
        col.update({}, {$set:{foo:10}})
        cur = col.find()
        expect(cur.next().foo).toEqual(10)
        expect(cur.next().foo).toBeUndefined()
        expect(cur.next().foo).toEqual(-9)
        col.update({}, {$set:{foo:10}}, {multi: true})
        cur = col.find()
        expect(cur.next().foo).toEqual(10)
        expect(cur.next().foo).toEqual(10)
        expect(cur.next().foo).toEqual(10)

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

      it "can load array", ->
        col.insert(docs)
        cur = col.find()
        arr = cur.toArray()
        expect(arr.length).toEqual(3)

      it "stores _id properly", ->
        col.insert(docs)
        o = col.find().next()
        expect(typeof o._id).toEqual("string")
        expect(o._id.length).toEqual(24)
