greek = require('../lib/greek.coffee')

describe 'Greek', ->
  describe 'betacode2unicode', ->
    it 'catches trailing characters', ->
      greek.betacode2unicode("le/gw").should.eql("λέγω")
    it 'handles sigmas properly', ->
      greek.betacode2unicode("dasso/s. dasso\\s dassos").should.eql("δασσός. δασσὸς δασσος")