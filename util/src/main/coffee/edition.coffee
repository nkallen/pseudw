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
    @text = @text.get('/TEI.2/text')
    annotate(@text, @annotator)
    @passage = selectPassage(@citationScheme, @passageSelector, @text)
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
    return text if !passageSelector
    passageSelectorParts = passageSelector.split('.')
    passage = text
    for citation, i in citationScheme
      break if i > passageSelectorParts.length - 1

      [tag, attr] = Citation2tag[label = citation.label]
      xpath = ".//#{tag}"
      xpath += "[" + (if attr then "@#{attr}='#{label}' and " else '') + "@n='#{passageSelectorParts[i]}']"
      passage = passage.get(xpath)
      return unless passage
    passage

  parents = (passage) ->
    result = new Set
    node = passage

    result.add(node)
    while node.parent && (node = node.parent())
      result.add(node)
    result

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

module.exports = Edition
