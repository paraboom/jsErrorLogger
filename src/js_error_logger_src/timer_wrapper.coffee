class TimerWrapper

  constructor: (@obj, @fnName) ->
    @originalFn = @obj[@fnName]

    @obj[@fnName] = (fn, args...) =>
      errorCallback = @errorCallback
      wrappedFn = ->
        try
          if typeof fn is 'string'
            eval(fn)
          else
            fn.apply(@, arguments)
        catch e
          errorCallback?(e)

      @originalFn.call(window, wrappedFn, args...)

  onError: (fn) ->
    @errorCallback = fn

  reset: ->
    @obj[@fnName] = @originalFn

modula.export('js_error_logger/timer_wrapper', TimerWrapper)
