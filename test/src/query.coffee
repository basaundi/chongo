
describe "Compare", ->
  a = b = c = d = e = null
  beforeEach () ->
    a = {'x': 'y', 'foo': 9, 'bar': "xxx", 'ding': [2,4,8],\
            'dong': -10, 'bang': {'foo': 8}}
    b = {'x': 'y', 'foo': 0, 'bar': "yyy", 'ding': [1,3,5,7],\
            'bang': {'foo': 0, 'lst': [1,2,3]}}
    c = {'type': 'tool', 'x': 'y', 'foo': 1, 'bar': "zzzz",\
          'ding': [1,3,5,7],\
          'bang': {'foo': 8, 'lst': [1,2,3]}}
    d = {'type': 'food', qty: 354, price: 5.95}
    e = {'type': 'food', qty: 254, price: 10.32}

  it "can do simple comparisons", ->
    C = Pongo.Compare({foo: 1})
    expect(C(a, b)).toEqual(1)  # 9 > 0
    expect(C(b, c)).toEqual(-1) # 0 < 1
    expect(C(c, d)).toEqual(1)  # 1 > undefined
    expect(C(d, e)).toEqual(0)  # undefined = undefined
    C = Pongo.Compare({bang: -1})
    expect(C(a,b)).toEqual(1)
    expect(C(b,c)).toEqual(-1)
    C = Pongo.Compare({type: 1, qty: -1})
    expect(C(c,d)).toEqual(1)
    expect(C(d,e)).toEqual(1)

describe "Update", ->
  joe = a = b = c = d = e = null
  beforeEach () ->
    a = {'x': 'y', 'foo': 9, 'bar': "xxx", 'ding': [2,4,8],\
             'dong': -10, 'bang': {'foo': 8}}
    b = {'x': 'y', 'foo': 0, 'bar': "yyy", 'ding': [1,3,5,7],\
             'bang': {'foo': 0, 'lst': [1,2,3]}}
    c = {'x': 'y', 'foo': 1, 'bar': "zzzz", 'ding': [1,3,5,7],\
             'bang': {'foo': 8, 'lst': [1,2,3]}}
    d = {'type': 'food', qty: 354, price: 5.95}
    e = {'type': 'food', qty: 254, price: 10.32}
    joe =
      "_id": 3,
      "name": "joe",
      "quizzes": [
        { "id" : 1, "score" : 6 },
        { "id" : 2, "score" : 9 }
      ]

  it "$set s elements", ->
    Pongo.Update('$set', {'foo': 'z'}, a)
    Pongo.Update('$set', {'foo': 'z'}, b)
    Pongo.Update('$set', {'foo': 'z'}, c)
    Pongo.Update('$set', {'foo': 'z'}, d)
    Pongo.Update('$set', {'foo': 'z'}, e)
    expect(a.foo).toEqual('z')
    expect(b.foo).toEqual('z')
    expect(c.foo).toEqual('z')
    expect(d.foo).toEqual('z')
    expect(e.foo).toEqual('z')

  it "does $push-$each-$short-$slice", ->
    res =
      "_id" : 3,
      "name" : "joe",
      "quizzes" : [
        { "id" : 1, "score" : 6 },
        { "id" : 5, "score" : 6 },
        { "id" : 4, "score" : 7 },
        { "id" : 3, "score" : 8 },
        { "id" : 2, "score" : 9 }
      ]
    Pongo.Update('$push', {
      quizzes: {
        $each: [
          { id: 3, score: 8 },
          { id: 4, score: 7 },
          { id: 5, score: 6 } ],
        $sort: { score: 1 },
        $slice: -5
      }
    }, joe)
    expect(joe).toEqual(res)

describe "Query", ->
  a = b = c = d = e = null
  beforeEach () ->
    a = {'x': 'y', 'foo': 9, 'bar': "xxx", 'ding': [2,4,8],\
             'dong': -10, 'bang': {'foo': 8}}
    b = {'x': 'y', 'foo': 0, 'bar': "yyy", 'ding': [1,3,5,7],\
             'bang': {'foo': 0, 'lst': [1,2,3]}}
    c = {'x': 'y', 'foo': 1, 'bar': "zzzz", 'ding': [1,3,5,7],\
             'bang': {'foo': 8, 'lst': [1,2,3]}}
    d = {'type': 'food', qty: 354, price: 5.95}
    e = {'type': 'food', qty: 254, price: 10.32}

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
    expect(m(c)).toBe(false)

  it "with regex", ->
    m = Pongo.Query('bar': /^z+$/)
    expect(m(a)).toBe(false)
    expect(m(b)).toBe(false)
    expect(m(c)).toBe(true)

  it "perform compound queries", ->
    m = Pongo.Query('x': 'y', 'foo': 0)
    expect(m(a)).toBe(false)
    expect(m(b)).toBe(true)
    expect(m(c)).toBe(false)

  it "in arrays", ->
    m = Pongo.Query('ding': 4)
    expect(m(a)).toBe(true)
    expect(m(b)).toBe(false)
    expect(m(c)).toBe(false)
    m = Pongo.Query('ding.1': 3)
    expect(m(a)).toBe(false)
    expect(m(b)).toBe(true)
    expect(m(c)).toBe(true)

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

  it "works with $or operator", ->
    m = Pongo.Query('$or': [{'bar': 'xxx'},{'bar': 'zzzz'}])
    expect(m(a)).toBe(true)
    expect(m(b)).toBe(false)
    expect(m(c)).toBe(true)

  it "works with complex queries", ->
    m = Pongo.Query({ type: 'food', $or: [{ qty:   { $gt: 100  }},
                                          { price: { $lt: 9.95 }}]})
    expect(m(a)).toBe(false)
    expect(m(b)).toBe(false)
    expect(m(c)).toBe(false)
    expect(m(d)).toBe(true)
    expect(m(e)).toBe(true)
    m = Pongo.Query({ type: 'food', $and: [{ qty:   { $gt: 100  }},
                                          { price: { $lt: 9.95 }}]})
    expect(m(a)).toBe(false)
    expect(m(b)).toBe(false)
    expect(m(c)).toBe(false)
    expect(m(d)).toBe(true)
    expect(m(e)).toBe(false)
