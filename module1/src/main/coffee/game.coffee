class Game
  class GameDesc
    constructor: (@showDictionaryEntry, @askFor, @showRuleOnError, @participles) ->
      @byForm = {}
      @forms = []
      for participle in @participles
        (@byForm[participle.morpheme] ?= []).push(participle)
        @forms.push(participle.morpheme)

  class GameState
    constructor: ->
      @startTime = new Date
    currentTurn: null
    showingMistake: false
    totalTurns: 0
    correctTurns: 0
    turns: {} # mapping of participle to correct/incorrect count

  @make: ($div, Participle, onSuccess) ->
    lemmas = $div.find(".config [name=lemmas]").val().split(/,\s*/)
    Participle.findAllByLemma(lemmas, (participles) ->
      gameDesc = new GameDesc(true, [], true, participles)
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

    @$card.on('click.carousel', '[data-move]', (e) =>
      @nextTurn()
      e.preventDefault()
    )

    @state = new GameState

  start: ->
    @nextTurn()

  nextTurn: ->
    if @state.currentTurn
      $turn = @$card.find(".item.active")
      madeMistake = false
      for inflection in ['tense', 'voice', 'case', 'gender', 'number']
        for participle in @state.currentTurn
          $inflection = $turn.find(".#{inflection} .#{participle.participleDesc[inflection]}")
          if $inflection.hasClass('active')
            $inflection.addClass('btn-success')
          else
            madeMistake = true
            $inflection.addClass('btn-danger')

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
    randomForm = @gameDesc.forms[Math.floor(Math.random() * @gameDesc.participles.length)]
    @gameDesc.byForm[randomForm]

  hasRemaining: -> true

  showState: ->
    @$correctTurns.text(@state.correctTurns)
    @$totalTurns.text(@state.totalTurns)

module.exports = Game