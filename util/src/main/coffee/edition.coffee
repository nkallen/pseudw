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

class Edition
  constructor: (@citationScheme, @passageSelector, @annotator, @document) ->
    start = new Date
    @dom = new dom.DocumentShim({})
    dfs(@document.get('/TEI.2/text'), domify(@annotator, @dom))
    @passage = selectPassage(@citationScheme, @passageSelector, @dom)
    @parents = parents(@passage)
    console.log("edition", new Date - start)

  find: (selector) ->
    wrap(@dom, @passage, @parents).find(selector)

  dfs = (node, fn, acc) ->
    acc = fn(acc, node)
    for childNode in node.childNodes()
      dfs(childNode, fn, acc)
    acc

  domify = (annotator, document) -> (parent, child) ->
    if child.type() == 'text'
      for annotation in annotator.annotate(child.text())
        element = document.createElement('annotation', annotation.form)
        element.annotation = annotation
        parent.children.push(element) if parent
      null # no accumulator, as text nodes have no children
    else
      attributes = {}
      for attr in child.attrs()
        attributes[attr.name()] = attr.value()
      element = document.createElement(name = child.name(), '', attributes)
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
    result = new Set
    result.add(node = passage)
    while node = node.parentNode
      result.add(node)
    result

  DESCENDENT_OF_PASSAGE = has: (item) -> true
  wrap = (node, passage, parents) ->
    if node == passage
      parents = DESCENDENT_OF_PASSAGE

    find: (selector) ->
      for found in sizzle(selector, node) when parents.has(found)
        wrap(found, passage, parents)
    attr: (name) ->
      node.getAttribute(name)
    text: ->
      node.text
    annotation: ->
      node.annotation
    path: ->
      node.path()

module.exports = Edition
