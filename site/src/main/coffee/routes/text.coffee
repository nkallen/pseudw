util = require('pseudw-util')
fs = require('fs')
libxml = require('libxmljs')
TreebankAnnotator = util.annotator.TreebankAnnotator
SimpleAnnotator = util.annotator.SimpleAnnotator
helpers = require('../helpers')

configure = (configuration) ->
  perseusIndex  = configuration.perseusIndex
  ctsIndex      = configuration.ctsIndex
  annotatorIndex = configuration.annotatorIndex

  group: (req, res) ->
    return res.send(404) unless _group = ctsIndex.group(req.params.group)
    
    res.render('group', group: _group)

  work: (req, res) ->
    return res.send(404) unless _group = ctsIndex.group(req.params.group)
    return res.send(404) unless _work = ctsIndex.work(req.params.group, req.params.work)

    res.render('work', group: _group, work: _work)

  load: (req, res, next) ->
    loadText =
      if req.params.urn
        (cb) -> ctsIndex.urn(req.params.urn, cb)
      else
        (cb) -> ctsIndex.path([req.params.group, req.params.work, req.params.edition], cb)

    loadText((err, text) ->
      return res.send(404) if err
      req.text = text
      annotatorIndex.pid(text.metadata.pid, (err, annotator) ->
        console.warn(err) if err

        req.annotator = annotator || new SimpleAnnotator
        next()))

  show: (req, res) ->
    res.render('text', text: helpers.view(req.text.passage), annotator: req.annotator, urn: req.text.metadata.urn)

  update: (req, res) ->
    unless filename = index.file(req.params.pid)
      res.send(404)
      return

    # XXX FIXME refactor to index.update (implies index should be renamed repository)
    fs.readFile(path = __dirname + "/../../../../perseus-greco-roman/#{filename}", 'utf8', (err, xml) ->
      doc = libxml.parseXml(xml)
      for key, value of req.body.path
        node = doc.get(unescape(key))
        replacement = libxml.parseXml(value).root()
        node.addNextSibling(replacement)
        node.remove()

      fs.writeFile(path, doc.toString(), (err) ->
        res.redirect('/pid/' + req.params.pid)))

module.exports =
  configure: configure
