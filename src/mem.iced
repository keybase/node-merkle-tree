
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
    ret = h.digest().toString('hex')
    ret

  store_node : ({key, obj, obj_s}, cb) ->
    @_nodes[key] = { obj, obj_s }
    cb null

  lookup_node : ({key}, cb) ->
    val = @_nodes[key]
    ret = val?.obj
    err = if ret? then null else new Error 'not found'
    cb err, ret

  lookup_root : (cb) ->
    cb null, @_root

  commit_root : ({key}, cb) ->
    @_root = key
    cb null

#====================================================================
