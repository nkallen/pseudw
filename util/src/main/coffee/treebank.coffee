greek = require('./greek')
vm = require('vm')
fs = require('fs')

Sizzle = do ->
  script = vm.createScript(fs.readFileSync(__dirname + "/../../../../sizzle/sizzle.js", "utf8"), 'sizzle.js');
  sandbox = { window: {}, document: null, console: console }
  script.runInNewContext(sandbox)
  sandbox.window.Sizzle

Sizzle.selectors.pseudos.before = Sizzle.selectors.createPseudo(
  (selector) ->
    (elem) ->
      matches = Sizzle(selector, elem)
      (match for match in matches when (elem.getAttribute('id') < match.getAttribute('id'))).length)

Sizzle.selectors.pseudos.after = Sizzle.selectors.createPseudo(
  (selector) ->
    (elem) ->
      matches = Sizzle(selector, elem)
      (match for match in matches when (elem.getAttribute('id') > match.getAttribute('id'))).length)


class DomShim
  constructor: (@attributes) ->
    @children = []
    @parentNode = null
    @nodeName = @attributes.lemma
  nodeType: 1
  getAttribute: (attribute) ->
    @attributes[attribute]
  compareDocumentPosition: (that) ->
    if this.attributes.id < that.attributes.id
      4
    else
      2
  getElementsByTagName: (name) ->
    if name == "*"
      @children
    else
      child for child in @children when child.nodeName == name
  uuid: () -> [@attributes.id, @attributes.sentenceId].toString()

class DocumentShim
  constructor: (@tags) ->
  nodeType: 9
  getElementsByTagName: (name) ->
    if name == "*"
      @tags.word
    else
      @tags[name] || []
  documentElement:
    removeChild: () ->
  createComment : () -> {}
  createElement : () -> {}
  getElementById : () -> []

Treebank =
  wordNode2word: (wordNode) ->
    sentence = wordNode.parent()
    lemma = wordNode.attr('lemma').value().replace(/1$/, '')
    id = wordNode.attr('id').value()
    sentenceId = sentence.attr('id').value()
    parentId = wordNode.attr('head').value()

    postag = wordNode.attr('postag').value()
    relation = wordNode.attr('relation').value()
    partOfSpeech = switch postag[0]
      when 'n' then 'noun'
      when 'v' then 'verb'
      when 't' then 'participle'
      when 'a' then 'adjective'
      when 'd' then 'adverb'
      when 'l' then 'article'
      when 'g' then 'particle'
      when 'c' then 'conjunction'
      when 'r' then 'preposition'
      when 'p' then 'pronoun'
      when 'm' then 'numeral'
      when 'i' then 'interjection'
      when 'e' then 'exclamation'
      when 'u' then 'punctuation'
      when 'x' then 'irregular'
      when '-' then null
      else throw "Invalid part-of-speech #{postag[0]} #{wordNode}"
    person = switch postag[1]
      when '1' then 'first'
      when '2' then 'second'
      when '3' then 'third'
      when '-' then null
      else throw "Invalid person #{postag[1]}"
    number = switch postag[2]
      when 's' then 'singular'
      when 'd' then 'dual'
      when 'p' then 'plural'
      when '-' then null
      else throw "Invalid number #{postag[2]}"
    tense = switch postag[3]
      when 'p' then 'present'
      when 'i' then 'imperfect'
      when 'r' then 'perfect'
      when 'l' then 'pluperfect'
      when 't' then 'future perfect'
      when 'f' then 'future'
      when 'a' then 'aorist'
      when '-' then null
      else throw "Invalid tense #{postag[3]}"
    mood = switch postag[4]
      when 'i' then 'indicative'
      when 's' then 'subjunctive'
      when 'o' then 'optative'
      when 'n' then 'infinitive'
      when 'm' then 'imperative'
      when 'p' then null
      when 'd' then 'gerund'
      when 'g' then 'gerundive'
      when '-' then null
      else throw "Invalid mood #{postag[4]}"
    voice = switch postag[5]
      when 'a' then 'active'
      when 'p' then 'passive'
      when 'm' then 'middle'
      when 'e' then 'middle-passive'
      when '-' then null
      else throw "Invalid voice #{postag[5]}"
    gender = switch postag[6]
      when 'm' then 'masculine'
      when 'f' then 'feminine'
      when 'n' then 'neuter'
      when '-' then null
      else throw "Invalid gender #{postag[6]}"
    kase = switch postag[7]
      when 'n' then 'nominative'
      when 'g' then 'genitive'
      when 'd' then 'dative'
      when 'a' then 'accusative'
      when 'v' then 'vocative'
      when 'l' then 'locative'
      when '-' then null
      else throw "Invalid case #{postag[7]}"
    degree = switch postag[8]
      when 'c' then 'comparative'
      when 's' then 'superlative'
      when '-' then null
      else throw "Invalid degree #{postag[7]}"

    {
      form:  if partOfSpeech == "punctuation" then wordNode.attr('form').value() else greek.betacode2unicode(wordNode.attr('form').value()),
      lemma: if partOfSpeech == "punctuation" then lemma else greek.betacode2unicode(lemma),
      id: id,
      sentenceId: sentenceId,
      parentId: parentId,
      relation: relation
      partOfSpeech: partOfSpeech,
      person: person,
      number: number,
      tense: tense,
      mood: mood,
      voice: voice,
      gender: gender,
      case: kase,
      degree: degree}

  load: (xml) ->
    tags =
      word: []

    id2word = currentSentenceId = null

    for bookNode in xml.find("//section[@class='book']")
      for wordNode in bookNode.find(".//span")
        sentenceId = wordNode.attr('data-sentence-id').value()

        unless currentSentenceId
          currentSentenceId = sentenceId
          id2word = {}
        if sentenceId != currentSentenceId
          root = null

          for id, word of id2word
            attributes = word.attributes
            if attributes.parentId == '0'
              root = word
            else
              parent = id2word[attributes.parentId]
              parent.children.push(word)
              word.parentNode = parent

          currentSentenceId = sentenceId
          id2word = {}

        attributes =
          form: wordNode.text()
          lemma: wordNode.attr('data-lemma').value()
          sentenceId: sentenceId
          id: wordNode.attr('data-id').value()
          parentId: wordNode.attr('data-parent-id').value()
          relation: wordNode.attr('data-relation').value()
          partOfSpeech: wordNode.attr('data-part-of-speech').value()
          person: wordNode.attr('data-person')?.value()
          number: wordNode.attr('data-number')?.value()
          tense: wordNode.attr('data-tense')?.value()
          mood: wordNode.attr('data-mood')?.value()
          voice: wordNode.attr('data-voice')?.value()
          gender: wordNode.attr('data-gender')?.value()
          case: wordNode.attr('data-case')?.value()
          degree: wordNode.attr('data-degree')?.value()
          line: wordNode.parent().parent().find('.//a')[0].text()
        attributes.book = bookNode.attr('data-number').value() if attributes.parentId == '0'

        word = new DomShim(attributes)
        id2word[attributes.id] = word
        tags.word.push(word)
        if lemma = tags[attributes.lemma]
          lemma.push(word)
        else
          tags[attributes.lemma] = [word]

    (query) -> Sizzle(query, new DocumentShim(tags))

module.exports = Treebank