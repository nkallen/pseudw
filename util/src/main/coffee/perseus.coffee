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
    return unless current = @resources[pid]

    while !current.file && current.ref
      current = current.ref

    file = fs.readFileSync(current.file)
    libxml.parseXml(file)

class CtsIndex
  @load: (xml, perseusIndex) ->
    xmlns =
      cts: 'http://chs.harvard.edu/xmlns/cts3/ti'
    resources = {}
    for edition in xml.find('//cts:edition', xmlns)
      resources[edition.attr('urn').value()] = resource = {}
      continue unless online = edition.get('./cts:online', xmlns)
      resource.docname = online.attr('docname').value()
      citation = online.get('./cts:citationMapping', xmlns)
      resource.citations = (citations = [])
      while citation = citation.get('./cts:citation', xmlns)
        citations.push(
          label: citation.attr('label').value())
    new CtsIndex(resources, perseusIndex)


  constructor: (@resources, @perseusIndex) ->
  resourceSync: (urn) ->
    [protocol, namespace, cts, work, passage] = urn.split(/:/)
    workUrn = "#{protocol}:#{namespace}:#{cts}:#{work}"
    return unless resource = @resources[workUrn]

    xml = @perseusIndex.resourceSync(docname2pid(resource.docname))
    return xml if !passage
    return unless text = xml.get('/TEI.2/text')

    passageParts = passage.split('.')
    passage = text
    for citation, i in resource.citationMapping
      break if i > passageParts.length - 1

      [tag, attr] = Citation2tag[label = citation.label]
      xpath = ".//#{tag}"
      xpath += "[" + (if attr then "@#{attr}='#{label}' and " else '') + "@n='#{passageParts[i]}']" if attr
      node = text.get(xpath)
      return unless node
    node

  docname2pid = (online) ->
    basename = online.replace('.xml', '')
    "Perseus:text:#{basename}"


module.exports =
  PerseusIndex: PerseusIndex
  CtsIndex: CtsIndex