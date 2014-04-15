
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
    console.log "store!"
    console.log key
    console.log JSON.stringify obj
    cb null

  lookup_node : ({key}, cb) ->
    console.log "lookup -> #{key}"
    val = @_nodes[key]
    ret = val?.obj
    err = if ret? then null else new Error 'not found'
    console.log " --> #{val?.obj_s}"
    console.log typeof val?.obj
    cb err, ret

  lookup_root : (cb) ->
    cb null, @_root

  commit_root : ({key}, cb) ->
    @_root = key
    cb null

#====================================================================
