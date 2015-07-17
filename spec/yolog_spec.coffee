Yolog = modula.require 'yolog'

describe 'Yolog', ->

  describe '.create', ->
    it 'returns true', ->
      expect(Yolog.createLogger()).to.be.true
