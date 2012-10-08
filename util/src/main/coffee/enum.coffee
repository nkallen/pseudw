Enum = (typeName, names...) ->
  class anon
    constructor: (@name) ->
    toJSON: -> @name
    toString: -> @name
    toSymbol: -> @toString()
    @toSymbol: -> typeName.toLowerCase()
    @toString: -> typeName

  for name in names
    anon[name] = new anon(name)

  anon

module.exports = Enum