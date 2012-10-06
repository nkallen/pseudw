#!/usr/bin/env coffee

fs = require('fs')
greek = require('pseudw-util').greek
libxml = require('libxmljs')
mysql = require('mysql')
stream = require('stream')

help = "
Import the Perseus Morpheme data into a Database

Provide path to morph file on command line, e.g.,

  ./import.coffee sgml/xml/data/greek.morph.xml
"

fileSource = fs.createReadStream(
  process.argv[2],
  {encoding: 'utf8'})

class AnalysisStream extends stream.Stream
  isPaused = false

  constructor: (@parser) ->
    @writable = @readable = true
  write: (chunk, encoding) ->
    @parser.write(chunk, (analyses) =>
      emissions = (@emit('data', analysis) for analysis in analyses)
      pause() if false in emissions
    )
    !isPaused
  pause: ->
    isPaused = true
  resume: ->
    isPaused = false
    @emit 'drain'
  end: ->
    @emit 'end'

class AnalysisParser
  CAPITAL = /^\*/
  CONTRACTION = /'$/
  WEIRD = /[_\-\^]/

  class State
    @skip:               new State
    @handleForm:         new State
    @awaitLemma:         new State
    @handleLemma:        new State
    @awaitPartOfSpeech:  new State
    @handlePartOfSpeech: new State
    @handleMorpheme:     new State
    @handleNumber:       new State
    @handleTense:        new State
    @handleVoice:        new State
    @handleGender:       new State
    @handleCase:         new State
    @handlePerson:       new State
    @handleDialect:      new State

  state = State.skip
  analyses = []
  analysis = null
  skip = ->
    analysis = null
    state = State.skip
  handleAnalysis = {
    startElementNS: (elem, attrs, prefix, uri, namespaces) ->
      if elem == "form"
        analyses.push(analysis) if analysis?
        analysis = {}
        state = State.handleForm

      switch state
        when State.awaitPartOfSpeech
          if elem == "pos"
            state = State.handlePartOfSpeech
        when State.awaitLemma
          if elem == "lemma"
            state = State.handleLemma
        when State.handleMorpheme
          switch elem
            when "number"
              state = State.handleNumber
            when "tense"
              state = State.handleTense
            when "voice"
              state = State.handleVoice
            when "gender"
              state = State.handleGender
            when "case"
              state = State.handleCase
            when "person"
              state = State.handlePerson
            when "mood"
              state = State.handleMood
            when "dialect"
              state = State.handleDialect
    characters: (chars) ->
      switch state
        when State.handleForm
          if CAPITAL.test(chars) || CONTRACTION.test(chars) || WEIRD.test(chars)
            skip()
          else
            analysis.form = chars
            state = State.awaitLemma
        when State.handleLemma
          analysis.lemma = chars
          state = State.awaitPartOfSpeech
        when State.handlePartOfSpeech
          analysis.partOfSpeech = chars
          state = State.handleMorpheme
        when State.handleNumber
          analysis.number = chars
        when State.handleTense
          analysis.tense = chars
        when State.handleVoice
          analysis.voice = chars
        when State.handleGender
          analysis.gender = chars
        when State.handleCase
          analysis.case = chars
        when State.handleMood
          analysis.mood = chars
        when State.handlePerson
          analysis.person = chars
        when State.handleDialect
          if chars.indexOf("attic") != -1
           skip()
    endElementNS: (elem, prefix, uri) ->
      switch state
        when State.handleNumber, State.handleTense, State.handleVoice, State.handleGender, State.handleCase, State.handleMood, State.handlePerson, State.handleDialect
          switch elem
            when "number", "tense", "voice", "gender", "case", "mood", "person", "dialect"
              state = State.handleMorpheme
  }
  parser = new libxml.SaxPushParser(handleAnalysis)

  write: (chunk, oncomplete) ->
    parser.push(chunk)
    oncomplete(analyses)
    analyses = []


