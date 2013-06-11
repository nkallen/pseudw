view = (passage, original, parents) ->
  unless original
    original = passage
    return passage if !passage.parent

  unless parents
    parents = new Set
    node = passage

    parents.add(node)
    while node.parent && (node = node.parent())
      parents.add(node)

  find: (path) ->
    for node in passage.find(path) when parents.has(node)
      if node == original
        node
      else
        view(node, original, parents)
  attr: (name) ->
    passage.attr(name)
  text: ->
    passage.text()
  path: ->
    passage.path()

module.exports =
  view: view
