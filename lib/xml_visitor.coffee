dfs = (node, fn, acc) ->
  acc = fn(acc, node)
  for childNode in node.childNodes()
    dfs(childNode, fn, acc)
  acc

module.exports =
  visit: (document, fn) ->
    dfs(document.get('/TEI.2/text'), fn)

  visitText: (document, textFn, nodeFn) ->
    @visit(document, (parent, child) ->
      if child.type() == 'text' && parent?.name?() != 'note'
        textFn(parent, child) if child.text().trim() != ''
        null
      else
        nodeFn(parent, child)
    )