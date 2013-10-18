greek = require('../lib/greek.coffee')

describe 'Greek', ->
  describe 'betacode2unicode', ->
    it 'catches trailing characters', ->
      greek.betacode2unicode("le/gw").should.eql("λέγω")
    it 'handles sigmas properly', ->
      greek.betacode2unicode("dasso/s. dasso\\s dassos' dassos").should.eql("δασσός. δασσὸς δασσοσʼ δασσος")

  describe 'Postag', ->
    it 'works', ->
      hash =
        partOfSpeech: greek.PartOfSpeech.participle
        case: greek.Case.genitive
        gender: greek.Gender.masculine
        number: greek.Number.singular
        tense: greek.Tense.aorist
        voice: greek.Voice.active
      greek.postag.toHash(greek.postag.fromHash(hash)).should.eql(hash)