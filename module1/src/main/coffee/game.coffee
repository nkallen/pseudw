util = require('pseudw-util')

# todo
#
# serialize the options form 
# keybindings
# tab behavior
# fix centering when hiding inflections
# generalize server to /lemma/morphemes
# generalize client to remove any Participle dependency, adding a config for POS
# extract view class
# show paradigm

greek = util.greek
Case = greek.Case
Gender = greek.Gender
Number = greek.Number
Tense = greek.Tense
Voice = greek.Voice
Participle = greek.Participle
Inflections = greek.Inflections

class Game
  class GameDesc
    lemmas: ['τιμάω', 'λέγω3']
    inflections: Participle.allInflections
    tenses: [Tense.present, Tense.future, Tense.aorist, Tense.perfect]
    voices: [Voice.active, Voice.middle, Voice.middlePassive, Voice.passive]
    numbers: [Number.singular, Number.plural] # dual absent by default
    genders: [Gender.masculine, Gender.feminine, Gender.neuter]
    cases: [Case.nominative, Case.genitive, Case.dative, Case.accusative] # vocative absent by default
    toHash: ->
      lemmas: @lemmas
      inflections: (inflection.toSymbol() for inflection in @inflections)
      tenses: (tense.toSymbol() for tense in @tenses)
      voices: (voice.toSymbol() for voice in @voices)
      numbers: (number.toSymbol() for number in @numbers)
      genders: (gender.toSymbol() for gender in @genders)
      cases: (kase.toSymbol() for kase in @cases)
    @fromHash: (hash) ->
      gameDesc = new GameDesc
      gameDesc.inflections = (Inflections[inflection] for inflection in hash['inflections[]'])
      gameDesc.lemmas = hash['lemmas[]']
      gameDesc.tenses = (Tense[tense] for tense in hash['tenses[]'])
      gameDesc.voices = (Voice[voice] for voice in hash['voices[]'])
      gameDesc.numbers = (Number[number] for number in hash['numbers[]'])
      gameDesc.genders = (Gender[gender] for gender in hash['genders[]'])
      gameDesc.cases = (Case[kase] for kase in hash['cases[]'])
      gameDesc

  class GameState
    constructor: ->
      @startTime = new Date
    currentTurn: null
    showingMistake: false
    totalTurns: 0
    correctTurns: 0
    accuracy:
      mistakes: {}
      total: {}

  @make: (options, $div, participleDao, onSuccess) ->
    gameDesc = GameDesc.fromHash(options)
    $config = $div.find(".config")

    for inflection in gameDesc.inflections
      $config.find("[data-option-inflection=#{inflection.toSymbol()}]")
        .addClass("active")

    for inflection in Participle.allInflections
      inflectionSymbol = inflection.toSymbol()
      for activeAttribute in gameDesc["#{inflectionSymbol}s"]
        $config.find("[data-option-#{inflectionSymbol}=#{activeAttribute}]").addClass("active")
    $config.find("[name=lemmas]").val(gameDesc.lemmas.join(", "))

    participleDao.findAllByLemma(gameDesc.lemmas, gameDesc.toHash(), (participles) ->
      gameDesc.participles = participles
      onSuccess(new Game(gameDesc, $div)))

  constructor: (@gameDesc, @$div) ->
    @$carousel       = @$div.find(".carousel")
    @$cardPrototype  = @$carousel.find(".prototype")
    @$carouselInner  = @$div.find(".carousel-inner")
    @$correctTurns   = @$div.find(".correct-turns")
    @$morpheme       = @$div.find(".morpheme")
    @$totalTurns     = @$div.find(".total-turns")
    @$state          = @$div.find(".state")
    @$config         = @$div.find(".config")
    @$modal          = @$div.find(".modal")

    @participlesByForm = {}
    @forms = []
    for participle in gameDesc.participles
      (@participlesByForm[participle.morpheme] ?= []).push(participle)
      @forms.push(participle.morpheme)

    @forms.sort(() -> Math.floor(Math.random() * 3) - 1)

    @$carousel.on('click.carousel', '[data-move=next]', (e) =>
      @nextTurn()
      e.preventDefault()
    )

    @$carousel.on('click.carousel', '[data-move=prev]', (e) =>
      @prevTurn()
      e.preventDefault()
    )

    @$modal.find(".btn-primary").click((e) =>
      window.location = window.location.origin + window.location.pathname + "?#{$.param(@configToGameDesc().toHash())}"
    )

    for inflection in Participle.allInflections
      inflectionSymbol = inflection.toSymbol()
      if inflection not in gameDesc.inflections
        @$cardPrototype.find("[data-inflection=#{inflectionSymbol}]")
          .addClass("hide")

    @state = new GameState

  start: ->
    @nextTurn()

  nextTurn: ->
    if @state.currentTurn
      $currentCard = @$carousel.find(".item.active")
      madeMistake = false
      for inflection in @gameDesc.inflections
        inflectionSymbol = inflection.toSymbol()
        for participle in @state.currentTurn
          $attribute = $currentCard.find("[data-#{inflectionSymbol}=#{participle.participleDesc[inflectionSymbol]}]")
          attribute = participle.participleDesc[inflectionSymbol]
          if $attribute.hasClass('active')
            $attribute
              .addClass('btn-success')
              .data("correct", true)
          else
            madeMistake = true
            @state.accuracy.mistakes[attribute] ||= 0
            @state.accuracy.mistakes[attribute] += 1
            $attribute.addClass('btn-danger')
          @state.accuracy.total[attribute] ||= 0
          @state.accuracy.total[attribute] += 1
        mistakes =
          $currentCard.find("[data-#{inflectionSymbol}].active").filter("[data-correct]")
            .addClass('btn-danger')
        madeMistake = true if mistakes.length > 0
        $currentCard.find("[data-#{inflectionSymbol}]")
          .addClass("disabled")

      @state.totalTurns++
      if madeMistake
        @state.currentTurn = null
        @state.accuracy.mistakes[participle] ||= 0
        @state.accuracy.mistakes[participle] += 1
      else
        @state.correctTurns++
      @state.accuracy.total[participle] ||= 0
      @state.accuracy.total[participle] += 1

    if @hasRemaining()
      unless madeMistake
        @$carousel.find('[data-move=prev]').removeClass("hide") if @state.totalTurns == 1
        participles = @chooseParticiples()
        @state.currentTurn = participles
        @showTurn(participles)
    else
      @state.currentTurn = null
      @$carousel.find('[data-move=next]').addClass("hide")
      showEnd()

  showTurn: (participles) ->
    $card = @$cardPrototype.clone()
    $card
      .removeClass('prototype')
      .addClass('item')
      .removeAttr('aria-hidden')
      .find('.btn-group')
        .keydown((e) ->
          key = String.fromCharCode(e.which)
          $card.find("[data-keybinding=#{key}]").click()
        )

    if participles.length > 1
      $card.find(".morpheme").html("#{participles[0].morpheme} <span class='label label-info'>#{participles.length} variants</span>")
    else
      $card.find(".morpheme").text("#{participles[0].morpheme}")
    $card.find(".principalParts").text(participles[0].verb.principalParts)
    $card.find(".translation").text(participles[0].verb.translation)
    $card.appendTo(@$carouselInner)
    @showState()
    @$carousel.carousel('next')

  chooseParticiples: ->
    form = @forms.shift()
    @participlesByForm[form]

  hasRemaining: -> true

  showState: ->
    @$correctTurns.text(@state.correctTurns)
    @$totalTurns.text(@state.totalTurns)

  configToGameDesc: ->
    gameDesc = new GameDesc

    gameDesc.inflections = []
    @$config.find("[data-option-inflection].active").map((i, node) ->
      # XXX jquery dependency
      gameDesc.inflections.push(Inflections[$(node).data('option-inflection')])
    )
    for element in [Tense, Voice, Number, Gender, Case]
      gameDesc["#{element.toSymbol()}s"] = []
      @$config.find("[data-option-#{element.toSymbol()}].active").map((i, node) ->
        # XXX jquery dependency
        gameDesc["#{element.toSymbol()}s"].push(element[$(node).data("option-#{element.toSymbol()}")])
      )
    gameDesc.lemmas = @$config.find("[name=lemmas]").val().split(/[,;\s]\s*/)
    gameDesc

module.exports = Game