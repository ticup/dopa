//
// model/util.opa
//
// provides some utility functions that can be used in other modules.
//
// @author: Tim Coppieters
// @date: 01/2013


module Util {

  // given an intmap, creates a unique key for the intmap
  recursive function int createId(intMap) {
    id = Random.int(Limits.max_int)
    exists = IntMap.get(id, intMap)
    Option.lazy_switch(function (_) {createId(intMap)}, function() {id}, exists)
  }
}