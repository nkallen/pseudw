path = require('path')
libxml = require('libxmljs')
fs = require('fs')
should = require('should')

AnnotatedEdition = require('../lib/annotated_edition.coffee')
annotator = require('../lib/annotator.coffee')

describe 'AnnotatedEdition', ->
  file = fs.readFileSync(path.resolve(__dirname, '../vendor/canonical/CTS_XML_TEI/perseus/greekLit/tlg0012/tlg001/tlg0012.tlg001.perseus-grc1.xml'))
  document = libxml.parseXml(file).get('/TEI.2/text')
  citationMapping = [{label: 'book'}, {label: 'line'}]
  annotator = new annotator.SimpleAnnotator

  describe 'select', ->
    it 'works', ->
      annotatedEdition = new AnnotatedEdition(citationMapping, annotator, document)
      annotatedEdition.select('2').find('l')[0].path().should.eql("/TEI.2/text/body/div[2]/p[1]/l[1]")

  describe 'selectFirst', ->
    it 'works', ->
      annotatedEdition = new AnnotatedEdition(citationMapping, annotator, document)
      annotatedEdition.selectFirst().find('l')[0].path().should.eql("/TEI.2/text/body/div[1]/p[1]/l[1]")
