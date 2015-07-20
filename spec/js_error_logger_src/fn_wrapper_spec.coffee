FnWrapper = modula.require 'js_error_logger/fn_wrapper'

describe 'FnWrapper', ->
  before ->
    @runAsync = (fn) ->
      dfd = $.Deferred()
      setTimeout ->
        fn.call(@)
        dfd.resolve()
      , 10
      dfd.promise()

  beforeEach ->
    @errorHandler = sinon.spy()
    @testObject = buggyFunction: -> callUndefinedFunction()

  describe '#constructor', ->
    it 'cathes errors, which happen when provided function is called asynchrounously', ->
      @wrappedFn = new FnWrapper(@testObject, 'buggyFunction')
      @wrappedFn.onError(@errorHandler)

      @runAsync(=>
        expect(@testObject.buggyFunction).to.not.throw "Can't find variable"
      ).then =>
        expect(@errorHandler).to.be.calledOnce
        expect(@errorHandler.lastCall.args[0]).to.be.instanceOf(Error)

  describe '#onError', ->
    it 'saves provided callback in @errorCallback', ->
      @wrappedFn = new FnWrapper(@testObject, 'buggyFunction')
      @wrappedFn.onError(@errorHandler)
      expect(@wrappedFn.errorCallback).to.be.equal @errorHandler

  describe '#reset', ->
    it 'removes errors wrapper', ->
      @wrappedFn = new FnWrapper(@testObject, 'buggyFunction')
      @wrappedFn.onError(@errorHandler)
      @wrappedFn.reset()

      @runAsync(=>
        expect(@testObject.buggyFunction).to.throw "Can't find variable"
      )
