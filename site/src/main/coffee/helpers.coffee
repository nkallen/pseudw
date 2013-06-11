view = (passage, original, parents) ->
  unless parents
    parents = new WeakMap
    node = passage
    parents.set(node)
    while node.parent && (node = node.parent())
      parents.set(node)
  unless original
    original = passage

  find: (path) ->
    for node in passage.find(path) when parents.has(node)
      if node == original
        node
      else
        view(node, passage, parents)
  attr: (name) ->
    passage.attr(name)
  text: ->
    passage.text()
  path: ->
    passage.path()

module.exports =
  view: view