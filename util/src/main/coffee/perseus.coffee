class Index
  @load: (xml) ->
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
        urn: description.get('./dcterms:identifier', xmlns)?.text()
        isVersionOf: description.get('./dcterms:isVersionOf', xmlns)?.attr('resource').value() 
        file: description.get('./perseus:text', xmlns)?.text()
    for resource in resources
      resource.ref = resources[resource.isVersionOf] if resource.isVersionOf

    new Index(resources)
  constructor: (@resources) ->
  file: (pid) ->
    return unless current = @resources[pid]

    while !current.file && current.ref
      current = current.ref
    current.file?.replace("Classics/", '')
  annotations: (pid) ->
    parts = pid.split(':')
    parts[parts.length-1] + '.json'

module.exports =
  index: Index