JsErrorLogger = modula.require 'js_error_logger'

describe 'JsErrorLogger', ->

  describe '.create', ->
    it 'returns true', ->
      expect(JsErrorLogger.createLogger()).to.be.true
