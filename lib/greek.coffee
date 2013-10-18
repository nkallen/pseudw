Trie = require('./trie')
Preconditions = require('./preconditions')
Enum = require('./enum')
unorm = require('unorm')

###
An object model for Greek Grammar and some utilities for character encoding.
###

PartOfSpeech = Enum('PartOfSpeech', 'verb', 'noun', 'adjective', 'pronoun', 'adverb', 'adverbial', 'participle', 'punctuation', 'particle', 'preposition', 'article', 'conjunction', 'irregular', 'numeral', 'exclamation')
Tense = Enum('Tense', 'present', 'future', 'perfect', 'pluperfect', 'imperfect', 'aorist', 'futurePerfect')
Gender = Enum('Gender', 'masculine', 'feminine', 'neuter')
Person = Enum('Person', 'first', 'second', 'third')
Number = Enum('Number', 'singular', 'dual', 'plural')
Case = Enum('Case', 'nominative', 'genitive', 'dative', 'accusative', 'vocative')
Voice = Enum('Voice', 'active', 'middle', 'passive', 'middlePassive')
Mood = Enum('Mood', 'indicative', 'optative', 'imperative', 'subjunctive', 'infinitive')
Dialect = Enum('Dialect', 'aeolic',  'poetic', 'attic', 'doric', 'prose', 'ionic', 'epic', 'parad_form', 'homeric')
Degree = Enum('Degree', 'comparative', 'superlative')
Punctuation = Enum('Punctuation', '.', ';', ',', '·', '"', 'ʽ', '“', '”')

postag =
  # Bitmasks for postags:
  partOfSpeech: 15 << (3 + 2 + 2 + 2 + 3 + 3 + 3)
  case        : 7  << (2 + 2 + 2 + 3 + 3 + 3)
  gender      : 3  << (2 + 2 + 3 + 3 + 3)
  number      : 3  << (2 + 3 + 3 + 3)
  person      : 3  << (3 + 3 + 3)
  tense       : 7  << (3 + 3)
  voice       : 7  << (3)
  mood        : 7

  fromHash: (hash) ->
    result = 0
    result <<= 4
    result |= PartOfSpeech.get(hash.partOfSpeech).id + 1 if hash.partOfSpeech
    result <<= 3
    result |= Case.get(hash.case).id + 1 if hash.case
    result <<= 2
    result |= Gender.get(hash.gender).id + 1 if hash.gender
    result <<= 2
    result |= Number.get(hash.number).id + 1 if hash.number
    result <<= 2
    result |= Person.get(hash.person).id + 1 if hash.person
    result <<= 3
    result |= Tense.get(hash.tense).id + 1 if hash.tense
    result <<= 3
    result |= Voice.get(hash.voice).id + 1 if hash.voice
    result <<= 3
    result |= Mood.get(hash.mood).id + 1 if hash.mood
    result

  toHash: (postag) ->
    result = {}
    if x = postag & @partOfSpeech
      result.partOfSpeech = PartOfSpeech.getById((x >> (3 + 2 + 2 + 2 + 3 + 3 + 3)) - 1)
    if x = postag & @case
      result.case = Case.getById((x >> (2 + 2 + 2 + 3 + 3 + 3)) - 1)
    if x = postag & @gender
      result.gender = Gender.getById((x >> (2 + 2 + 3 + 3 + 3)) - 1)
    if x = postag & @number
      result.number = Number.getById((x >> (2 + 3 + 3 + 3)) - 1)
    if x = postag & @person
      result.person = Person.getById((x >> (3 + 3 + 3)) - 1)
    if x = postag & @tense
      result.tense = Tense.getById((x >> (3 + 3)) - 1)
    if x = postag & @voice
      result.voice = Voice.getById((x >> (3)) - 1)
    if x = postag & @mood
      result.mood = Mood.getById(x - 1)
    result

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
  Dialect: Dialect
  Feature: Feature
  Punctuation: Punctuation
  WordBoundary: WordBoundary
  betacode2unicode: betacode2unicode
  postag: postag
