greek = require('../../main/coffee/greek.coffee')

describe 'Greek', ->
  describe 'betacode2unicode', ->
    it 'catches trailing characters', ->
      this.expect(greek.betacode2unicode("le/gw")).toEqual("λέγω")
    it 'handles sigmas properly', ->
      this.expect(greek.betacode2unicode("dasso/s. dasso\\s dassos")).toEqual("δασσός. δασσὸς δασσος")