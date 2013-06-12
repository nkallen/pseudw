Citation2tag =
  article: ['div', 'type']
  section: ['milestone', 'unit']
  chapter: ['milestone', 'unit']
  page: ['milestone', 'unit']
  book: ['div', 'type']
  text: ['text']
  line: ['l']
  scene: ['div', 'type']
  act: ['div', 'type']
  entry: ['div', 'type']
  card: ['milestone', 'unit']
  speech: ['div', 'type']
  root: ['div', 'type']
  poem: ['div', 'type']

class Edition
  constructor: (@citationScheme, @passageSelector, @annotator, @text) ->
    annotate(@text, @annotator)
    @passage = selectPassage(@text, @citationScheme, @passageSelector)
    @parents = parents(@passage)

  find: (path) ->
    wrap(@text, @passage, @parents).find(path)

  annotate = (text, annotator) ->
    stack = [@text]
    while node = stack.pop()
      for childNode in node.childNodes
        cursor = childNode
        if childNode.name() == 'text'
          for annotation in annotator.annotate(childNode.text())
            annotationNode = childNode.node('annotation', annotation.form)
            annotationNode.attr(annotation)
            cursor.addNextSibling(annotationNode)
          childNode.remove()
        else
          stack.push(childNode)

  selectPassage = (citationScheme, passageSelector, text) ->
    return xml if !passageSelector
    return unless text = xml.get('/TEI.2/text')
    passageSelectorParts = passageSelector.split('.')
    passage = text
    for citation, i in citationMapping
      break if i > passageSelectorParts.length - 1

      [tag, attr] = Citation2tag[label = citation.label]
      xpath = ".//#{tag}"
      xpath += "[" + (if attr then "@#{attr}='#{label}' and " else '') + "@n='#{passageSelectorParts[i]}']"
      node = text.get(xpath)
      return unless node
    node

  parents = (passage) ->
    parents = new Set
    node = passage

    parents.add(node)
    while node.parent && (node = node.parent())
      parents.add(node)
    parents

  wrap = (node, passage, parents) ->
    find: (path) ->
      for found in passage.find(path) when parents.has(found)
        if found == passage
          passage
        else
          wrap(found, passage, parents)
    attr: (name) ->
      node.attr(name)
    text: ->
      node.text()
    path: ->
      node.path()

module.exports =
  Edition: Edition
