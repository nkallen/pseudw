Trie = require('./trie')
Preconditions = require('./preconditions')
Enum = require('./enum')

###
An object model for Greek Grammar and some utilities for character encoding.
###

Tense = Enum('Tense', 'present', 'future', 'perfect', 'pluperfect', 'imperfect', 'aorist')
Gender = Enum('Gender', 'masculine', 'feminine', 'neuter')
Number = Enum('Number', 'singular', 'dual', 'plural')
Case = Enum('Case', 'nominative', 'genitive', 'dative', 'accusative', 'vocative')
Voice = Enum('Voice', 'active', 'middle', 'passive', 'middlePassive')
Mood = Enum('Mood', 'indicative', 'optatitive', 'imperative', 'subjunctive')

class Verb
  constructor: (@lemma, @principleParts, @definition) ->

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

  @allInflections: [Tense, Voice, Gender, Number, Case]

betacode2unicode = do ->
  # The following is unicorn normalized to NFC
  raw =
    "a)/ ἄ
    a(/ ἅ
    a(= ἆ
    a)= ἇ
    a|( ᾁ
    a|) ᾀ
    a/| ᾴ
    a=| ᾷ
    a|\ ᾲ
    a|/ ᾴ
    a) ἀ
    a( ἁ
    a/ ά
    a\ ὰ
    a= ᾶ
    a| ᾳ
    a α
    c ξ
    d δ
    e)/ ἔ
    e(/ ἔ
    e) ἐ
    e( ἑ
    e/ έ
    e\ ὲ
    e ε
    b β
    f φ
    g γ
    h)/ ἤ
    h(/ ἥ
    h)= ἦ
    h(= ῆ
    h)| ᾐ
    h(| ᾑ
    h/| ῄ
    h=| ῇ
    h|\ ῂ
    h|/ ῄ
    h) ἠ
    h( ἡ
    h/ ή
    h\ ὴ
    h= ἠ
    h| ῃ
    h η
    i)/ ἴ
    i(/ ἵ
    i)= ἶ
    i(= ἷ
    i) ἰ
    i( ἱ
    i/ ί
    i\ ὶ
    i= ῖ
    i ι
    k κ
    l λ
    m μ
    n ν
    o)/ ὄ
    o(/ ὅ
    o) ὀ
    o( ὁ
    o/ ό
    o\ ὸ
    o ο
    p π
    q θ
    r( ῥ
    r ρ
    s σ
    t τ
    u)/ ὔ
    u(/ ὕ
    u)= ὖ
    u(= ὗ
    u) ὐ
    u( ὑ
    u/ ύ
    u\ ὺ
    u= ῦ
    u υ
    w)/ ὤ
    w(/ ὥ
    w|( ᾡ
    w|) ᾠ
    w)= ὧ
    w(= ὦ
    w/| ώ
    w=| ῷ
    w|\ ῲ
    w|/ ώ
    w) ὠ
    w( ὡ
    w/ ώ
    w\ ὼ
    w= ῶ
    w| ῳ
    w ω
    x χ
    y ψ
    z ζ"
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
    out

module.exports = {
  Tense: Tense,
  Gender: Gender,
  Number: Number,
  Case: Case,
  Voice: Voice,
  Mood: Mood,
  Verb: Verb,
  ParticipleDesc: ParticipleDesc,
  Participle: Participle,
  betacode2unicode: betacode2unicode,
}