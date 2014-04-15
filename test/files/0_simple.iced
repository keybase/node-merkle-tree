
main = require '../../src/main'
{ObjFactory} = require './obj_factory'
{Config,MemTree} = main
mem_tree = null
obj_factory = new ObjFactory()

#===============================================================

exports.init = (T,cb) ->
  config = new Config { N : 4, M : 16 }
  mem_tree = new MemTree { config }
  cb()

#===============================================================

exports.do_inserts = (T,cb) ->
  for i in [0...10]
    {key, val} = obj_factory.produce()
    await mem_tree.upsert { key, val }, defer err
    T.no_error err
  cb()
  
#===============================================================

