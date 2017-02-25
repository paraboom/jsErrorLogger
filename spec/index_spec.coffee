rewire = require 'rewire'
JsErrorLogger = rewire '../src/index'

describe 'JsErrorLogger', ->
  beforeEach ->
    @printStackTrace = sinon.spy()
    @processFunction = sinon.spy()

    @revertPrintStackTrace = JsErrorLogger.__set__({@printStackTrace})

    @jsErrorLogger = new JsErrorLogger
      errorProcessFn: @processFunction

  afterEach ->
    @revertPrintStackTrace()

  describe '#onError', ->
    it 'calls errorProcessFn when error thrown', ->
      try
        throw new Error('Error Message')
      catch e
        window.onerror.call(window, e.toString(), document.location.toString(), 2)

      expect(@processFunction).to.be.calledOnce

  describe '#catchWrap', ->
    it 'wraps function with try..catch and calls with correct context', ->
      objectWithFn =
        property: 'Value of property'
        myFn: ->
          @property

      @jsErrorLogger.catchWrap(objectWithFn, 'myFn')

      expect(objectWithFn.myFn()).to.be.eql 'Value of property'

    it 'calls errorProcessFn when error thrown', ->
      objectWithFn =
        property: 'Value of property'
        myFn: ->
          notExistingFunction()

      @jsErrorLogger.catchWrap(objectWithFn, 'myFn')

      try
        objectWithFn.myFn()
      catch e
        window.onerror.call(window, e.toString(), document.location.toString(), 2)

      expect(@processFunction).to.be.calledOnce

  describe '#catchWrapTimer', ->
    beforeEach ->
      @clock = sinon.useFakeTimers()

    afterEach ->
      @clock.restore()

    it 'wraps function with try..catch and calls errorProcessFn when error thrown', ->
      @jsErrorLogger.catchWrapTimer(window, 'setTimeout')

      objectWithFn =
        property: 'Value of property'
        myFn: ->
          notExistingFunction()

      window.setTimeout ->
        try
          objectWithFn.myFn()
        catch e
          window.onerror.call(window, e.toString(), document.location.toString(), 2)
      , 100

      @clock.tick(200)

      expect(@processFunction).to.be.calledOnce
