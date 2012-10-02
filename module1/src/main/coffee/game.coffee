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
    @$correctTurns   = @$div.find(".correctTurns")
    @$morpheme       = @$div.find(".morpheme")
    @$totalTurns     = @$div.find(".totalTurns")
    @$principalParts = @$div.find(".principalParts")
    @$definition     = @$div.find(".definition")
    @$nextButton     = @$div.find("button.next")

    console.log(@$nextButton)
    @$nextButton.click(=>
      @nextTurn()
    )

    @state = new GameState

  start: ->
    @nextTurn()

  nextTurn: ->
    if @state.currentTurn
      answer = getAnswer()
      @gameState.correctTurns++ if isAnswerCorrect(answer)
      @gameState.totalTurns++

    if @hasRemaining()
      participle = @chooseParticiple()
      @showTurn(participle)
    else
      showEnd()

  showTurn: (participle) ->
    @showCard()
    @showParticiple(participle)
    @showState()

  chooseParticiple: -> @gameDesc.participles[Math.floor(Math.random() * @gameDesc.participles.length)]

  hasRemaining: -> true

  showCard: ->
    @$card.toggleClass("show-dictionary-entry", @showDictionaryEntry)

  showParticiple: (participle) ->
    @$morpheme.html(participle.morpheme)
    @$principalParts.html(participle.verb.principalParts)
    @$definition.html(participle.verb.definition)

  showState: ->
    @$correctTurns.html(@state.correctTurns)
    @$totalTurns.html(@state.correctTurns)

module.exports = Game