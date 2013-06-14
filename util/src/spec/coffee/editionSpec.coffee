Edition = require('../../main/coffee/edition.coffee')
annotator = require('../../main/coffee/annotator.coffee')
libxml = require('libxmljs')
fs = require('fs')

describe 'Edition', ->
  file = fs.readFileSync(__dirname + '/../resources/iliad.xml')
  document = libxml.parseXml(file).get('/TEI.2/text')
  citationMapping = [{label: 'book'}, {label: 'line'}]
  annotator = new annotator.SimpleAnnotator

  it 'selects a passage with a coarse selector', ->
    edition = new Edition(citationMapping, '2', annotator, document)
    expect(edition.find('div')[0].text()).toEqual(document.get(".//div[@type='book' and @n='2']").text())

  it 'selects a passage with a fine selector', ->
    edition = new Edition(citationMapping, '2.2', annotator, document)
    expect(edition.find('l')[0].text()).toEqual(document.get(".//div[@type='book' and @n='2']//l[@n = '2']").text())
