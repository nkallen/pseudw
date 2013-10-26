class ElementShim
  constructor: (@tagName, @text, @attributes) ->
    @nodeName = @tagName
    @attributes ?= {}
    @children = []
  nodeType: 1
  name: -> @tagName
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
      result = []
      result = result.concat(child for child in @children when child.tagName == name)
      for child in @children
        result = result.concat(child.getElementsByTagName(name))
      result
  appendChild: (child) ->
    @children.push(child)
    child.parentNode = this
  uuid: () -> [@attributes.id, @attributes.sentenceId].toString()

class DocumentShim
  constructor: (@tags) ->
    @tags ?= []
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
  clear: () ->
    @tags = []

module.exports =
  ElementShim: ElementShim
  DocumentShim: DocumentShim
