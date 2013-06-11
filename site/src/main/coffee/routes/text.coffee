util = require('pseudw-util')
perseus = util.perseus
fs = require('fs')
libxml = require('libxmljs')
util = require('pseudw-util')
TreebankAnnotator = util.annotator.TreebankAnnotator
SimpleAnnotator = util.annotator.SimpleAnnotator
helpers = require('../helpers')

perseusIndex = perseus.PerseusIndex.load(libxml.parseXml(fs.readFileSync(__dirname + '/../../../../../perseus-greco-roman/index.perseus.xml')), __dirname + '/../../../../../perseus-greco-roman')
ctsIndex = perseus.CtsIndex.load(libxml.parseXml(fs.readFileSync(__dirname + '/../../../../../perseus-greco-roman/index.cts.xml')), perseusIndex)

show = (req, res, next) ->
  ctsIndex.urn(req.params.urn, (err, text) ->
    return res.send(404) if err

    annotator = new SimpleAnnotator
    res.render('text', text: helpers.view(text), urn: req.params.urn, annotator: annotator))

update = (req, res, next) ->
  unless filename = index.file(req.params.pid)
    res.send(404)
    return

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
  show: show
  update: update