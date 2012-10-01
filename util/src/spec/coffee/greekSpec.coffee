greek = require('../../main/coffee/greek.coffee')

describe 'Greek', ->
  describe 'betacode2unicode', ->
    it 'catches trailing characters', ->
      this.expect(greek.betacode2unicode("le/gw")).toEqual("λέγω")
