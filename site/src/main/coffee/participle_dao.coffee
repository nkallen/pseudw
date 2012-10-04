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

  findAllByLemma: (lemmas, onSuccess, onFailure) ->
    Preconditions.assertDefined(lemmas)
    Preconditions.assertDefined(onSuccess)

    console.log("#{@uri}/#{lemmas.join(";")}/participles")
    @getJson("#{@uri}/#{lemmas.join(";")}/participles", {}, (jsons) ->
      participles = for json in jsons
        new Participle(json.morpheme, new Verb(json.verb.lemma, json.verb.principleParts, json.verb.definition),
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

  findAllByLemma: (lemmas, onSuccess, onFailure) ->
    Preconditions.assertDefined(lemmas)
    Preconditions.assertDefined(onSuccess)

    @connection.query("select * from morphemes where lemma in (?) and part_of_speech = 'participle'", [lemmas], (err, rows, fields) ->
      return onFailure(err) if err?

      participles = for row in rows
        if row.voice == "middle-passive"
          voice = Voice["middlePassive"]
        else
          voice = Voice[row.voice]

        new Participle(row.form, new Verb(row.lemma, [], ""),
            new ParticipleDesc(Tense[row.tense], voice, Case[row.case], Gender[row.gender], Number[row.number]))

      onSuccess(participles)
    )

module.exports = {
  http: ParticipleHttpDao,
  sql: ParticipleSqlDao
}