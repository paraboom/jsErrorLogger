class FnWrapper

  constructor: (@obj, @fnName) ->
    @originalFn = @obj[@fnName]

    @obj[@fnName] = (args...) =>
      try
        @originalFn.apply(@, args)
      catch e
        @errorCallback?(e)

  onError: (fn) ->
    @errorCallback = fn

  reset: ->
    @obj[@fnName] = @originalFn

modula.export('js_error_logger/fn_wrapper', FnWrapper)
