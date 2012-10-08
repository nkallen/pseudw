util = require('pseudw-util')

# todo
#
# generalize server to /lemma/morphemes
# generalize client to remove any Participle dependency, adding a config for POS
# extract view class

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
      for element in [Inflections, Tense, Voice, Number, Gender, Case] when param = hash["#{element.toSymbol()}s[]"]
        array = if Array.isArray(param) then param else Array(param)
        gameDesc["#{element.toSymbol()}s"] = (element[attribute] for attribute in array)
      if lemmas = hash['lemmas[]']
        gameDesc.lemmas = (if Array.isArray(lemmas) then lemmas else Array(lemmas))
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
        $config.find("[data-option-#{inflectionSymbol}=#{activeAttribute}]")
          .addClass("active")
    $config.find("[name=lemmas]").val(gameDesc.lemmas.join(", "))

    options = {}
    gameDescHash = gameDesc.toHash()
    for key in ['tenses', 'voices', 'numbers', 'genders', 'cases']
      options[key] = gameDescHash[key]

    participleDao.findAllByLemma(gameDesc.lemmas, options, (participles) ->
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
    for participle in @gameDesc.participles
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
      $inflection = @$cardPrototype.find("[data-inflection=#{inflectionSymbol}]")
      if inflection not in @gameDesc.inflections
        $inflection.addClass("hide")
      for attribute in inflection.values() when attribute not in @gameDesc["#{inflectionSymbol}s"]
        $inflection.find("[data-#{inflectionSymbol}=#{attribute.toSymbol()}]")
          .hide()

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
    self = this
    $card
      .removeClass('prototype')
      .addClass('item')
      .removeAttr('aria-hidden')
      .find('.btn-group')
        .keydown((e) ->
          if e.which == 13
            self.$carousel.find('[data-move=next]').click()
          else
            key = String.fromCharCode(e.which).toLowerCase()
            return unless /[a-z]/.test(key)
            return if e.metaKey || e.ctrlKey || e.altKey
            # XXX jquery dep
            $(this).find("[data-keybinding=#{key}]").click()
          e.preventDefault()
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
    $card.find('.btn-group:not(.hide)')[0].focus()

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