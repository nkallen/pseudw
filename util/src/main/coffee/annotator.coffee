fs = require('fs')
_  = require('underscore')

class Annotator
  annotate: (string) ->
    remainder = string
    tokens = []
    while remainder && (remainder = remainder.trim()).length && !@eof()
      [token, remainder] = @one(remainder)
      break unless token
      tokens.push(token)
    [tokens, remainder]
  one: (string) ->
  eof: () -> false
  reset: (pos) ->
  skip: () ->
  pos: () -> 0
  update: (position, token) ->
  toJson: () ->


class SimpleAnnotator extends Annotator
  one: (string) ->
    split = string.split(' ')
    token = form: split[0]
    remainder = split[1..].join(' ')
    [token, remainder]
  toJson: () -> {}

class TreebankAnnotator extends Annotator
  constructor: (@treebank) ->
    @reset()
  one: (string) ->
    throw "EOF" if @eof()

    annotation = @treebank[@i]
    form = annotation.originalForm || annotation.form
    if (original = string[0...form.length]) != form
      return [null, string]
    annotation.__position__ = @i++
    remainder = string[form.length..]
    [annotation, remainder]

  reset: (pos) -> @i = pos || 0

  skip: () -> @i++

  eof: () -> @i > @treebank.length - 1

  pos: () -> @i

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
      if token
        @lastPos = @annotator.pos()
        break

      @annotator.skip()

      if @annotator.eof()
        @annotator.reset(@lastPos)
        break
        
    [token, remainder]
  reset: (pos) ->
    @annotator.reset(pos)
  skip: () ->
    @annotator.skip()
  eof: () ->
    @annotator.eof()
  pos: () ->
    @annotator.pos()
  update: () ->
    @annotator.update(position, token)
  toJson: () ->
    # XXX FIXME

class FailoverAnnotator extends Annotator
  constructor: (@primaryAnnotator, @secondaryAnnotator) ->
  one: (string) ->
    throw "EOF" if @eof()

    unless @primaryAnnotator.eof()
      [token, remainder] = @primaryAnnotator.one(string)

    if !token && !@secondaryAnnotator.eof()
      [token, remainder] = @secondaryAnnotator.one(remainder)
    [token, remainder]
  reset: (pos) ->
    @primaryAnnotator.reset(pos)
    @secondaryAnnotator.reset(pos)
  skip: () ->
    @primaryAnnotator.skip()
    @secondaryAnnotator.skip()
  eof: () ->
    @primaryAnnotator.eof() && @secondaryAnnotator.eof()
  pos: () ->
    @primaryAnnotator.pos()
  update: () ->
    @primaryAnnotator.update(position, token)
  toJson: () ->
    # XXX FIXME

class TreebankAnnotatorRepository
  @load: (dir) ->
    resources = {}
    for file in fs.readdirSync(dir)
      pid = 'Perseus:text:' + file.replace('.json', '')
      resources[pid] = dir + '/' + file

    new TreebankAnnotatorRepository(resources)

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
  TreebankAnnotatorRepository: TreebankAnnotatorRepository
