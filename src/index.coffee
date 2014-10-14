window.JsErrorLogger = class

  # Predefined list of levels.
  LOG_LEVELS = 'info warn error'.split(' ')

  # Aliases map.
  LOG_LEVEL_ALIASES =
    log: 'info'

  VISITED_PAGES_LENGTH = 5

  constructor: (options) ->
    if options.errorProcessFn and _.isFunction(options.errorProcessFn)
      @errorProcessFn = options.errorProcessFn

    window.onerror = _.bind(@onError, @)

  addLogger: (object) ->
    for level in LOG_LEVELS
      # TODO: Raise exception if some of levels is already defined in object
      # TODO: Find a way to manage custom namespaces and namespace prefixes
      object[level] = (message) ->
        echo[level](message)

    for alias, level of LOG_LEVEL_ALIASES
      object[alias] = object[level]

    object

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
      messageIsObject = _.isObject(message)
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
    @errorProcessFn e

  # Wrap function into try-catch.
  catchWrap: (fnOrObj, fnName) ->
    if fnName
      obj         = fnOrObj
      origin      = obj[fnName]
      obj[fnName] = @catchWrap(origin)

    else
      fn = fnOrObj
      that = @

      (args...) ->
        try
          fn.apply(@, args)
        catch e
          that._catch e

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
          that._catch e

      originFn.call(window, wrappedFn, args...)

  ## Private

  # Process JS exception.
  _catch: (e) ->
    @processError(e)

modula.export('js_error_logger', JsErrorLogger)
