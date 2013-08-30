path = require('path')
libxml = require('libxmljs')
fs = require('fs')
should = require('should')

Edition = require('../lib/edition.coffee')
annotator = require('../lib/annotator.coffee')

describe 'Edition', ->
  file = fs.readFileSync(path.resolve(__dirname, 'resources/iliad.xml'))
  document = libxml.parseXml(file).get('/TEI.2/text')
  citationMapping = [{label: 'book'}, {label: 'line'}]
  annotator = new annotator.SimpleAnnotator

  it 'selects a passage with a coarse selector', ->
    edition = Edition.make(citationMapping, '2', annotator, document)
    edition.find('l')[0].path().should.eql("/TEI.2/text/body/div[2]/p[1]/l[1]")

  it 'selects a passage with a fine selector', ->
    edition = Edition.make(citationMapping, '2.2', annotator, document)
    edition.path().should.eql("/TEI.2/text/body/div[2]/p[1]/l[2]")
