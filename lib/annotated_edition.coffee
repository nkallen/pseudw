Dom = require('./dom')
xmlVisitor = require('./xml_visitor')
Citation = require('./citation')

class AnnotatedEdition
  constructor: (citationScheme, annotator, document) ->
    dom = new Dom.DocumentShim()
    xmlVisitor.visitText(document, processText(annotator), processNode(dom))
    @citation = new Citation(dom, citationScheme)

  select: (selector) ->
    @citation.select(selector)

  selectFirst: () ->
    @citation.selectFirst()

  processText = (annotator) -> (parent, child) ->
    [annotations, remainder] = annotator.annotate(child.text())
    console.warn("Text not fully annotated: '#{remainder}'") if remainder
    parent.annotations = annotations

  processNode = (document) -> (parent, child) ->
    attributes = {}
    for attr in child.attrs()
      attributes[attr.name()] = attr.value()
    element = document.createElement(name = child.name(), '', attributes)
    parent.appendChild(element) if parent
    element

module.exports = AnnotatedEdition
