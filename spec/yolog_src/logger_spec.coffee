Logger = modula.require 'yolog/logger'

describe 'Logger', ->

  describe '.create', ->
    it 'returns true', ->
      expect(Logger.create()).to.be.true
