class FnWrapper

  constructor: (obj, fnName) ->
    @obj = obj
    @fnName = fnName
    @originalFn = obj[fnName]

    @obj[@fnName] = (args...) =>
      try
        @originalFn.apply(@, args)
      catch e
        @errorCallback?(e)

  onError: (fn) ->
    @errorCallback = fn

  reset: ->
    @obj[@fnName] = @originalFn

modula.export('yolog/fn_wrapper', FnWrapper)
