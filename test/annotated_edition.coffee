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

  it 'selects a passage with a coarse selector', ->
    annotatedEdition = AnnotatedEdition.make(citationMapping, '2', annotator, document)
    annotatedEdition.find('l')[0].path().should.eql("/TEI.2/text/body/div[2]/p[1]/l[1]")

  xit 'selects a passage with a fine selector', -> # doesn't work because <l> tags don't have n='' at the moment.
    annotatedEdition = AnnotatedEdition.make(citationMapping, '2.2', annotator, document)
    annotatedEdition.path().should.eql("/TEI.2/text/body/div[2]/p[1]/l[2]")
