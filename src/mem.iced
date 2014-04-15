
{Base} = require('./tree')
{createHash} = require 'crypto'

#====================================================================

exports.MemTree = class MemTree extends Base

  constructor : (args...) ->
    super args...
    @_root = null
    @_nodes = {}

  hash_fn : (s) -> 
    h = createHash('SHA512')
    h.update(s)
    h.toString 'hex'

  store_node : ({key, obj, obj_s}, cb) ->
    @_nodes[key] = { obj, obj_s }
    cb null

  lookup_node : ({key}, cb) ->
    obj = @_nodes[key]
    err = if obj? then new Error 'not found' else null
    cb err, obj

  lookup_root : (cb) ->
    cb null, @_root

  commit_root : ({key}, cb) ->
    @_root = key
    cb null

#====================================================================
