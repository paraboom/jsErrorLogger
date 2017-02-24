printStackTrace = require 'stacktrace-js'

isObject = (obj) ->
  type = typeof obj
  type is 'function' or type is 'object' and !!obj

module.exports = class JsErrorLogger
  constructor: (options) ->
    {@errorProcessFn} = options
    window.onerror = @onError.bind(@)

  # Proccess global exceptions.
  #
  # Examples
  #
  #   window.onerror = Core.onError
  #
  # Always returns false to prevent default error proccessing.
  onError: (message, url, line, symbol, e) ->
    if @rethrow
      @rethrow = false
    else
      # Exceptions at line 0 basically are errors in scripts violates a
      # browser's cross-origin policy.
      #
      # More info: http://blog.errorception.com/2012/04/script-error-on-line-0.html.
      #
      # Some exceptions at line 0 are NPObject errors, them also should be
      # ignored because they are throwed in a browser's plugin (e.g Flash).
      #
      # > NPObject is an "interface" to any "foreign" code exposed through
      # > the browser
      #
      # More info: http://stackoverflow.com/a/8938931/75284
      notOurProblem = line is 0
      messageIsObject = isObject(message)
      hasExceptionObject = e?

      unless notOurProblem
        if hasExceptionObject
          @_catch(e)
        else if messageIsObject
          @_catch(message: 'Unknown error', data: message)
        else
          @_catch(message: "Global error: #{message} @ #{url}:#{line}:#{symbol}")

    false

  processError: (e) ->
    @errorProcessFn?(e, @_errorData(e))

  # Wrap function into try-catch.
  catchWrap: (fnOrObj, fnName) ->
    if fnName
      obj = fnOrObj
      origin = obj[fnName]
      obj[fnName] = @catchWrap(origin)

    else
      fn = fnOrObj
      that = @

      (args...) ->
        try
          fn.apply(@, args)
        catch e
          throw e

  catchWrapTimer: (obj, fnName) ->
    originFn = obj[fnName]
    that = @
    obj[fnName] = (fn, args...) ->

      wrappedFn = ->
        try
          if typeof fn is 'string'
            eval(fn)
          else
            fn.apply(@, arguments)
        catch e
          throw e

      originFn.call(window, wrappedFn, args...)

  ## Private

  # Returns call stack.
  #
  # Examples
  #
  #   Core.stacktrace()
  #   # => [
  #   #      ...
  #   #      "_.extend.delegateEvents (http://toptal.dev/assets/backbone.js?body=1:1339:24)",
  #   #      "Framework.View.View.delegateEvents (http://toptal.dev/assets/framework/base/view.js?body=1:81:44)",
  #   #      "Backbone.View (http://toptal.dev/assets/backbone.js?body=1:1261:10)",
  #   #      "View (http://toptal.dev/assets/framework/base/view.js?body=1:12:34)",
  #   #      ...
  #   #    ]
  #
  # Returns array.
  _stacktrace: (e) ->
    printStackTrace {e}

  # Returns stringified stacktrace.
  _stacktraceDump: (e) ->
    JSON.stringify(@_stacktrace(e))

  # Returns user agent
  _userAgent: ->
    navigator.userAgent

  # Returns exception data
  _errorData: (e) ->
    name: e.name
    level: 'error'
    msg: e.message
    data: e.data
    stacktrace: @_stacktraceDump(e)

  # Process JS exception.
  _catch: (e) ->
    @processError(e)