class MysqlStream extends stream.Stream
  connection = mysql.createConnection({
    host     : 'localhost',
    user     : process.env.DB_USER,
    password : process.env.DB_PASS,
    database : 'pseudw',
  })
  connection.connect((err) ->
    throw err if err?
  )
  queue = []

  totalInserts = 0
  flush = (onsuccess) ->
    values = sanitize(queue)
    queue = []
    connection.query(
      "INSERT INTO morphemes (`part_of_speech`, `lemma`, `form`, `number`, `tense`, `mood`, `gender`, `case`, `person`, `voice`) VALUES ?",
      [values],
    (err, rows, fields) =>
      throw err if err?
      totalInserts += values.length
      console.log("Inserted #{totalInserts} items so far")
      onsuccess()
    )

  constructor: ->
    @writable = true
  write: (chunk, encoding) ->
    queue.push(chunk)
    if queue.length >= 1000
      flush(=>
        @emit 'drain'
      )
      false
    else
      true
  end: ->
    flush(=>
      connection.end((err) ->
        throw err if err?
      )
      @emit 'end'
    )

  sanitize = do ->
    sanitizePartOfSpeech = (partOfSpeech) ->
      switch partOfSpeech
        when "part" then "participle"
        when "verb" then "verb"
        when "noun" then "noun"
        when "exclam" then "exclamation"
        when "prep" then "preposition"
        when "adj" then "adjective"
        when "adv" then "adverb"
        when "pron" then "pronoun"
        when "partic" then "particle"
        when "conj" then "conjunction"
        when "adverbial" then "adverbial"
        when "article" then "article"
        when "irreg" then "irregular"
        when "numeral" then "numeral"
        else
          throw new TypeError("Invalid part-of-speech '#{partOfSpeech}'")

    sanitizeNumber = (number) ->
      switch number
        when "sg" then "singular"
        when "pl" then "plural"
        when "dual" then "dual"
        when number?
          throw new TypeError("Invalid number '#{number}'")

    sanitizeTense = (tense) ->
      switch tense
        when "pres" then "present"
        when "aor" then "aorist"
        when "fut" then "future"
        when "perf" then "perfect"
        when "plup" then "pluperfect"
        when "futperf" then "futurePerfect"
        when tense?
          throw new TypeError("Invalid tense '#{tense}'")

    sanitizeMood = (mood) ->
      switch mood
        when "ind" then "indicative"
        when "imperat" then "imperative"
        when "subj" then "subjunctive"
        when "opt" then "optative"
        when "inf" then "infinitive"
        when mood?
          throw new TypeError("Invalid mood '#{mood}'")

    sanitizeCase = (kase) ->
      switch kase
        when "nom" then "nominative"
        when "voc" then "vocative"
        when "gen" then "genitive"
        when "dat" then "dative"
        when "acc" then "accusative"
        when kase?
          throw new TypeError("Invalid case '#{kase}'")

    sanitizeGender = (gender) ->
      switch gender
        when "masc" then "masculine"
        when "fem" then "feminine"
        when "neut" then "neuter"
        when gender?
          throw new TypeError("Invalid gender '#{gender}'")

    sanitizePerson = (person) ->
      switch person
        when "1st" then "1st"
        when "2nd" then "2nd"
        when "3rd" then "3rd"
        when person?
          throw new TypeError("Invalid Person '#{person}'")

    sanitizeVoice = (voice) ->
      switch voice
        when "act" then "active"
        when "mid" then "middle"
        when "mp" then "middlePassive"
        when "pass" then "passive"
        when voice?
          throw new TypeError("Invalid Voice '#{voice}'")

    (queue) ->
      [
        sanitizePartOfSpeech(item.partOfSpeech),
        greek.betacode2unicode(item.lemma),
        greek.betacode2unicode(item.form),
        sanitizeNumber(item.number),
        sanitizeTense(item.tense),
        sanitizeMood(item.mood),
        sanitizeGender(item.gender),
        sanitizeCase(item.case),
        sanitizePerson(item.person),
        sanitizeVoice(item.voice),
      ] for item in queue

analysisStream = new AnalysisStream(new AnalysisParser)
fileSource.pipe(analysisStream)
analysisStream.pipe(new MysqlStream)