Enum = (typeName, names...) ->
  class anon
    constructor: (@name) ->
    toJSON: -> @name

  for name in names
    anon[name] = new anon(name)

  anon.toString = -> typeName
  anon

module.exports = Enum