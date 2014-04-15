
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
  for i in [0...128]
    {key, val} = obj_factory.produce()
    await mem_tree.upsert { key, val }, defer err
    T.no_error err
  cb()
  
#===============================================================

exports.test_by_finding = (T,cb) ->
  for key,val of obj_factory.dump_all()
    await mem_tree.find { key, skip_verify : false }, defer err, val2
    T.no_error err
    T.equal val, val2, "worked for key #{key}"
  cb()

#===============================================================

