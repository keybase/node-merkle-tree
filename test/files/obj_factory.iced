
{prng} = require 'crypto'
exports.skip = true

#===============================================================

exports.ObjFactory = class ObjFactory

  #----------------------------

  constructor : () ->
    @_objs = {}
    @_i = 0

  #----------------------------

  produce : () ->
    key = prng(16).toString 'hex'
    val = [ @_i++, key ]
    @_obj[key] = val
    return { key, val }

#===============================================================

