describe("Pongo", function() {
	var con;
	var db;
	
	beforeEach(function() {
		con = new Pongo.Connection(sessionStorage);
	});
	
	it("it should be able to retrieve databases", function() {
		db = con.db('mydb')
		expect(db.constructor).toEqual(pongo.Database);
	});

})