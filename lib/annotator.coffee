fs = require('fs')
path = require('path')
_  = require('underscore')
urn = require('./urn')

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
  constructor: (@language) ->
    @wordBoundary = language?.WordBoundary || /\s/
    @wordBoundary

  one: (string) ->
    return [form: string, ''] if (i = string.search(@wordBoundary)) < 0
    # Precondition: string is trimmed, so as not to return a space.
    # Precondition: boundaries are one character wide, so we don't tokenize e.g., '--' as two tokens.
    return [form: string[0], string[1..]] if i == 0

    token = form: string[0..i-1]
    remainder = string[i..-1].trim()
    [token, remainder]
  toJson: () -> {}

class TreebankAnnotator extends Annotator
  constructor: (@treebank) ->
    @reset()
  one: (string) ->
    throw "EOF" if @eof()

    annotation = @treebank[@i]
    form = annotation.originalForm || annotation.form
    return [null, string] if (original = string[0...form.length]) != form
    @skip()
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
    token = remainder = null
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
  constructor: (@fileReader) ->

  urn: (_urn, callback) ->
    _urn = urn.parse(_urn)
    _path = path.join.apply(null, [_urn.service].concat(_urn.work.split('.')[0..1]).concat(_urn.work)) + '.json'

    @fileReader.readFile(_path, (err, file) ->
      return callback(err) if err

      callback(null, new TreebankAnnotator(JSON.parse(file))))

module.exports =
  SimpleAnnotator: SimpleAnnotator
  TreebankAnnotator: TreebankAnnotator
  SkippingAnnotator: SkippingAnnotator
  FailoverAnnotator: FailoverAnnotator
  TreebankAnnotatorRepository: TreebankAnnotatorRepository
