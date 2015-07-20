Logger = modula.require 'js_error_logger/logger'

describe 'Logger', ->

  describe '.create', ->
    it 'returns true', ->
      expect(Logger.create()).to.be.true
