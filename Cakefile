{print} = require 'util'
{spawn} = require 'child_process'

task 'build', 'Build lib/ from src/', ->
  coffee = spawn 'node_modules/.bin/coffee', ['-j', 'lib/pongo.js', '-c', 'src']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

task 'build_tests', 'Build lib/ from src/', ->
  coffee = spawn 'node_modules/.bin/coffee', ['-c', '-o', 'test/spec', 'test/src']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

task 'watch', 'Watch src/ for changes', ->
  coffee = spawn 'node_modules/.bin/coffee', ['-j', 'lib/pongo.js', '-w', '-c', 'src']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
    
  coffee_t = spawn 'node_modules/.bin/coffee', ['-w', '-c', '-o', 'test/spec', 'test/src']
  coffee_t.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee_t.stdout.on 'data', (data) ->
    print data.toString()