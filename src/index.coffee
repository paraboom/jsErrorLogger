class @JsErrorLogger

  handleFn = null
  wrappedFns = []
  wrappedTimers = []
  originalErrorHandler = window.onerror

  @onError: (fn) ->
    handleFn = fn
    window.onerror = (message, url, line, symbol, e) =>
      # Exceptions at line 0 basically are errors in scripts violates a browser's cross-origin policy.
      # More info: http://blog.errorception.com/2012/04/script-error-on-line-0.html.
      #
      # Some exceptions at line 0 are NPObject errors, them also should be ignored because they are throwed in a browser's plugin (e.g Flash).
      # > NPObject is an "interface" to any "foreign" code exposed through the browser
      # More info: http://stackoverflow.com/a/8938931/75284
      notOurProblem = line is 0
      messageIsObject = _.isObject(message)
      hasExceptionObject = e?

      unless notOurProblem
        if hasExceptionObject
          @processError(e)
        else if messageIsObject
          @processError(message: 'Unknown error', data: message)
        else
          @processError(message: "Global error: #{message} @ #{url}:#{line}:#{symbol}")

      # Return false to prevent default error proccessing
      false

  @processError: (e) ->
    handleFn? e,
      name: e.name
      level: 'error'
      msg: e.message
      data: e.data
      stacktrace: printStackTrace({e})

  @catchFnErrors: (object, methodName) ->
    wrappedFn = new FnWrapper(object, methodName)
    wrappedFn.onError(_.bind(@processError, @))
    wrappedFns.push(wrappedFn)

  @catchTimerErrors: (object, methodName) ->
    wrappedTimer = new TimerWrapper(object, methodName)
    wrappedFn.onError(_.bind(@processError, @))
    wrappedTimers.push(wrappedTimer)

  @reset: ->
    _.each(wrappedFns, (wrappedFn) -> wrappedFn.reset())
    _.each(wrappedTimers, (wrappedTimer) -> wrappedTimer.reset())
    wrappedFns = []
    wrappedTimers = []
    handleFn = null
    window.onerror = originalErrorHandler

 modula.export('js_error_logger', JsErrorLogger)
