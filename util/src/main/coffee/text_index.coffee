libxml = require('libxmljs')
fs = require('fs')

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

  pidSync: (pid, newValue) ->
    return unless fileName = @fileNameFor(pid)

    if newValue
      fs.writeFileSync(filename, newValue.toString())
    else
      file = fs.readFileSync(fileName)
      libxml.parseXml(file)

  pid: () ->
    pid = arguments[0]
    return next("resource not found") unless fileName = @fileNameFor(pid)

    if arguments.length == 2
      next = arguments[1]
      file = fs.readFile(fileName, (err, file) ->
        return next(err) if err
        next(null, libxml.parseXml(file)))
    else
      console.log("writePath")
      newValue = arguments[1]
      next = arguments[2]
      fs.writeFile(fileName, newValue.toString(), (err, file) ->
        next(err))

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

  urnSync: (urn, newValue) ->
    urn = parseUrn(urn)
    return unless resource = @resources.urns[urn.work]

    if newValue
      @perseusIndex.pidSync(resource.pid, newValue.document)
    else
      xml = @perseusIndex.pidSync(resource.pid)
      metadata: resource, document: xml, passageSelector: urn.passage

  urn: () ->
    urn = parseUrn(arguments[0])
    next = arguments[arguments.length - 1]
    return next("resource not found") unless resource = @resources.urns[urn.work]

    if arguments.length == 2
      @perseusIndex.pid(resource.pid, (err, xml) ->
        return next(err) if err
        next(null, metadata: resource, document: xml, passageSelector: urn.passage))
    else
      console.log("write path")
      newValue = arguments[1]
      @perseusIndex.pid(resource.pid, newValue.document, next)

  group: (group) ->
    @resources.groups[group]

  work: (group, work) ->
    @group(group).works[work]

  docname2pid = (docname) ->
    basename = docname.replace('.xml', '')
    "Perseus:text:#{basename}"

  parseResource = (editionOrTranslation) ->
    return unless online = editionOrTranslation.get('./cts:online', xmlns)
    resource =
      label: editionOrTranslation.get('./cts:label', xmlns).text()
      description: editionOrTranslation.get('./cts:description', xmlns).text()
      docname: docname = online.attr('docname').value()
      pid: docname2pid(docname)
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
