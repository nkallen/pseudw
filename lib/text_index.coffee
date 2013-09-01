fs = require('fs')
path = require('path')
urn = require('./urn')

class PerseusRepository
  constructor: (@fileReader) ->

  urn: (_urn, callback) ->
    _urn = urn.parse(_urn)
    _path = path.join.apply(null, [_urn.service].concat(_urn.work.split('.')[0..1]).concat(_urn.work)) + '.xml'
    @fileReader.readFile(_path, callback)

class CtsIndex
  xmlns = cts: 'http://chs.harvard.edu/xmlns/cts/ti'

  @load: (xml) ->
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
          translations: {}
        group.works[work.title] = work

        for edition in workNode.find('./cts:edition', xmlns)
          continue unless resource = parseResource(edition)
          resources.urns[resource.urn] = work.editions[resource.label] = resource

        for translation in workNode.find('./cts:translation', xmlns)
          continue unless resource = parseResource(translation)
          resources.urns[resource.urn] = work.translations[resource.label] = resource

    new CtsIndex(resources)

  constructor: (@resources) ->
    @groups = (group for blah, group of @resources.groups)

  urn: (_urn) ->
    @resources.urns[_urn]

  group: (group, callback) ->
    @resources.groups[group]

  work: (group, work) ->
    @group(group).works[work]

  edition: (group, work, edition) ->
    @group(group).works[work].editions[edition]

  parseResource = (editionOrTranslation) ->
    return unless online = editionOrTranslation.get('./cts:online', xmlns)
    resource =
      label: editionOrTranslation.get('./cts:label', xmlns).text()
      description: editionOrTranslation.get('./cts:description', xmlns).text()
      docname: docname = online.attr('docname').value()
      citationMapping: citationMapping = []
      urn: editionOrTranslation.attr('urn').value()
    citation = online.get('./cts:citationMapping', xmlns)
    while citation = citation.get('./cts:citation', xmlns)
      citationMapping.push(
        label: citation.attr('label').value())
    resource

module.exports =
  PerseusRepository: PerseusRepository
  CtsIndex: CtsIndex
