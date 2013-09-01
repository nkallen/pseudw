module.exports =
  parse: (urn) ->
    [protocol, namespace, service, work, passage] = urn.split(/:/)
    protocol: protocol
    namespace: namespace
    service: service
    work: work
    passage: passage
    urn: urn