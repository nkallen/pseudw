greek = require('./greek')

class MorphologicalAnalyzer
  constructor: (json) ->
    @analyses = {}
    for morpheme, analyses of json
      @analyses[morpheme] = []
      for analysis in analyses
        @analyses[morpheme].push(
          lemma: analysis.lemma
          partOfSpeech: greek.PartOfSpeech.get(analysis.partOfSpeech)
          number: greek.Number.get(analysis.number)
          tense: greek.Tense.get(analysis.tense)
          mood: greek.Mood.get(analysis.mood)
          gender: greek.Gender.get(analysis.gender)
          case: greek.Case.get(analysis.case)
          person: greek.Person.get(analysis.person)
          voice: greek.Voice.get(analysis.voice)
        )

  analyze: (form) ->
    @analyses[form]

module.exports = MorphologicalAnalyzer