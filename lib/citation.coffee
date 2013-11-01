sizzle = require('./sizzle')()

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

class Level
  constructor: (@label, @parent) ->
    @sections = []
  push: (name, isCurrent) ->
    @sections.push(name)
    if isCurrent
      @currentPos = @sections.length - 1
      @current = name
  cite: (name) ->
    name ||= @sections[@currentPos]
    if @parent
      @parent.cite() + '.' + name
    else
      name
  forEach: (f) ->
    self = this
    @sections.forEach((name) ->
      f(name: name, citation: self.cite(name))
    )
  next: ->
    return unless @currentPos < @sections.length - 1
    @cite(@sections[@currentPos + 1])
  prev: ->
    return unless @currentPos > 0
    @cite(@sections[@currentPos - 1])

class Toc
  constructor: ->
    @levels = []
    @levelsByLabel = {}

  section: (label, name, isCurrent) ->
    unless level = @levelsByLabel[label]
      level = new Level(label, @levels[@levels.length - 1])
      @levelsByLabel[label] = level
      @levels.push(level)
    level.push(name, isCurrent)

  forEach: (f) ->
    @levels.forEach(f)

  next: ->
    next = null
    i = @levels.length - 1
    loop
      return if i < 0
      break if next = @levels[i--].next()
    pad(next, @levels.length, ':first')

  prev: ->
    prev = null
    i = @levels.length - 1
    loop
      return if i < 0
      break if prev = @levels[i--].prev()
    pad(prev, @levels.length, ':last')

  pad = (citation, depth, padding) ->
    parts = citation.split('.')
    for i in [0...depth - parts.length]
      parts.push(padding)
    parts.join('.')

class Citation
  constructor: (@dom, @citationScheme) ->

  selectFirst: () ->
    @select(':first')

  select: (passageSelector) ->
    parts = passageSelector.split('.')
    tokens = []
    toc = new Toc
    for part, i in parts
      citation = @citationScheme[i]
      [tag, attr] = Citation2Tag[citation.label]
      token = tag + (if attr then "[#{attr}=#{citation.label}]" else '')

      sections = sizzle((tokens.concat([token])).join(" "), @dom)
      for section, i in sections
        n = section.getAttribute('n')
        isCurrent = part == n || part == ':first' && i == 0 || part == ':last' && i == sections.length - 1
        toc.section(citation.label, n, isCurrent)

      token += if /^:/.test(part) then part else "[n=#{part}]"
      tokens.push(token)

    selection = wrap(sizzle(tokens.join(" "), @dom)[0])
    selection.toc = toc

    selection

  wrap = (node) ->
    find: (selector) ->
      wrap(found) for found in sizzle(selector, node)
    attr: (name) ->
      node.getAttribute(name)
    text: ->
      node.text
    annotations: ->
      node.annotations || []
    node: node

module.exports = Citation