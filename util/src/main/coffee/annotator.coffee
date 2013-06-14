fs = require('fs')
_  = require('underscore')

###
  class Annotator
    annotate: (string) -> [tokens]
    reset: () -> ()
    update: (position, token) -> ()
    toJson: () -> {}
  
  Note: update performs PARTIAL updates.
###

class SimpleAnnotator
  annotate: (string) ->
    for token in string.split(' ')
      form: token
  reset: () -> # stateless, so no-op
  update: () -> # stateless, so no-op
  toJson: () -> {}

class TreebankAnnotator
  constructor: (@treebank) ->
    @reset()
  annotate: (string) ->
    result = []

    while (string = string.trim()).length
      annotation = @treebank[@i]
      annotation.__position__ = @i++
      form = annotation.originalForm || annotation.form
      if (original = string[0...form.length]) != form
        throw "Original '#{original}' not equal to '#{form}': #{JSON.stringify(annotation)}"
      result.push(annotation)
      string = string[form.length..]
    result

  reset: () ->
    @i = 0

  update: (position, token) ->
    _.extend(@treebank[position], token)

  toJson: () ->
    @treebank

  toString: () ->
    JSON.stringify(@treebank)

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
  TreebankAnnotatorIndex: TreebankAnnotatorIndex
