// Generated by CoffeeScript 1.6.3
(function() {
  describe("Connection", function() {
    var con;
    con = null;
    beforeEach(function() {
      sessionStorage.clear();
      return con = new Pongo.Connection(sessionStorage);
    });
    it("should be able to retrieve databases", function() {
      var db;
      db = con.db('mydb');
      return expect(db.constructor).toEqual(Pongo.Database);
    });
    return describe("Database", function() {
      var db;
      db = null;
      beforeEach(function() {
        sessionStorage.clear();
        return db = con.db('mydb');
      });
      it("should be able to retrieve collections", function() {
        var col;
        expect(db.col).toBeDefined();
        col = db.col('mycol');
        col.insert({
          x: 9
        });
        return expect(col.count()).toEqual(1);
      });
      return describe("Collection", function() {
        var col, docs;
        col = null;
        docs = [
          {
            'username': 'root',
            'password': 'toor',
            'super': true
          }, {
            'username': 'bill',
            'password': '1234',
            'shell': 'bash'
          }, {
            'foo': -9
          }
        ];
        beforeEach(function() {
          sessionStorage.clear();
          return col = db.col('mycol');
        });
        return it("can do basic CRUD operations", function() {
          var cur;
          expect(col).toBeDefined();
          expect(col.count()).toEqual(0);
          col.insert(docs[0]);
          expect(col.count()).toEqual(1);
          col.insert(docs[1]);
          col.insert(docs[2]);
          expect(col.count()).toEqual(3);
          cur = col.find();
          expect(cur.next().username).toEqual('root');
          expect(cur.next().shell).toEqual('bash');
          col.update({}, {
            'shell': 'zsh'
          });
          cur = col.find();
          expect(cur.next().shell).toEqual('zsh');
          col.remove({});
          return expect(col.count()).toEqual(0);
        });
      });
    });
  });

}).call(this);
