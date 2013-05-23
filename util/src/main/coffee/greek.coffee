Trie = require('./trie')
Preconditions = require('./preconditions')
Enum = require('./enum')
unorm = require('unorm')

###
An object model for Greek Grammar and some utilities for character encoding.
###

Tense = Enum('Tense', 'present', 'future', 'perfect', 'pluperfect', 'imperfect', 'aorist', 'futurePerfect')
Gender = Enum('Gender', 'masculine', 'feminine', 'neuter')
Number = Enum('Number', 'singular', 'dual', 'plural')
Case = Enum('Case', 'nominative', 'genitive', 'dative', 'accusative', 'vocative')
Voice = Enum('Voice', 'active', 'middle', 'passive', 'middlePassive')
Mood = Enum('Mood', 'indicative', 'optatitive', 'imperative', 'subjunctive')
Dialect = Enum('Dialect', 'aeolic',  'poetic', 'attic', 'doric', 'prose', 'ionic', 'epic', 'parad_form', 'homeric')

Feature = Enum('Feature',
  'a_copul',
  'a_priv',
  'apocope',
  'causal',
  'elide_preverb',
  'pros_to_proti',
  'unasp_preverb',
  'impersonal',
  'en_to_eni',
  'frequentat',
  'intrans',
  'late',
  'n_infix',
  'nu_movable',
  'pres_redupl',
  'redupl',
  'short_subj',
  'syncope',
  'uncontr',
  'uper_to_upeir',
  'attic_redupl',
  'pros_to_poti',
  'short_eis',
  'sig_to_ci',
  'comp_only',
  'contr',
  'dissimilation',
  'iota_intens',
  'later',
  'prevb_aug',
  'raw_preverb',
  'unaugmented',
  'desiderative',
  'iterative',
  'meta_to_peda',
  'r_e_i_alpha',
  'doubled_cons',
  'diminutive',
  'double_aug',
  'early',
  'rare',
  'raw_sonant',
  'geog_name',
  'indeclform',
  'irreg_comp',
  'irreg_superl',
  'no_redupl',
  'para_to_parai',
  'upo_to_upai',
  'root_preverb',
  'enclitic',
  'ends_in_dig',
  'metath',
  'no_circumflex',
  'proclitic',
  'syll_augment')

Inflections =
  toSymbol: -> 'inflection'
for inflection in [Tense, Gender, Number, Case, Voice, Mood]
  Inflections[inflection.toSymbol()] = inflection

class Verb
  constructor: (@lemma, @principleParts, @translation) ->

class ParticipleDesc
  constructor: (@tense, @voice, @case, @gender, @number) ->
    Preconditions.assertType(@tense, Tense)
    Preconditions.assertType(@voice, Voice)
    Preconditions.assertType(@case, Case)
    Preconditions.assertType(@gender, Gender)
    Preconditions.assertType(@number, Number)

class Participle
  constructor: (@morpheme, @verb, @participleDesc) ->
    Preconditions.assertType(@verb, Verb)
    Preconditions.assertType(@participleDesc, ParticipleDesc)

  @allInflections: [Tense, Voice, Case, Gender, Number]

betacode2unicode = do ->
  raw =
   "a α
    b β
    g γ
    d δ
    e ε
    v ϝ
    z ζ
    h η
    q θ
    i ι
    k κ
    l λ
    m μ
    n ν
    c ξ
    o ο
    p π
    r ρ
    s σ
    t τ
    u υ
    f φ
    x χ
    y ψ
    w ω
    *a Α
    *b Β
    *g Γ
    *d Δ
    *e Ε
    *v Ϝ
    *z Ζ
    *h Η
    *q Θ
    *i Ι
    *k Κ
    *l Λ
    *m Μ
    *n Ν
    *c Ξ
    *o Ο
    *p Π
    *r Ρ
    *s Σ
    *t Τ
    *u Υ
    *f Φ
    *x Χ
    *y Ψ
    *w Ω
    *)/a Ἄ
    *)/e Ἔ
    *)/h Ἤ
    *)/i Ἴ
    *)/o Ὄ
    *)/u Υ̓́
    *)/w Ὤ
    *)\\a Ἂ
    *)\\e Ἒ
    *)\\h Ἢ
    *)\\i Ἲ
    *)\\o Ὂ
    *)\\u Υ̓̀
    *)\\w Ὢ
    *)=a Ἆ
    *)=e Ἐ͂
    *)=h Ἦ
    *)=i Ἶ
    *)=o Ὀ͂
    *)=u Υ̓͂
    *)=w Ὦ
    *)a Ἀ
    *)e Ἐ
    *)h Ἠ
    *)i Ἰ
    *)o Ὀ
    *)u Υ̓
    *)w Ὠ
    *(/a Ἅ
    *(/e Ἕ
    *(/h Ἥ
    *(/i Ἵ
    *(/o Ὅ
    *(/u Ὕ
    *(/w Ὥ
    *(\\a Ἃ
    *(\\e Ἓ
    *)\\h Ἣ
    *(\\i Ἳ
    *(\\o Ὃ
    *(\\u Ὓ
    *(\\w Ὣ
    *(=a Ἇ
    *(=e Ἑ͂
    *(=h Ἧ
    *(=i Ἷ
    *(=o Ὁ͂
    *(=u Ὗ
    *(=w Ὧ
    *(a Ἁ
    *(e Ἑ
    *(h Ἡ
    *(i Ἱ
    *(o Ὁ
    *(u Ὑ
    *(w Ὡ
    ) ̓
    ( ̔
    / ́
    = ͂
    \\ ̀
    + ̈
    | ͅ
    & ̄
    ' ’
    : ·"
  array = raw.split(/\s+/)
  betacode2unicodeTrie = new Trie
  while array.length > 0
    [betacode, unicode, array...] = array
    betacode2unicodeTrie.put(betacode, unicode)

  (betacode) ->
    out = ""
    prev = null
    traversal = betacode2unicodeTrie.traverse()
    i = 0
    while i < betacode.length
      char = betacode[i++]
      prev = traversal
      unless (traversal = traversal.find(char))
        if prev.value()
          out = out.concat(prev.value())
          i--
        else
          out = out.concat(char)
        traversal = betacode2unicodeTrie.traverse()
    out = out.concat(traversal.value()) if traversal.value()
    unorm.nfc(out.replace(/σ(\b|$)/, 'ς'))

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
      form: betacode2unicode(wordNode.attr('form').value()),
      lemma: betacode2unicode(lemma),
      id: id,
      sentenceId: sentenceId,
      parentId: parentId,
      partOfSpeech: partOfSpeech,
      person: person,
      number: number,
      tense: tense,
      mood: mood,
      voice: voice,
      gender: gender,
      case: kase,
      degree: degree,
      relation: relation}

module.exports = {
  Tense: Tense,
  Gender: Gender,
  Number: Number,
  Case: Case,
  Voice: Voice,
  Mood: Mood,
  Verb: Verb,
  Inflections: Inflections,
  ParticipleDesc: ParticipleDesc,
  Participle: Participle,
  Dialect: Dialect,
  Feature: Feature,
  Treebank: Treebank,
  betacode2unicode: betacode2unicode,
}