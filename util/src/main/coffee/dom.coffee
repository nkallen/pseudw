class ElementShim
  constructor: (@tagName, @text, @attributes) ->
    @nodeName = @tagName
    @attributes ?= {}
    @children = []
    @parentNode = null
  nodeType: 1
  getAttribute: (attribute) ->
    if @attributes.hasOwnProperty(attribute) && @attributes[attribute] != undefined
      @attributes[attribute].toString()
    else
      ''
  compareDocumentPosition: (that) ->
    if this.attributes.id < that.attributes.id
      4
    else
      2
  getElementsByTagName: (name) ->
    if name == "*"
      @children
    else
      child for child in @children when child.tagName == name
  uuid: () -> [@attributes.id, @attributes.sentenceId].toString()

class DocumentShim
  constructor: (@tags) ->
  nodeType: 9
  getElementsByTagName: (name) ->
    if name == "*"
      @tags.all
    else
      @tags[name] || []
  documentElement: do ->
    removeChild: (node) -> # this.tags[node.nodeName].splice(this.tags[node.nodeName].indexOf(node), 1)
  createComment: () -> {}
  createElement: (tagName, text, attributes) ->
    element = new ElementShim(tagName, text, attributes)
    (@tags[tagName] ?= []).push(element)
    element.parentNode = @documentElement
    element.ownerDocument = this
    element
  getElementById: () -> []

module.exports =
  ElementShim: ElementShim
  DocumentShim: DocumentShim
