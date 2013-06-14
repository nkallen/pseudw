util = require('pseudw-util')
fs = require('fs')
libxml = require('libxmljs')
TreebankAnnotator = util.annotator.TreebankAnnotator
SimpleAnnotator = util.annotator.SimpleAnnotator
Edition = util.Edition

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
      req.urn = req.params.urn || text.metadata.urn
      annotatorIndex.pid(text.metadata.pid, (err, annotator) ->
        console.warn(err) if err

        req.annotator = annotator || new SimpleAnnotator
        next()))

  show: (req, res) ->
    text = req.text
    res.render('text',
      edition: new Edition(text.metadata.citationMapping, text.passageSelector, req.annotator, text.document),
      urn: req.urn)

  update: (req, res) ->
    self = this
    text = req.text

    for key, value of req.body.path
      node = text.document.get(unescape(key))
      replacement = libxml.parseXml(value).root()
      node.addNextSibling(replacement)
      node.remove()

    ctsIndex.urn(text.metadata.urn, text, (err) ->
      return res.send(500) if err

      res.render('text',
        edition: new Edition(text.metadata.citationMapping, text.passageSelector, req.annotator, text.document),
        urn: req.urn))

module.exports =
  configure: configure
