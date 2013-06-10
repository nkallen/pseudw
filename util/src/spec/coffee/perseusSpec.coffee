perseus = require('../../main/coffee/perseus.coffee')
libxml = require('libxmljs')
fs = require('fs')

describe 'Index', ->
  pid = 'Perseus:text:1999.01.0133'
  file = __dirname + '/../resources/iliad.xml'
  perseusResources = {}
  perseusResources[pid] =
    file: file
  perseusIndex = new perseus.PerseusIndex(perseusResources)
  
  urn = 'urn:cts:greekLit:tlg0012.tlg001.perseus-grc1'
  ctsResources = {}
  ctsResources[urn] =
    docname: '1999.01.0133.xml'
    citationMapping: [{label: 'book'}, {label: 'line'}]
  ctsIndex = new perseus.CtsIndex(ctsResources, perseusIndex)

  document = libxml.parseXml(fs.readFileSync(file))

  describe 'PerseusIndex', ->
    it 'loads a document by pid', ->
      resource = perseusIndex.resourceSync(pid)
      expect(resource.get('//title').text()).toEqual(document.get('//title').text())

  describe 'CtsIndex', ->
    it 'loads a work urn', ->
      resource = ctsIndex.resourceSync(urn)
      expect(resource.get('//title').text()).toEqual(document.get('//title').text())

    it 'loads a coarse passage urn', ->
      resource = ctsIndex.resourceSync(urn + ':1')
      expect(resource.text()).toEqual(document.get(".//div[@type='book' and @n='1']").text())

    it 'loads a fine passage urn', ->
      resource = ctsIndex.resourceSync(urn + ':1.1')
      expect(resource.text()).toEqual(document.get(".//div[@type='book' and @n='1']//l[@n = '1']").text())
