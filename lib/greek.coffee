Trie = require('./trie')
Preconditions = require('./preconditions')
Enum = require('./enum')
unorm = require('unorm')

###
An object model for Greek Grammar and some utilities for character encoding.
###

PartOfSpeech = Enum('PartOfSpeech', 'verb', 'noun', 'adjective', 'pronoun', 'adverb', 'adverbial', 'adverbial', 'participle', 'punctuation', 'particle', 'preposition', 'article', 'conjunction', 'irregular', 'numeral', 'exclamation')
Tense = Enum('Tense', 'present', 'future', 'perfect', 'pluperfect', 'imperfect', 'aorist', 'futurePerfect')
Gender = Enum('Gender', 'masculine', 'feminine', 'neuter')
Person = Enum('Person', 'first', 'second', 'third')
Number = Enum('Number', 'singular', 'dual', 'plural')
Case = Enum('Case', 'nominative', 'genitive', 'dative', 'accusative', 'vocative')
Voice = Enum('Voice', 'active', 'middle', 'passive', 'middlePassive')
Mood = Enum('Mood', 'indicative', 'optative', 'imperative', 'subjunctive', 'infinitive')
Dialect = Enum('Dialect', 'aeolic',  'poetic', 'attic', 'doric', 'prose', 'ionic', 'epic', 'parad_form', 'homeric')
Degree = Enum('Degree', 'comparative', 'superlative')
Punctuation = Enum('Punctuation', '.', ';', ',', '·', '"')

boundaries = []
for token in Punctuation.values()
  boundaries.push(token.name)

WordBoundary = new RegExp('[' + boundaries.join('') + ']|\\s')

Features = [PartOfSpeech, Tense, Gender, Person, Number, Case, Voice, Mood, Degree, Punctuation]

###
Synonyms for dealing with data in legacy formats
###

PartOfSpeech['part'] = PartOfSpeech.participle
PartOfSpeech['partic'] = PartOfSpeech.particle
PartOfSpeech['exclam'] = PartOfSpeech.exclamation
PartOfSpeech['prep'] = PartOfSpeech.preposition
PartOfSpeech['adj'] = PartOfSpeech.adjective
PartOfSpeech['adv'] = PartOfSpeech.adverb
PartOfSpeech['pron'] = PartOfSpeech.pronoun
PartOfSpeech['conj'] = PartOfSpeech.conjunction
PartOfSpeech['irreg'] = PartOfSpeech.irregular
Number['sg'] = Number.singular
Number['pl'] = Number.plural
Tense['future perfect'] = Tense['futperf'] = Tense.futurePerfect
Tense['pres'] = Tense.present
Tense['imperf'] = Tense.imperfect
Tense['aor'] = Tense.aorist
Tense['fut'] = Tense.future
Tense['perf'] = Tense.perfect
Tense['plup'] = Tense.pluperfect
Mood['ind'] = Mood.indicative
Mood['imperat'] = Mood.imperative
Mood['subj'] = Mood.subjunctive
Mood['opt'] = Mood.optative
Mood['inf'] = Mood.infinitive
Case['nom'] = Case.nominative
Case['voc'] = Case.vocative
Case['gen'] = Case.genitive
Case['dat'] = Case.dative
Case['acc'] = Case.accusative
Gender['masc'] = Gender.masculine
Gender['fem'] = Gender.feminine
Gender['neut'] = Gender.neuter
Person['1st'] = Person.first
Person['2nd'] = Person.second
Person['3rd'] = Person.third
Voice['middle-passive'] = Voice['mp'] = Voice.middlePassive
Voice['act'] = Voice.active
Voice['mid'] = Voice.middle
Voice['pass'] = Voice.passive

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

class Participle
  class Desc
    constructor: (@tense, @voice, @case, @gender, @number) ->
      Preconditions.assertType(@tense, Tense)
      Preconditions.assertType(@voice, Voice)
      Preconditions.assertType(@case, Case)
      Preconditions.assertType(@gender, Gender)
      Preconditions.assertType(@number, Number)

  constructor: (@morpheme, @lemma, @desc) ->
    Preconditions.assertType(@morpheme, String)
    Preconditions.assertType(@lemma, String)
    Preconditions.assertType(@desc, Participle.Desc)

class Noun
  class Desc
    constructor: (@case, @gender, @number) ->
      Preconditions.assertType(@case, Case)
      Preconditions.assertType(@gender, Gender)
      Preconditions.assertType(@number, Number)

  constructor: (@morpheme, @lemma, @desc) ->
    Preconditions.assertType(@morpheme, String)
    Preconditions.assertType(@lemma, String)
    Preconditions.assertType(@desc, Desc)

class Pronoun < Noun
class Article < Adjective
class Adjective < Noun

class Verb
  class Desc
    constructor: (@tense, @voice, @mood, @person, @number) ->
      Preconditions.assertType(@tense, Tense)
      Preconditions.assertType(@voice, Voice)
      Preconditions.assertType(@mood, Mood)
      Preconditions.assertType(@person, Person)
      Preconditions.assertType(@number, Number)

  constructor: (@morpheme, @lemma, @desc) ->
    Preconditions.assertType(@morpheme, String)
    Preconditions.assertType(@lemma, String)
    Preconditions.assertType(@desc, Desc)

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
    *(r Ῥ
    /+ ̈́
    \\+ ̈̀
    =+ ̈͂
    ) ̓
    ( ̔
    / ́
    = ͂
    \\ ̀
    + ̈
    | ͅ
    & ̄
    ' ʼ
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
    unorm.nfc(out.replace(/σ(?=[\s]|[^ʼ\u0370-\u03FF]|$)/g, 'ς'))

module.exports =
  PartOfSpeech: PartOfSpeech
  Tense: Tense
  Person: Person
  Gender: Gender
  Number: Number
  Case: Case
  Voice: Voice
  Mood: Mood
  Degree: Degree
  Inflections: Inflections
  Features: Features
  Verb: Verb
  Noun: Noun
  Adjective: Adjective
  Article: Article
  Pronoun: Pronoun
  Participle: Participle
  Dialect: Dialect
  Feature: Feature
  Punctuation: Punctuation
  WordBoundary: WordBoundary
  betacode2unicode: betacode2unicode
