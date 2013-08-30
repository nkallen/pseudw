dom = require('./dom')
Sizzle = require('./sizzle')

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

sizzle = Sizzle()

# FIXME, refactor into Edition without passage selector, with select method.

class Edition
  @make: (@citationScheme, @passageSelector, @annotator, @document) ->
    start = new Date
    @dom = new dom.DocumentShim({})
    dfs(@document.get('/TEI.2/text'), domify(@annotator, @dom))
    @passage = selectPassage(@citationScheme, @passageSelector, @dom)
    @parents = parents(@passage)
    console.log("edition", new Date - start)
    wrap(@passage)

  dfs = (node, fn, acc) ->
    acc = fn(acc, node)
    for childNode in node.childNodes()
      dfs(childNode, fn, acc)
    acc

  id = 0
  domify = (annotator, document) -> (parent, child) ->
    if child.type() == 'text'
      [annotations, remainder] = annotator.annotate(child.text())
      console.warn("Text not fully annotated: '#{remainder}'") if remainder
      for annotation in annotations
        element = document.createElement('annotation', annotation.form)
        element.annotation = annotation
        element.__id__ = id++
        parent.children.push(element) if parent
      null # no accumulator, as text nodes have no children
    else
      attributes = {}
      for attr in child.attrs()
        attributes[attr.name()] = attr.value()
      element = document.createElement(name = child.name(), '', attributes)
      element.xmlNode = child
      element.xpath = child.path()
      element.__id__ = id++
      if parent
        element.parentNode = parent
        element.parentNode.children.push(element)
      element

  selectPassage = (citationScheme, passageSelector, text) ->
    return text if !passageSelector
    passageSelectorParts = passageSelector.split('.')
    passage = text
    cssSelectorTokens = []
    for citation, i in citationScheme
      break if i > passageSelectorParts.length - 1

      [tag, attr] = Citation2tag[label = citation.label]
      cssSelectorTokens.push(tag + (if attr then "[#{attr}=#{label}]" else '') + "[n=#{passageSelectorParts[i]}]")

    sizzle(cssSelectorTokens.join(" "), passage)[0]

  parents = (passage) ->
    result = {}
    result[(node = passage).__id__] = true
    while node = node.parentNode
      result[node.__id__] = true
    result

  DESCENDENT_OF_PASSAGE = has: (item) -> true
  wrap = (node) ->
    find: (selector) ->
      wrap(found) for found in sizzle(selector, node)
    attr: (name) ->
      node.getAttribute(name)
    text: ->
      node.text
    annotation: ->
      node.annotation
    xml: ->
      node.xmlNode.toString()
    path: ->
      node.xpath
    node: node

module.exports = Edition
