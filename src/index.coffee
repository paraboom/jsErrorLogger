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

    @store = options.store if options.store

    @dataObject = options.dataObject if options.dataObject

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
    @errorProcessFn? e, @_errorData(e)

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

  # Log recently vistiteed pages and save current one
  logPageVisit: ->
    return unless window.localStorage

    store = @_getDefaultStore() unless @store

    visitedPages = store.get('visited_pages') || []

    @_logRecentlyVisitedPages(visitedPages) if visitedPages.length > 0

    visitedPages.push(location: window.location.href, time: new Date())

    if visitedPages.length > VISITED_PAGES_LENGTH
      visitedPages = visitedPages.slice(visitedPages.length - VISITED_PAGES_LENGTH)

    store.set('visited_pages', visitedPages)

  ## Private

  # Returns dump of all saved logs.
  _logsDump: ->
    echo.dump()

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
    printStackTrace { e }

  # Returns stringified stacktrace.
  _stacktraceDump: (e) ->
    JSON.stringify(@._stacktrace(e))

  # Returns user agent
  _userAgent: ->
    navigator.userAgent

  # Returns exception data
  _errorData: (e) ->
    name:       e.name
    level:      'error'
    msg:        e.message
    person:     @dataObject?('user') || ''
    data:       e.data
    stacktrace: @_stacktraceDump(e)
    logs:       @_logsDump()

  # Process JS exception.
  _catch: (e) ->
    @processError(e)

  _logRecentlyVisitedPages: (pages) ->
    @log('Recently visited pages:')
    @log("#{log.time}: #{log.location}") for log in pages

  _getDefaultStore: ->
    get: (key) ->
      value = window.localStorage.getItem(key)
      try
        return JSON.parse(value)
      catch e
        return value || undefined

    set: (key, val) ->
      window.localStorage.setItem(key, JSON.stringify(val)) if val?
      return val

modula.export('js_error_logger', JsErrorLogger)
