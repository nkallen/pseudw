Enum = (typeName, names...) ->
  class anon
    constructor: (@name) ->
    toJSON: -> @name
    toString: -> @name
    toSymbol: -> toString.toLowerCase() # XXX does not convert camelcase to dash
    @toSymbol: -> @toString.toLowerCase()

  for name in names
    anon[name] = new anon(name)

  anon.toString = -> typeName
  anon

module.exports = Enum