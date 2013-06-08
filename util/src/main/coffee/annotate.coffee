###
class Annotate
  annotate: (string) -> [tokens]
  reset: () ->
###

class SimpleAnnotate
  annotate: (string) ->
    for token in string.split(' ')
      form: token
  reset: () -> # stateless, so no-op

class TreebankAnnotate
  constructor: (@treebank) ->
    @reset()
  annotate: (string) ->
    result = []

    while string.length
      annotation = @treebank[@i++]
      form = annotation.originalForm || annotation.form
      if (original = string[0...form.length]) != form
        throw "Original '#{original}' not equal to '#{form}'"
      result.push(annotation)
      string = string[form.length..].trim()
    result

  reset: () ->
    @i = 0

module.exports =
  SimpleAnnotate: SimpleAnnotate
  TreebankAnnotate: TreebankAnnotate
