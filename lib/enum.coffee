Enum = (typeName, names...) ->
  values = []
  ids = {}
  id = 0
  class anon
    constructor: (@name, @id) ->
    toJSON: -> @name
    toString: -> @name
    toSymbol: -> @toString()
    @get: (symbol) ->
      if symbol
        this[symbol] || throw new Error("Invalid symbol #{symbol} for Enumeration #{this}")
    @getById: (id) ->
      ids[id] || throw new Error("Invalid id #{id} for Enumeration #{this}")
    @getOrCreate: (symbol) ->
      if symbol
        this[symbol] || @create(symbol)
    @create: (name) ->
      value = new anon(name, id)
      anon[name] = value
      values.push(value)
      ids[id++] = value
      value
    @toSymbol: -> typeName[0].toLowerCase() + typeName[1..-1]
    @toString: -> typeName
    @toBitmap: (elements) ->
      elementsSet = {}
      for element in elements
        elementsSet[element] = true

      result = []
      word = 0
      i = 0
      for value in @values()
        if elementsSet[value]
          word = (word | 1 << (i % 32)) >>> 0
        i++
        if i == 32
          result.push(word)
          word = 0
          i = 0

      result.push(word) if i > 0
      result

  anon.values = -> values
  anon.ids = -> ids

  for name in names
    anon.create(name)
  anon

module.exports = Enum