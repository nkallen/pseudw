Enum = (typeName, names...) ->
  class anon
    constructor: (@name) ->
    toJSON: -> @name
    toString: -> @name
    toSymbol: -> @toString()
    @toSymbol: -> typeName.toLowerCase()
    @toString: -> typeName

  values = []
  for name in names
    value = new anon(name)
    anon[name] = value
    values.push(value)

  anon.values = -> values

  anon

module.exports = Enum