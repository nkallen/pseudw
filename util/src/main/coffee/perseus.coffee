libxml = require('libxmljs')
fs = require('fs')

Citation2tag =
  article: ['div', 'type']
  section: ['milestone', 'unit']
  chapter: ['milestone', 'unit']
  page: ['milestone', 'unit']
  book: ['div', 'type']
  text: ['text']
  line: ['l']
  scene: ['div', 'type']
  act: ['div', 'type']
  entry: ['div', 'type']
  card: ['milestone', 'unit']
  speech: ['div', 'type']
  root: ['div', 'type']
  poem: ['div', 'type']

class PerseusIndex
  @load: (xml, root) ->
    resources = {}
    xmlns =
      tufts: "http://www.tufts.edu/"
      rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xsi: "http://www.w3.org/2001/XMLSchema-instance"
      persq: "http://www.perseus.org/meta/persq.rdfs#"
      perseus: "http://www.perseus.org/meta/perseus.rdfs#"
      dctype: "http://purl.org/dc/dcmitype/"
      dcterms: "http://purl.org/dc/terms/"
      dc: "http://purl.org/dc/elements/1.1/"

    for description in xml.find('/rdf:RDF/rdf:Description', xmlns)
      resources[description.attr('about').value()] =
        pid: description.get('./dcterms:identifier', xmlns)?.text()
        isVersionOf: description.get('./dcterms:isVersionOf', xmlns)?.attr('resource').value() 
        file: root + '/' + description.get('./perseus:text', xmlns)?.text()
    for resource in resources
      resource.ref = resources[resource.isVersionOf] if resource.isVersionOf

    new PerseusIndex(resources)
  constructor: (@resources) ->

  resourceSync: (pid) ->
    return unless fileName = @fileNameFor(pid)
    file = fs.readFileSync(fileName)
    libxml.parseXml(file)

  resource: (pid, next) ->
    return next("resource not found") unless fileName = @fileNameFor(pid)

    file = fs.readFile(fileName, (err, file) ->
      return next(err) if err
      next(null, libxml.parseXml(file)))

  fileNameFor: (pid) ->
    return unless current = @resources[pid]

    while !current.file && current.ref
      current = current.ref  

    current.file

class CtsIndex
  xmlns = cts: 'http://chs.harvard.edu/xmlns/cts3/ti'

  @load: (xml, perseusIndex) ->
    resources = urns: {}, groups: {}
    for groupNode in xml.find('//cts:textgroup', xmlns)
      group =
        name: groupNode.get('./cts:groupname', xmlns).text()
        works: {}
      resources.groups[group.name] = group
      for workNode in groupNode.find('./cts:work', xmlns)
        work =
          title: workNode.get('./cts:title', xmlns).text()
          editions: {}
        group.works[work.title] = work
        for editionNode in workNode.find('./cts:edition', xmlns)
          continue unless resource = parseResource(editionNode)
          resources.urns[resource.urn] = work.editions[resource.label] = resource

        for translation in workNode.find('./cts:translation', xmlns)
          continue unless resource = parseResource(translation)
          resources.urns[resource.urn] = work.editions[resource.label] = resource

    new CtsIndex(resources, perseusIndex)

  constructor: (@resources, @perseusIndex) ->

  urnSync: (urn) ->
    urn = parseUrn(urn)
    return unless resource = @resources.urns[urn.work]

    xml = @perseusIndex.resourceSync(docname2pid(resource.docname))
    selectPassage(resource.citationMapping, urn.passage, xml)

  urn: (urn, next) ->
    urn = parseUrn(urn)
    return next("resource not found") unless resource = @resources.urns[urn.work]

    @perseusIndex.resource(docname2pid(resource.docname), (err, xml) ->
      return next(err) if err
      next(null, selectPassage(resource.citationMapping, urn.passage, xml)))

  group: (group) ->
    @resources.groups[group]

  work: (group, work) ->
    @group(group).works[work]

  selectPassage = (citationMapping, passage, xml) ->
    return xml if !passage
    return unless text = xml.get('/TEI.2/text')
    passageParts = passage.split('.')
    passage = text
    for citation, i in citationMapping
      break if i > passageParts.length - 1

      [tag, attr] = Citation2tag[label = citation.label]
      xpath = ".//#{tag}"
      xpath += "[" + (if attr then "@#{attr}='#{label}' and " else '') + "@n='#{passageParts[i]}']"
      node = text.get(xpath)
      return unless node
    node

  docname2pid = (docname) ->
    basename = docname.replace('.xml', '')
    "Perseus:text:#{basename}"

  parseResource = (editionOrTranslation) ->
    return unless online = editionOrTranslation.get('./cts:online', xmlns)
    resource =
      label: editionOrTranslation.get('./cts:label', xmlns).text()
      description: editionOrTranslation.get('./cts:description', xmlns).text()
      docname: online.attr('docname').value()
      citationMapping: citationMapping = []
      urn: editionOrTranslation.attr('urn').value()
    citation = online.get('./cts:citationMapping', xmlns)
    while citation = citation.get('./cts:citation', xmlns)
      citationMapping.push(
        label: citation.attr('label').value())
    resource

  parseUrn = (urn) ->
    [protocol, namespace, service, work, passage] = urn.split(/:/)
    service: service
    work: "#{protocol}:#{namespace}:#{service}:#{work}"
    passage: passage

module.exports =
  PerseusIndex: PerseusIndex
  CtsIndex: CtsIndex
