fs = require('fs')
path = require('path')
libxml = require('libxmljs')

textIndex = require('../lib/text_index.coffee')

describe 'Index', ->
  pid = 'Perseus:text:1999.01.0133'
  file = path.resolve(__dirname, 'resources/iliad.xml')
  perseusResources = {}
  perseusResources[pid] =
    file: file
  
  urn = 'urn:cts:greekLit:tlg0012.tlg001.perseus-grc1'
  ctsResources =
    urns: {}
  ctsResources.urns[urn] =
    docname: '1999.01.0133.xml'
    pid: pid
    citationMapping: [{label: 'book'}, {label: 'line'}]

  document = libxml.parseXml(fs.readFileSync(file))

  describe 'PerseusIndex', ->
    perseusIndex = null

    describe 'load', ->
      it 'parses a perseus xml file', ->
        perseusIndex = textIndex.PerseusIndex.load(libxml.parseXml(fs.readFileSync(path.resolve(__dirname, 'resources/index.perseus.xml'))), path.resolve(__dirname, 'resources'))
        resource = perseusIndex.pidSync(pid)
        resource.get('//title').text().should.eql(document.get('//title').text())

    describe 'resource', ->
      beforeEach ->
        perseusIndex = new textIndex.PerseusIndex(perseusResources)

      it 'loads a document by pid', ->
        resource = perseusIndex.pidSync(pid)
        resource.get('//title').text().should.eql(document.get('//title').text())

  describe 'CtsIndex', ->
    ctsIndex = perseusIndex = null

    beforeEach ->
      perseusIndex = new textIndex.PerseusIndex(perseusResources)

    describe 'load', ->
      it 'parses a text inventory', ->
        ctsIndex = textIndex.CtsIndex.load(libxml.parseXml(fs.readFileSync(path.resolve(__dirname, 'resources/index.cts.xml'))), perseusIndex)
        text = ctsIndex.urnSync(urn)
        text.document.get('//title').text().should.eql(document.get('//title').text())

    describe 'resource', ->
      beforeEach ->
        ctsIndex = new textIndex.CtsIndex(ctsResources, perseusIndex)

      it 'loads a work urn', ->
        text = ctsIndex.urnSync(urn)
        text.document.get('//title').text().should.eql(document.get('//title').text())
