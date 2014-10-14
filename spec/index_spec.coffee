JsErrorLogger = modula.require 'js_error_logger'

describe 'JsErrorLogger', ->

  beforeEach ->
    @processFunction = sinon.spy()

    @jsErrorLogger = new JsErrorLogger {
      errorProcessFn: @processFunction
    }

  describe '#addLogger', ->

    beforeEach ->
      @tempObject = {}
      @jsErrorLogger.addLogger(@tempObject)

    it 'extends object with logger methods', ->
      expect(@tempObject).to.have.ownProperty('info')
      expect(@tempObject).to.have.ownProperty('warn')
      expect(@tempObject).to.have.ownProperty('error')
      expect(@tempObject).to.have.ownProperty('log')

    it 'delegates logger methods to echo.js methods', ->
      window.echo =
        info: sinon.spy()
        warn: sinon.spy()
        error: sinon.spy()

      @tempObject.info('Error message')

      expect(window.echo.info).to.be.calledOnce
      expect(window.echo.info.lastCall.args).to.be.eql ['Error message']

      @tempObject.log('Error message two')

      expect(window.echo.info).to.be.calledTwice
      expect(window.echo.info.lastCall.args).to.be.eql ['Error message two']

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

      try
        window.setTimeout ->
          objectWithFn.myFn()
        , 10
      catch e
        window.onerror.call(window, e.toString(), document.location.toString(), 2)

      @clock.tick(20);

      expect(@processFunction).to.be.calledOnce

  describe '#logPageVisit', ->

    beforeEach ->
      window.localStorage.clear()
      @jsErrorLogger.addLogger(@jsErrorLogger)

    it 'saves visited pages to store', ->
      @jsErrorLogger.logPageVisit()

      visitedPagesValue = JSON.parse(window.localStorage.getItem('visited_pages'))

      expect(JSON.parse(window.localStorage.getItem('visited_pages')).length).to.be.eql 1

      @jsErrorLogger.logPageVisit()

      expect(JSON.parse(window.localStorage.getItem('visited_pages')).length).to.be.eql 2

    it 'saves not more than VISITED_PAGES_LENGTH (5) items in store', ->
      for i in [1..10]
        @jsErrorLogger.logPageVisit()

      expect(JSON.parse(window.localStorage.getItem('visited_pages')).length).to.be.eql 5


