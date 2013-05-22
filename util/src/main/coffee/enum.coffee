Enum = (typeName, names...) ->
  class anon
    constructor: (@name, @id) ->
    toJSON: -> @name
    toString: -> @name
    toSymbol: -> @toString()
    @toSymbol: -> typeName.toLowerCase()
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

  values = []
  id = 0
  for name in names
    value = new anon(name, id++)
    anon[name] = value
    values.push(value)

  anon.values = -> values

  anon

module.exports = Enum