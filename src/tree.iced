deq = require 'deep-equal'
{json_stringify_sorted} = require('pgp-utils').util
{Lock} = require('iced-utils').lock
{chain_err,make_esc} = require 'iced-error'

##=======================================================================

node_types = 
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

#------------------------------------

JSS = (o) ->
  json_stringify_sorted o, { sort_fn : hex_cmp } 

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
class SortedMap

  #------------------------------------

  constructor : ({obj, list, sorted_list, key, val}) ->
    if obj?
      list = ([k,v] for k,v of obj)
    else if sorted_list?
      @_list = sorted_list

    if key? and val?
      @_list = [ [ key, val] ] 

    if list? and not @_list?
      list.sort (a,b) -> hex_cmp a[0], b[0]
      @_list = l

    if not @_list?
      @_list = []

  #------------------------------------

  slice : (a,b) -> new SortedMap { sorted_list : @_list[a...b] }

  #------------------------------------

  to_hash : ({hasher, type} ) ->
    JS = JSON.stringify
    parts = []
    for [k,v] of @_list
      parts.push [JS(k), JS(v)].join(":")
    tab = parts.join ", "
    """{ "tab" : #{tab}, "type" : type }"""

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
    if @_obj 
    [ index, eq ] = @binary_search { key }
    @_list = @_list[0...index].concat([[key,val]]).concat(@_list[(index+eq)...])
    @

##=======================================================================

class Config

  #---------------------------------

  constructor : ( { @M, @N }) ->
    @C = log_16 @M  # For 256, get 2, etc...

  #---------------------------------
  
##=======================================================================

class MerkleTreeBase

  #---------------------------------
  
  constructor : ({@config}) ->
    @_lock = new Lock

  #---------------------------------

  unimplemented : () -> new Error "unimplemented"

  #---------------------------------

  hasher      : (s)                     -> @unimplemented()
  store_node  : ({key, obj, obj_s}, cb) -> @unimplemented()
  commit_root : ({key},             cb) -> @unimplemented()
  lookup_node : ({key},             cb) -> @unimplemented()
  lookup_root : (                   cb) -> @unimplemented()

  #---------------------------------

  list_to_hash : ({list, type}) ->
    tab = list_to_tab list
    @tab_to_hash { tab, type }

  tab_to_hash : ({tab, type}) ->
    obj = { tab, type }
    @obj_to_hash obj

  obj_to_hash : (obj) ->
    obj_s = JSS obj
    key = @hash obj_s
    { key, obj, obj_s }

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
        curr = shallow_copy curr
        curr.tab[p] = h
        {key, obj, obj_s} = @obj_to_hash curr
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
      {key, obj, obj_s } = @sorted_map.to_hash { hasher : @hasher.bind(@), type : node_types.LEAF }
      await @store_node { key, obj, obj_s }, defer err
    else
      n = (1 << @M)
      j = 0
      tab = []
      for i in [0...n]
        prefix = format_hex i, @const.C
        start = j
        while j < list.length and (@prefix_at_level({ level, obj : list[j] }) is prefix)
          j++
        end = j
        if end > start
          sublist = list[start...end]
          await @hash_tree_r { level : (level+1), list : sublist }, defer err, h
          break if err?
          prefix = @prefix_through_level { level, obj : sublist[0] }
          tab.push [ prefix, h ]
      unless err?
        {key, obj, obj_s} = @list_to_hash { list : tab, type : node_types.INODE }
        await @store_node { key, obj, obj_s }, defer err

    cb err, key

##=======================================================================


