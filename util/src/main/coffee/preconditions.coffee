class Preconditions
  @assertType: (instance, type) ->
    unless instance instanceof type
      throw new TypeError("#{instance} must be a #{type}")
    instance
  @assertDefined: (object) ->
    throw new TypeError("#{object} must be defined") unless object?
    object

module.exports = Preconditions