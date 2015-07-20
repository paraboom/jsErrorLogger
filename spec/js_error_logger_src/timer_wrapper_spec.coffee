TimerWrapper = modula.require 'js_error_logger/timer_wrapper'

describe 'TimerWrapper', ->
  before ->
    @originalSetTimeout = originalSetTimeout = window.setTimeout

    @runAsync = (fn) ->
      dfd = $.Deferred()
      fn.call(@)

      originalSetTimeout ->
        dfd.resolve()
      , 100
      dfd.promise()

  beforeEach ->
    @errorHandler = sinon.spy()
    @buggyFn = -> callUndefinedFunction()

    window.setTimeout = (fn, timeout) -> fn.call(@)

  afterEach ->
    window.setTimeout = @originalSetTimeout

  describe '#constructor', ->
    it 'cathes errors, which happen error happens in timer', ->
      @wrapperTimer = new TimerWrapper(window, 'setTimeout')
      @wrapperTimer.onError(@errorHandler)

      @runAsync(=>
        setTimeoutCall = _.bind(setTimeout, window, @buggyFn, 10)
        expect(setTimeoutCall).to.not.throw "Can't find variable"
      ).then =>
        expect(@errorHandler).to.be.calledOnce
        expect(@errorHandler.lastCall.args[0]).to.be.instanceOf(Error)

  describe '#onError', ->
    it 'saves provided callback in @errorCallback', ->
      @wrapperTimer = new TimerWrapper(window, 'setTimeout')
      @wrapperTimer.onError(@errorHandler)
      expect(@wrapperTimer.errorCallback).to.be.equal @errorHandler

  describe '#reset', ->
    it 'removes errors wrapper', ->
      @wrapperTimer = new TimerWrapper(window, 'setTimeout')
      @wrapperTimer.onError(@errorHandler)

      @runAsync(=>
        setTimeoutCall = _.bind(setTimeout, window, @buggyFn, 10)
        expect(setTimeoutCall).to.not.throw "Can't find variable"
        expect(@errorHandler).to.be.calledOnce

        @wrapperTimer.reset()

        setTimeoutCall = _.bind(setTimeout, window, @buggyFn, 10)
        expect(setTimeoutCall).to.throw "Can't find variable"
      ).then =>
        expect(@errorHandler).to.be.calledOnce
