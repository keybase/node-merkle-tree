
{Lock} = require('iced-utils').lock
{chain_err,make_esc} = require 'iced-error'

##=======================================================================

exports.node_types = node_types = 
  NONE : 0
  INODE : 1
  LEAF : 2

##=======================================================================

log_16 = (y) ->
  ret = 0
  while y > 1
    y = (y >> 4)
    ret++
  return ret

#-------------------------

shallow_copy = (obj) ->
  tab = {}
  ret = { type : obj.type, tab }
  for k,v of obj.tab
    tab[k] = v
  return ret

#------------------------------------

format_hex = (i, len) ->
  buf = new Buffer 4
  buf.writeUInt32BE i, 0
  buf.toString('hex')[(8 - len)...]

#------------------------------------

list_to_tab = (list) ->
  tab = {}
  for pair in list
    tab[pair[0]] = pair[1]
  return tab

#------------------------------------

tab_to_list = (tab) -> ([k,v] for k,v of tab)

#----------------------------------

hex_len = (a) ->
  ret = a.length
  for c in a
    if c is '0' then ret--
    else break
  return ret

#----------------------------------

map = {
  0 : 0, 1 : 1, 2 : 2 , 3 : 3, 4 : 4, 5 : 5, 6 : 6, 7 : 7,
  8 : 8, 9 : 9, a : 10, b : 11, c : 12, d : 13, e : 14, f : 15 
}

#----------------------------------

hex_cmp = (a,b) ->
  a_len = hex_len(a)
  b_len = hex_len(b)
  ret = if a_len > b_len then 1
  else if a_len < b_len then -1
  else
    tmp = 0
    for c,i in a
      d = b[i]
      if map[c] > map[d] then tmp = 1
      else if map[c] < map[d] then tmp = -1
      break if tmp isnt 0
    tmp
  ret

##=======================================================================

# A sorted key-value map
exports.SortedMap = class SortedMap

  #------------------------------------

  constructor : ({node, obj, list, sorted_list, key, val}) ->
    if node?
      obj = node.tab
      @_type = node.type
    if obj?
      list = ([k,v] for k,v of obj)
    else if sorted_list?
      @_list = sorted_list

    if key? and val?
      @_list = [ [ key, val] ] 

    if list? and not @_list?
      sorted = true
      for i in [0...list.length]
        j = i + 1
        if (j < list.length) and (hex_cmp(list[i][0], list[j][0])) > 0
          sorted = false
          break
      unless sorted
        list.sort (a,b) -> hex_cmp a[0], b[0]
      @_list = l

    if not @_list?
      @_list = []

  #------------------------------------

  slice : (a,b) -> new SortedMap { sorted_list : @_list[a...b] }
  len : () -> @_list.length
  at : (i) -> @_list[i]

  #------------------------------------

  to_hash : ({hasher, type} ) ->
    JS = JSON.stringify
    type or= @_type
    parts = []
    tab = {}
    for [k,v] in @_list
      parts.push [JS(k), JS(v)].join(":")
      tab[k] = v
    tab = "{" + parts.join(",") + "}"
    obj_s """{"tab":#{tab},"type":#{type}}"""
    obj = { tab, type }
    hash = hasher(obj_s)
    return { hash, obj, obj_s }

  #------------------------------------

  binary_search : ({key}) ->
    beg = 0
    end = @_list.length - 1

    while beg < end
      mid = (end - beg) >> 1
      c = hex_cmp key, @_list[mid][0]
      if c > 0
        beg = mid + 1
      else if c < 0
        end = mid

    c = hex_cmp key, @_list[beg][0]

    eq = 0
    ret = if c > 0 then beg + 1
    else if c is 0
      eq = 1
      beg
    else beg

    return [ beg, eq ]

  #------------------------------------

  replace : ({key, val}) ->
    [ index, eq ] = @binary_search { key }
    @_list = @_list[0...index].concat([[key,val]]).concat(@_list[(index+eq)...])
    @

##=======================================================================

