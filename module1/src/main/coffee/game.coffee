util = require('pseudw-util')
Preconditions = util.preconditions

# todo
#
# somehow make static assets cacheable
# generalize server to /lemma/morphemes
# generalize client to remove any Participle dependency, adding a config for POS

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
    accuracy: do ->
      mistakes = {}
      total = {}
      mistake: (elem) ->
        mistakes[elem] ||= 0
        mistakes[elem]++
      total: (elem) ->
        total[elem] ||= 0
        total[elem]++        

  class GameView
    class Correction
      constructor: ->
        @right = []
        @wrong = []
        @missing = []

    constructor: (@$div) ->
      @$               = $div.constructor # hacky way of not making jQuery a npm dependency
      @$config         = $div.find(".config")
      @$carousel       = @$div.find(".carousel")
      @$cardPrototype  = @$carousel.find(".prototype")
      @$carouselInner  = @$div.find(".carousel-inner")
      @$correctTurns   = @$div.find(".correct-turns")
      @$morpheme       = @$div.find(".morpheme")
      @$totalTurns     = @$div.find(".total-turns")
      @$state          = @$div.find(".state")
      @$config         = @$div.find(".config")
      @$modal          = @$div.find(".modal")
      @posFromCurrentTurn = 0

    init: (gameDesc, game) ->
      @prepareOptionsForm(gameDesc)
      @prepareAnswerFields(gameDesc)
      @bindCarouselEvents(game)

      # store the height of the carousel so that it doesn't jiggle while we switch visibility:hidden to display:none
      @$carousel.height(@$carousel.height())
      @$cardPrototype
        .addClass('hide')
        .removeClass('invisible')

    prepareOptionsForm: (gameDesc) ->
      Preconditions.assertType(gameDesc, GameDesc)

      for inflection in gameDesc.inflections
        @$config.find("[data-option-inflection=#{inflection.toSymbol()}]")
          .addClass("active")

      for inflection in Participle.allInflections
        inflectionSymbol = inflection.toSymbol()
        for activeAttribute in gameDesc["#{inflectionSymbol}s"]
          @$config.find("[data-option-#{inflectionSymbol}=#{activeAttribute}]")
            .addClass("active")
      @$config.find("[name=lemmas]").val(gameDesc.lemmas.join(", "))

      @$config.find(".btn-primary").click((e) =>
        window.location = window.location.origin + window.location.pathname + "?#{@$.param(@configToGameDesc().toHash())}")

    prepareAnswerFields: (gameDesc) ->
      for inflection in Participle.allInflections
        inflectionSymbol = inflection.toSymbol()
        $inflection = @$cardPrototype.find("[data-inflection=#{inflectionSymbol}]")
        if inflection not in gameDesc.inflections
          $inflection.addClass("hide")
        for attribute in inflection.values() when attribute not in gameDesc["#{inflectionSymbol}s"]
          $inflection.find("[data-#{inflectionSymbol}=#{attribute.toSymbol()}]")
            .hide()

    bindCarouselEvents: (game) ->
      @$carousel.on('click.carousel', '[data-move=next]', (e) =>
        if @posFromCurrentTurn < 0
          @$carousel.carousel('next')
          @posFromCurrentTurn++
        else
          game.nextTurn()
        e.preventDefault()
      )

      @$carousel.on('click.carousel', '[data-move=prev]', (e) =>
        @$carousel.carousel('prev')
        @posFromCurrentTurn--
        e.preventDefault())

    configToGameDesc: ->
      gameDesc = new GameDesc

      gameDesc.inflections = []
      @$config.find("[data-option-inflection].active").map((i, node) =>
        gameDesc.inflections.push(Inflections[@$(node).data('option-inflection')]))
      for element in [Tense, Voice, Number, Gender, Case]
        gameDesc["#{element.toSymbol()}s"] = []
        @$config.find("[data-option-#{element.toSymbol()}].active").map((i, node) =>
          gameDesc["#{element.toSymbol()}s"].push(element[@$(node).data("option-#{element.toSymbol()}")]))
      gameDesc.lemmas = @$config.find("[name=lemmas]").val().split(/[,;\s]\s*/)
      gameDesc

    correctAnswer: ->
      $currentCard = @$carouselInner.find(".item.active")
      answer = {}
      corrections = {}
      for inflection in $currentCard.find("[data-inflection]")
        $inflection = @$(inflection)
        inflectionSymbol = $inflection.data("inflection")
        answer[inflectionSymbol] = []
        for attribute in $inflection.find("[data-#{inflectionSymbol}].active")
          $attribute = @$(attribute)
          answer[inflectionSymbol].push($attribute.data(inflectionSymbol))
        corrections[inflectionSymbol] = new Correction
      [corrections, answer]

    showCorrection: (corrections) ->
      $currentCard = @$carouselInner.find(".item.active")
      for inflectionSymbol, correction of corrections
        [right, wrong, missing] = [correction.right, correction.wrong, correction.missing]
        for attribute in right
          $currentCard.find("[data-inflection=#{inflectionSymbol}] [data-#{inflectionSymbol}=#{attribute}]")
            .addClass('btn-success')
        for attribute in missing
          $currentCard.find("[data-inflection=#{inflectionSymbol}] [data-#{inflectionSymbol}=#{attribute}]")
            .addClass('btn-danger')
        $currentCard.find("[data-inflection=#{inflectionSymbol}] [data-#{inflectionSymbol}]")
          .addClass("disabled")

    allowPrev: ->
      @$carousel.find('[data-move=prev]').removeClass("hide")

    disallowNext: ->
      @$carousel.find('[data-move=next]').addClass("hide")

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
              (self.$)(this).find("[data-keybinding=#{key}]").click()
            e.preventDefault())

      if participles.length > 1
        $card.find(".morpheme").html("#{participles[0].morpheme} <span class='label label-info'>#{participles.length} variants</span>")
      else
        $card.find(".morpheme").text("#{participles[0].morpheme}")
      $card.find(".principalParts").text(participles[0].verb.principalParts)
      $card.find(".translation").text(participles[0].verb.translation)
      $card.appendTo(@$carouselInner)
      @$carousel.carousel('next').one('slid', =>
        $card.find('.btn-group:not(.hide)')[0].focus())

    showState: (state) ->
      @$correctTurns.text(state.correctTurns)
      @$totalTurns.text(state.totalTurns)

  @make: (options, $div, participleDao, onSuccess) ->
    gameDesc = GameDesc.fromHash(options)
    gameView = new GameView($div)

    options = {}
    gameDescHash = gameDesc.toHash()
    for key in ['tenses', 'voices', 'numbers', 'genders', 'cases']
      options[key] = gameDescHash[key]

    participleDao.findAllByLemma(gameDesc.lemmas, options, (err, participles) ->
      throw err if err?

      gameDesc.participles = participles
      onSuccess(new Game(gameDesc, gameView)))

  constructor: (@gameDesc, @gameView) ->
    @participlesByForm = {}
    @forms = []
    for participle in @gameDesc.participles
      (@participlesByForm[participle.morpheme] ?= []).push(participle)
      @forms.push(participle.morpheme)

    @forms.sort(() -> Math.floor(Math.random() * 3) - 1)

    @gameView.init(gameDesc, this)

    @state = new GameState

  start: ->
    @nextTurn()

  nextTurn: ->
    if @state.currentTurn
      [corrections, answer] = @gameView.correctAnswer()

      madeMistake = false
      for inflection in @gameDesc.inflections
        inflectionSymbol = inflection.toSymbol()
        allegedAttributes = answer[inflectionSymbol]
        actualAttributes = (participle.participleDesc[inflectionSymbol] for participle in @state.currentTurn)
        for allegedAttribute in allegedAttributes
          if inflection[allegedAttribute] not in actualAttributes
            corrections[inflectionSymbol].wrong.push(allegedAttribute)
            madeMistake = true
          else
            corrections[inflectionSymbol].right.push(allegedAttribute)
        for actualAttribute in actualAttributes
          if actualAttribute.toSymbol() not in allegedAttributes
            corrections[inflectionSymbol].missing.push(actualAttribute)
            madeMistake = true
            @state.accuracy.mistake(actualAttribute)
          @state.accuracy.total(actualAttribute)

      @state.totalTurns++
      if madeMistake
        @state.currentTurn = null
        @state.accuracy.mistake(participle)
      else
        @state.correctTurns++
      @state.accuracy.total(participle)

    @gameView.showCorrection(corrections)
    @gameView.showState(@state)

    if @hasRemaining()
      unless madeMistake
        @gameView.allowPrev() if @state.totalTurns == 1
        participles = @chooseParticiples()
        @state.currentTurn = participles
        @gameView.showTurn(participles)
    else
      @state.currentTurn = null
      @gameView.disallowNext()
      showEnd()

  chooseParticiples: ->
    form = @forms.shift()
    @participlesByForm[form]

  hasRemaining: -> true

module.exports = Game