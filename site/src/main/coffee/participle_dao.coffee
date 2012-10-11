util = require('pseudw-util')

greek = util.greek
Preconditions = util.preconditions
Participle = greek.Participle
Verb = greek.Verb
ParticipleDesc = greek.ParticipleDesc
Case = greek.Case
Gender = greek.Gender
Number = greek.Number
Tense = greek.Tense
Voice = greek.Voice
Inflections = greek.Inflections

class ParticipleHttpDao
  constructor: (@uri, @getJson) ->
    Preconditions.assertDefined(@uri)
    Preconditions.assertDefined(@getJson)

  findAllByLemma: (lemmas, options, cb) ->
    Preconditions.assertKeys(options, 'tenses', 'voices', 'numbers', 'genders', 'cases')
    Preconditions.assertDefined(lemmas)
    Preconditions.assertDefined(cb)

    @getJson("#{@uri}/#{lemmas.join(";")}/participles", options, (jsons) ->
      participles = for json in jsons
        new Participle(json.morpheme, new Verb(json.verb.lemma, json.verb.principleParts, json.verb.translation),
          new ParticipleDesc(
              Tense[json.participleDesc.tense],
              Voice[json.participleDesc.voice],
              Case[json.participleDesc.case],
              Gender[json.participleDesc.gender],
              Number[json.participleDesc.number]))
      cb(null, participles)
    )

class ParticipleSqlDao
  constructor: (@client) ->

  findAllByLemma: (lemmas, options, cb) ->
    Preconditions.assertKeys(options, 'tenses', 'voices', 'numbers', 'genders', 'cases')
    Preconditions.assertDefined(lemmas)
    Preconditions.assertDefined(cb)

    n = 1
    query = "SELECT * FROM morphemes INNER JOIN lexemes ON morphemes.lemma = lexemes.lemma WHERE morphemes.lemma IN (#{("$#{n++}" for lemma in lemmas).join(", ")}) AND part_of_speech = 'participle'"
    bindParameters = lemmas
    for inflection in Inflections
      if attribute = options[inflection.toSymbol() + 's']
        query += " AND \"#{inflection.toSymbol()}\" IN ($#{n++})"
        bindParameters.push(attribute for attribute in attributes)

    @client.query(query, bindParameters, (err, result) ->
      return cb(err) if err?

      participles = for row in result.rows
        new Participle(row.form, new Verb(row.lemma, [], row.translation),
            new ParticipleDesc(Tense[row.tense], Voice[row.voice], Case[row.case], Gender[row.gender], Number[row.number]))

      cb(null, participles)
    )

module.exports = {
  http: ParticipleHttpDao,
  sql: ParticipleSqlDao
}