exports.Config = class Config

  #---------------------------------

  # @M - the number of children per node.
  # @N - the maxium number of leaves before we resplit.
  constructor : ( { @M, @N }) ->
    # If we have 2^M children per node, how many hex chars does it take to
    # represent it?
    @C = Math.ceil(@M/4) 

  #---------------------------------
  
##=======================================================================

exports.Base = class Base

  #---------------------------------
  
  constructor : ({@config}) ->
    @_lock = new Lock
    @hasher = @hash_fn.bind(@)

  #---------------------------------

  unimplemented : () -> new Error "unimplemented"

  #---------------------------------

  hash_fn     : (s)                     -> @unimplemented()
  store_node  : ({key, obj, obj_s}, cb) -> @unimplemented()
  commit_root : ({key},             cb) -> @unimplemented()
  lookup_node : ({key},             cb) -> @unimplemented()
  lookup_root : (                   cb) -> @unimplemented()

  #-----------------------------------------

  obj_to_key : (o) -> o[0]

  prefix_at_level : ({level, key, obj}) -> 
    key or= @obj_to_key obj
    key[(level*@C)...(level+1)*@C]

  prefix_through_level : ({level, key, obj}) -> 
    key or= @obj_to_key obj
    key[0...(level+1)*@C]

  #-----------------------------------------

  unlock : (cb) ->
    @_lock.release()
    cb null

  #-----------------------------------------

  upsert : ({key, val}, cb) ->

    # All happens with a lock
    cb = chain_err cb, @unlock.bind(@)
    esc = make_esc cb, "full_build"
    await @_lock.acquire defer()

    # Now find the root
    await @lookup_root defer root
    curr = null
    if root?
      await @lookup_node { key : root }, esc defer curr

    last = null
    path = []

    # Find the path from the key up to the root
    while curr?
      p = @prefix_through_level { key, level : path.length }
      path.push [ p, curr ] 
      last = curr
      if (nxt = curr.tab[p])?
        await @lookup_node { key : nxt }, esc defer curr
      else
        curr = null

    # Figure out what to store at the node where we stopped going
    # down the path.
    [sorted_map, level] = if not last?
      [ (new SortedMap { key, val }), path.length ]
    else if last.type is node_types.INODE
      [ (new SortedMap { key, val }), path.length + 1]
    else if not((v2 = last.tab[key])?) or not(deq(val, v2))
      [ (new SortedMap { obj : last.tab }).replace({key,val}), path.length ]
    else [ null, 0 ]

    if store_list?
      # Store the leaf
      await @hash_tree_r { level, sorted_map }, esc defer h

      # Store back up to the root
      path.reverse()
      for [ p, curr ] in path when (curr.type is node_types.INODE)
        sm = (new SortedMap { node : curr }).replace { key : p, val : h }
        {key, obj, obj_s} = sm.to_hash { @hasher }
        h = key
        await @store_node { key, obj, obj_s }, esc defer()

      # It's always safe to back up until we store the root
      await @commit_root h, esc defer()

    cb null

  #-----------------------------------------

  hash_tree_r : ({level, sorted_map }, cb) ->
    err = null
    key = null

    if list.length < @const.N
      {key, obj, obj_s} = sorted_map.to_hash { @hasher, type : node_types.LEAF }
      await @store_node { key, obj, obj_s }, defer err
    else
      M = (1 << @const.M) # the number of children we have
      C = @const.C        # the number of characters needed to represent it
      j = 0
      new_sorted_map = new SortedMap {}
      for i in [0...M]
        prefix = format_hex i, C
        start = j
        while j < sorted_map.len() and (@prefix_at_level({ level, obj : sorted_map.at(j) }) is prefix)
          j++
        end = j
        if end > start
          sublist = sorted_map[start...end]
          await @hash_tree_r { level : (level+1), sorted_map : sublist }, defer err, h
          break if err?
          prefix = @prefix_through_level { level, obj : sublist.at(0) }
          new_sorted_map.push { key : prefix, val : h }
      unless err?
        {key, obj, obj_s} = new_sorted_map.to_hash { @hasher, type : node_types.INODE }
        await @store_node { key, obj, obj_s }, defer err

    cb err, key

##=======================================================================


