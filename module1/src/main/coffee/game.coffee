util = require('pseudw-util')

# todo
#
# support server side filter of inflections
# use inflections when making rpc
# track user mistakes
# tab behavior
# lines
# make going backwards possible
# keybindings
# config populated from url
# fix centering when hiding inflections
# show paradigm
# load definitions

greek = util.greek
Case = greek.Case
Gender = greek.Gender
Number = greek.Number
Tense = greek.Tense
Voice = greek.Voice
Participle = greek.Participle

class Game
  class GameDesc
    lemmas: ['τιμάω', 'λέγω3']
    showDictionaryEntry: true
    inflections: Participle.allInflections
    tenses: [Tense.present, Tense.future, Tense.aorist, Tense.perfect]
    voices: [Voice.active, Voice.middle, Voice.middlePassive, Voice.passive]
    numbers: [Number.singular, Number.plural] # dual absent by default
    genders: [Gender.masculine, Gender.feminine, Gender.neuter]
    cases: [Case.nominative, Case.genitive, Case.dative, Case.accusative] # vocative absent by default

  class GameState
    constructor: ->
      @startTime = new Date
    currentTurn: null
    showingMistake: false
    totalTurns: 0
    correctTurns: 0
    turns: {} # mapping of participle to correct/incorrect count

  @make: ($div, participleDao, onSuccess) ->
    gameDesc = new GameDesc
    for inflection in gameDesc.inflections
      inflectionLowerCase = inflection.toString().toLowerCase()
      $div.find(".config [data-option-inflection=#{inflectionLowerCase}]")
        .addClass("active")

    for inflection in Participle.allInflections
      inflectionLowerCase = inflection.toString().toLowerCase()
      for activeAttribute in gameDesc["#{inflectionLowerCase}s"]
        $div.find(".config [data-option-#{inflectionLowerCase}=#{activeAttribute}]").addClass("active")
    $div.find(".config [name=lemmas]").val(gameDesc.lemmas.join(", "))

    participleDao.findAllByLemma(gameDesc.lemmas, (participles) ->
      gameDesc.participles = participles
      onSuccess(new Game(gameDesc, $div)))

  constructor: (@gameDesc, @$div) ->
    @$card           = @$div.find(".card")
    @$cardPrototype  = @$card.find(".prototype")
    @$carouselInner  = @$div.find(".carousel-inner")
    @$correctTurns   = @$div.find(".correct-turns")
    @$morpheme       = @$div.find(".morpheme")
    @$totalTurns     = @$div.find(".total-turns")
    @$principalParts = @$div.find(".principalParts")
    @$definition     = @$div.find(".definition")
    @$state          = @$div.find(".state")

    @participlesByForm = {}
    @forms = []
    for participle in gameDesc.participles
      (@participlesByForm[participle.morpheme] ?= []).push(participle)
      @forms.push(participle.morpheme)

    @forms.sort(() -> Math.floor(Math.random() * 3) - 1)

    @$card.on('click.carousel', '[data-move]', (e) =>
      @nextTurn()
      e.preventDefault()
    )

    for inflection in Participle.allInflections
      inflectionLowerCase = inflection.toString().toLowerCase() # XXX DRY
      if inflection not in gameDesc.inflections
        @$cardPrototype.find("[data-inflection=#{inflectionLowerCase}]")
          .addClass("hide")

    @state = new GameState

  start: ->
    @nextTurn()

  nextTurn: ->
    if @state.currentTurn
      $turn = @$card.find(".item.active")
      madeMistake = false
      for inflection in @gameDesc.inflections
        inflectionLowerCase = inflection.toString().toLowerCase()
        for participle in @state.currentTurn
          $inflection = $turn.find("[data-#{inflectionLowerCase}=#{participle.participleDesc[inflectionLowerCase]}]")
          if $inflection.hasClass('active')
            $inflection
              .addClass('btn-success')
              .removeClass('active')
              .data("correct", true)
          else
            madeMistake = true
            $inflection.addClass('btn-danger')
        mistakes =
          $turn.find("[data-#{inflectionLowerCase}].active").filter("[data-correct]")
            .addClass('btn-danger')
        madeMistake = true if mistakes.length > 0
        $turn.find("[data-#{inflectionLowerCase}]")
          .addClass("disabled")

      @state.totalTurns++
      if madeMistake
        @state.currentTurn = null
      else
        @state.correctTurns++

    if @hasRemaining()
      unless madeMistake
        participles = @chooseParticiples()
        @state.currentTurn = participles
        @showTurn(participles)
    else
      @state.currentTurn = null
      showEnd()

  showTurn: (participles) ->
    $turn = @$cardPrototype
      .clone()
      .removeClass('prototype')
      .addClass('item')
      .removeAttr('aria-hidden')
      .find('.btn-group')
        .keypress((event) ->
          key = "p" # f(event.charCode) # XXX
          $(this).find("[data-keybinding=#{key}]").click()
        )
        .end()

    if participles.length > 1
      $turn.find(".morpheme").text("#{participles[0].morpheme} (#{participles.length} variants)")
    else
      $turn.find(".morpheme").text("#{participles[0].morpheme}")
    $turn.find(".principalParts").text(participles[0].verb.principalParts)
    $turn.find(".definition").text(participles[0].verb.defintion)
    $turn.appendTo(@$carouselInner)
    @showState()
    @$card.carousel('next')

  chooseParticiples: ->
    form = @forms.shift()
    @participlesByForm[form]

  hasRemaining: -> true

  showState: ->
    @$correctTurns.text(@state.correctTurns)
    @$totalTurns.text(@state.totalTurns)

module.exports = Game