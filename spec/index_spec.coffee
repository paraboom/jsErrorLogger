JsErrorLogger = modula.require 'js_error_logger'

describe 'JsErrorLogger', ->

  before ->
    window.printStackTrace = ->

  describe '.onError', ->
    it 'attaches provided fn to window.onerror', ->
      testFn = sinon.spy()
      JsErrorLogger.onError(testFn)
      window.onerror.call(window)
      expect(testFn).to.be.calledOnce
