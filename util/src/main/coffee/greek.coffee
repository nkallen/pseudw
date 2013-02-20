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
  betacode2unicode: betacode2unicode,
}