fs = require('fs')
_  = require('underscore')

###
  class Annotator
    annotate: (string) -> [[tokens], remainder]
    reset: () -> ()
    update: (position, token) -> ()
    toJson: () -> {}
  
  Note: update performs PARTIAL updates.
###

class SimpleAnnotator
  annotate: (string) ->
    tokens = for token in string.split(' ')
      form: token
    [tokens, null]
  one: (string) ->
    string = string.trim()
    split = string.split(' ')
    token = form: split[0]
    remainder = split[1..].join(' ')
    [token, remainder]
  reset: () -> # stateless, so no-op
  skip: (n) -> # stateless, so no-op
  update: () -> # stateless, so no-op
  toJson: () -> {}

class TreebankAnnotator
  constructor: (@treebank) ->
    @reset()
  annotate: (string) ->
    result = []

    while (string = string.trim()).length
      annotation = @treebank[@i]
      form = annotation.originalForm || annotation.form
      if (original = string[0...form.length]) != form
        return [result, string]
      annotation.__position__ = @i++
      result.push(annotation)
      string = string[form.length..]
    [result, null]

  one: (string) ->
    string = string.trim()
    annotation = @treebank[@i]
    form = annotation.originalForm || annotation.form
    if (original = string[0...form.length]) != form
      return [null, string]
    annotation.__position__ = @i++
    remainder = string[form.length..]
    [annotation, remainder]
  reset: () ->
    @i = 0

  skip: () ->
    ++@i < @treebank.length

  update: (position, token) ->
    _.extend(@treebank[position], token)

  toJson: () ->
    @treebank

  toString: () ->
    JSON.stringify(@treebank)

class SkippingAnnotator
  constructor: (@annotator) ->
  annotate: (string) ->
    result = []
    remainder = string
    while remainder && remainder.length
      [tokens, remainder] = @annotator.annotate(string)
      result = result.concat(tokens)
      break unless @annotator.skip()
    [result, null]
  reset: () ->
    @annotator.reset()
  skip: () ->
    @annotator.skip()
  update: () ->
    # XXX FIXME
  toJson: () ->
    # XXX FIXME

class FailoverAnnotator
  constructor: (@primaryAnnotator, @secondaryAnnotator) ->
  annotate: (string) ->
    result = []
    remainder = string
    while remainder && remainder.length
      [token, remainder] = @one(remainder)
      result.push(token)
    [result, remainder]
  one: (string) ->
    [token, remainder] = @primaryAnnotator.one(string)
    [token, remainder] = @secondaryAnnotator.one(remainder) unless token
    [token, remainder]
  reset: () ->
    @primaryAnnotator.reset()
    @secondaryAnnotator.reset()
  skip: () ->
    @primaryAnnotator.skip()
    @secondaryAnnotator.skip()
  update: () ->
    # XXX FIXME
  toJson: () ->
    # XXX FIXME

class TreebankAnnotatorIndex
  @load: (dir) ->
    resources = {}
    for file in fs.readdirSync(dir)
      pid = 'Perseus:text:' + file.replace('.json', '')
      resources[pid] = dir + '/' + file

    new TreebankAnnotatorIndex(resources)

  constructor: (@resources) ->

  pid: () ->
    pid = arguments[0]
    next = arguments[arguments.length - 1]
    return next("resource not found") unless resource = @resources[pid]

    if arguments.length == 2
      fs.readFile(resource, (err, file) ->
        return next(err) if err

        start = new Date
        json = JSON.parse(file)
        console.log("Treebank load", new Date - start)
        next(null, new TreebankAnnotator(json)))
    else
      annotator = arguments[1]
      fs.writeFile(resource, annotator.toString(), (err) ->
        next(err))

module.exports =
  SimpleAnnotator: SimpleAnnotator
  TreebankAnnotator: TreebankAnnotator
  SkippingAnnotator: SkippingAnnotator
  FailoverAnnotator: FailoverAnnotator
  TreebankAnnotatorIndex: TreebankAnnotatorIndex
