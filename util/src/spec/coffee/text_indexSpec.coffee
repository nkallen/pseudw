textIndex = require('../../main/coffee/text_index.coffee')
libxml = require('libxmljs')
fs = require('fs')

describe 'Index', ->
  pid = 'Perseus:text:1999.01.0133'
  file = __dirname + '/../resources/iliad.xml'
  perseusResources = {}
  perseusResources[pid] =
    file: file
  
  urn = 'urn:cts:greekLit:tlg0012.tlg001.perseus-grc1'
  ctsResources =
    urns: {}
  ctsResources.urns[urn] =
    docname: '1999.01.0133.xml'
    citationMapping: [{label: 'book'}, {label: 'line'}]

  document = libxml.parseXml(fs.readFileSync(file))

  describe 'PerseusIndex', ->
    perseusIndex = null

    describe 'load', ->
      it 'parses a perseus xml file', ->
        perseusIndex = perseus.PerseusIndex.load(libxml.parseXml(fs.readFileSync(__dirname + '/../resources/index.perseus.xml')), __dirname + '/../resources')
        resource = perseusIndex.resourceSync(pid)
        expect(resource.get('//title').text()).toEqual(document.get('//title').text())

    describe 'resource', ->
      beforeEach ->
        perseusIndex = new perseus.PerseusIndex(perseusResources)

      it 'loads a document by pid', ->
        resource = perseusIndex.resourceSync(pid)
        expect(resource.get('//title').text()).toEqual(document.get('//title').text())

  describe 'CtsIndex', ->
    ctsIndex = perseusIndex = null

    beforeEach ->
      perseusIndex = new perseus.PerseusIndex(perseusResources)

    describe 'load', ->
      it 'parses a text inventory', ->
        ctsIndex = perseus.CtsIndex.load(libxml.parseXml(fs.readFileSync(__dirname + '/../resources/index.cts.xml')), perseusIndex)
        resource = ctsIndex.urnSync(urn)
        expect(resource.get('//title').text()).toEqual(document.get('//title').text())

    describe 'resource', ->
      beforeEach ->
        ctsIndex = new perseus.CtsIndex(ctsResources, perseusIndex)

      it 'loads a work urn', ->
        resource = ctsIndex.urnSync(urn)
        expect(resource.get('//title').text()).toEqual(document.get('//title').text())

      it 'loads a coarse passage urn', ->
        resource = ctsIndex.urnSync(urn + ':1')
        expect(resource.text()).toEqual(document.get(".//div[@type='book' and @n='1']").text())

      it 'loads a fine passage urn', ->
        resource = ctsIndex.urnSync(urn + ':1.2')
        expect(resource.text()).toEqual(document.get(".//div[@type='book' and @n='1']//l[@n = '2']").text())
