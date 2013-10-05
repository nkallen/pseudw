dom = require('./dom')
Sizzle = require('./sizzle')

Citation2Tag =
  article: ['div', 'type']
  section: ['div3']
  chapter: ['div2']
  page: ['milestone', 'unit']
  book: ['div1', 'type']
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

class AnnotatedEdition
  constructor: (@citationScheme, @annotator, @document) ->
    @dom = new dom.DocumentShim()
    dfs(@document.get('/TEI.2/text'), domify(@annotator, @dom))

  select: (passageSelector) ->
    return @dom if !passageSelector

    passageSelectorParts = passageSelector.split('.')
    cssSelectorTokens = []
    for citation, i in @citationScheme
      break if i == passageSelectorParts.length

      [tag, attr] = Citation2Tag[label = citation.label]
      cssSelectorTokens.push(tag + (if attr then "[#{attr}=#{label}]" else '') + "[n=#{passageSelectorParts[i]}]")

    wrap(sizzle(cssSelectorTokens.join(" "), @dom)[0])

  selectFirst: ->
    cssSelectorTokens = []
    for citation, i in @citationScheme[0..-2]
      [tag, attr] = Citation2Tag[label = citation.label]
      cssSelectorTokens.push(tag + (if attr then "[#{attr}=#{label}]" else '') + ":first")
    wrap(sizzle(cssSelectorTokens.join(" "), @dom)[0])

  toc: ->
    [tag, attr] = Citation2Tag[label = @citationScheme[0].label]
    cssSelector = tag + (if attr then "[#{attr}=#{label}]" else '')
    [tag.getAttribute(attr), tag.getAttribute('n')] for tag in sizzle(cssSelector, @dom)

  dfs = (node, fn, acc) ->
    acc = fn(acc, node)
    for childNode in node.childNodes()
      dfs(childNode, fn, acc)
    acc

  domify = (annotator, document) -> (parent, child) ->
    if child.type() == 'text'
      [annotations, remainder] = annotator.annotate(child.text())
      console.warn("Text not fully annotated: '#{remainder}'") if remainder
      parent.annotations = annotations
      null # no accumulator, since text nodes have no children
    else
      attributes = {}
      for attr in child.attrs()
        attributes[attr.name()] = attr.value()
      element = document.createElement(name = child.name(), '', attributes)
      parent.appendChild(element) if parent
      element

  wrap = (node) ->
    find: (selector) ->
      wrap(found) for found in sizzle(selector, node)
    attr: (name) ->
      node.getAttribute(name)
    text: ->
      node.text
    annotations: ->
      node.annotations
    node: node

module.exports = AnnotatedEdition
