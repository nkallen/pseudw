class Game
  class GameDesc
    constructor: (@showDictionaryEntry, @askFor, @showRuleOnError, @participles) ->

  class GameState
    constructor: ->
      @startTime = new Date
    currentTurn: null
    totalTurns: 0
    correctTurns: 0
    turns: {} # mapping of participle to correct/incorrect count

  @make: ($div, Participle, onSuccess) ->
    lemmas = $div.find(".config textarea[name=lemmas]").text().split(/,\s*/)
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
        $inflection = $turn.find(".#{inflection} .#{@state.currentTurn.participleDesc[inflection]}")
        if $inflection.hasClass('active')
          $inflection.addClass('btn-success')
        else
          madeMistake = true
          $inflection.addClass('btn-danger')

      @state.totalTurns++
      @state.correctTurns++ unless madeMistake

    if @hasRemaining()
      participle = @chooseParticiple()
      @state.currentTurn = participle
      @showTurn(participle)
    else
      @state.currentTurn = null
      showEnd()

  showTurn: (participle) ->
    $turn = @$cardPrototype
      .clone()
      .removeClass('prototype')
      .addClass('item')
      .removeAttr('aria-hidden')
    $turn.find(".morpheme").text(participle.morpheme)
    $turn.find(".principalParts").text(participle.verb.principalParts)
    $turn.find(".definition").text(participle.verb.defintion)
    $turn.appendTo(@$carouselInner)
    @showState()
    @$card.carousel('next')

  chooseParticiple: -> @gameDesc.participles[Math.floor(Math.random() * @gameDesc.participles.length)]

  hasRemaining: -> true

  showState: ->
    console.log(@state)
    @$correctTurns.text(@state.correctTurns)
    @$totalTurns.text(@state.totalTurns)

module.exports = Game