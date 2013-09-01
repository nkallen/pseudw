fs = require('fs')
path = require('path')
libxml = require('libxmljs')
should = require('should')

textIndex = require('../lib/text_index.coffee')

describe 'Text Indexes & Repositories', ->
  urn = 'urn:cts:greekLit:tlg0012.tlg001.perseus-grc1'

  describe 'PerseusRepository', ->
    fileReader =
      readFile: (file, callback) -> fs.readFile(path.join(__dirname, '../vendor/canonical/CTS_XML_TEI/perseus', file), callback)
    perseusRepository = new textIndex.PerseusRepository(fileReader)  

    describe 'urn', ->
      it 'loads a document by urn', (done) ->
        perseusRepository.urn(urn, (error, resource) ->
          libxml.parseXml(resource).get('//title').text().should.eql('Iliad (Greek). Machine readable text')
          done()
        )

  describe 'CtsIndex', ->
    xml = libxml.parseXml(fs.readFileSync(path.resolve(__dirname, '../vendor/catalog_data/perseus/perseuscts.xml')))
    ctsIndex = textIndex.CtsIndex.load(xml)

    describe 'urn', ->
      it 'works', ->
        text = ctsIndex.urn(urn)

    describe 'group', ->
      it 'works', ->
        group = ctsIndex.group('Homer')
        group.name.should.eql('Homer')
        group.works.Iliad.title.should.eql('Iliad')

    describe 'work', ->
      it 'works', ->
        work = ctsIndex.work('Homer', 'Iliad')
        work.editions.Iliad.description.should.eql('Perseus:bib:oclc,29448041, Homer. Homeri Opera in five volumes. Oxford, Oxford University Press. 1920.')

    describe 'edition', ->
      it 'works', ->
        edition = ctsIndex.edition('Homer', 'Iliad', 'Iliad')
        edition.description.should.eql('Perseus:bib:oclc,29448041, Homer. Homeri Opera in five volumes. Oxford, Oxford University Press. 1920.')
