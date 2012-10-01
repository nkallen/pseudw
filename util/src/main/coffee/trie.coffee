###
A simple Trie-like datastructure
###

class Trie
  class Node
    constructor: (@state) ->
    find: (char) ->
      if next = @state[char]
        new Node(next)
      else null
    value: () -> @state.value
    isLeaf: () -> false
    isBranch: () -> true

  root = {}
 
  put: (str, value) ->
    branch = root
    for char in str
      branch = branch[char] ||= {}

    branch.value = value

  traverse: () -> new Node(root)

  module.exports = Trie