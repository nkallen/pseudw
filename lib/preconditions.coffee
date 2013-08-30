class Preconditions
  @assertType: (instance, type) ->
    unless instance instanceof type
      throw new TypeError("#{instance} must be a #{type}")
    instance
  @assertDefined: (object) ->
    throw new TypeError("#{object} must be defined") unless object
    object
  @assertKeys: (object, validKeys...) ->
  	validKeysHash = {}
  	for key in validKeys
  		validKeysHash[key] = true
  	for key, value of object
  		throw "#{object} contains key #{key} not allowed in #{validKeys}" unless validKeysHash[key]

module.exports = Preconditions