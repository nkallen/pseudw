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

group = (req, res) ->
  return res.send(404) unless _group = ctsIndex.group(req.params.group)
  
  res.render('group', group: _group)

work = (req, res) ->
  return res.send(404) unless _group = ctsIndex.group(req.params.group)
  return res.send(404) unless _work = ctsIndex.work(req.params.group, req.params.work)

  res.render('work', group: _group, work: _work)

load = (req, res, next) ->
  if req.params.urn
    ctsIndex.urn(req.params.urn, (err, text) ->
      req.text = text
      next())
  else
    ctsIndex.path([req.params.group, req.params.work, req.params.edition], (err, text) ->
      req.text = text
      next())

show = (req, res) ->
  annotator = new SimpleAnnotator
  res.render('text', text: helpers.view(req.text), annotator: annotator, urn: 'XXX FIXME')

update = (req, res) ->
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
  load: load
  group: group
  work: work
