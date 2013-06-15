fs = require('fs')
_  = require('underscore')

class Annotator
  @EOF: {}
  annotate: (string) ->
    remainder = string
    tokens = []
    while remainder && (remainder = remainder.trim()).length
      [token, remainder] = @one(remainder)
      break unless token
      tokens.push(token)
    [tokens, remainder]
  one: (string) ->
  reset: () ->
  skip: () ->
  update: (position, token) ->
  toJson: () ->


class SimpleAnnotator extends Annotator
  one: (string) ->
    string = string.trim()
    split = string.split(' ')
    token = form: split[0]
    remainder = split[1..].join(' ')
    [token, remainder]
  toJson: () -> {}

class TreebankAnnotator extends Annotator
  constructor: (@treebank) ->
    @reset()
  one: (string) ->
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

class SkippingAnnotator extends Annotator
  constructor: (@annotator) ->
  one: (string) ->
    token = null
    remainder = null
    loop
      [token, remainder] = @annotator.one(string)
      break if token || !@annotator.skip()
        
    [token, remainder]
  reset: () ->
    @annotator.reset()
  skip: () ->
    @annotator.skip()
  update: () ->
    # XXX FIXME
  toJson: () ->
    # XXX FIXME

class FailoverAnnotator extends Annotator
  constructor: (@primaryAnnotator, @secondaryAnnotator) ->
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
