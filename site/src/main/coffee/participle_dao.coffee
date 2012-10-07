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

class ParticipleHttpDao
  constructor: (@uri, @getJson) ->
    Preconditions.assertDefined(@uri)
    Preconditions.assertDefined(@getJson)

  findAllByLemma: (lemmas, options, onSuccess, onFailure) ->
    Preconditions.assertDefined(lemmas)
    Preconditions.assertDefined(onSuccess)

    queryStringOptions = {}
    for inflection, attributes of options
      console.log(inflection, attributes)
      queryStringOptions[inflection.toString().toLowerCase()] =
        (attribute.toString() for attribute in attributes)

    @getJson("#{@uri}/#{lemmas.join(";")}/participles", queryStringOptions, (jsons) ->
      participles = for json in jsons
        new Participle(json.morpheme, new Verb(json.verb.lemma, json.verb.principleParts, json.verb.translation),
          new ParticipleDesc(
              Tense[json.participleDesc.tense],
              Voice[json.participleDesc.voice],
              Case[json.participleDesc.case],
              Gender[json.participleDesc.gender],
              Number[json.participleDesc.number]))
      onSuccess(participles)
    )

class ParticipleSqlDao
  constructor: (@connection) ->

  findAllByLemma: (lemmas, options, onSuccess, onFailure) ->
    Preconditions.assertDefined(lemmas)
    Preconditions.assertDefined(onSuccess)

    query = "SELECT * FROM morphemes LEFT OUTER JOIN lexemes ON morphemes.lemma = lexemes.lemma WHERE morphemes.lemma IN (?) AND part_of_speech = 'participle'"
    bindParameters = [lemmas]
    for inflection, attributes of options
      query += " AND `#{inflection.toString().toLowerCase()}` IN (?)"
      bindParameters.push(attribute.toString() for attribute in attributes)

    @connection.query(query, bindParameters, (err, rows, fields) ->
      return onFailure(err) if err?

      participles = for row in rows
        if row.voice == "middle-passive"
          voice = Voice["middlePassive"]
        else
          voice = Voice[row.voice]

        new Participle(row.form, new Verb(row.lemma, [], row.translation),
            new ParticipleDesc(Tense[row.tense], voice, Case[row.case], Gender[row.gender], Number[row.number]))

      onSuccess(participles)
    )

module.exports = {
  http: ParticipleHttpDao,
  sql: ParticipleSqlDao
}