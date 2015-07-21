class Logger

  constructor: (options) ->
    @logger = Echo()
    @logger.defineDefaults()
    @logger.defaultOptions.print = options.shouldPrintLogs

  log: (message) ->
    @logger.log(message)

  error: (message) ->
    @logger.error(message)

  warn: (message) ->
    @logger.warn(message)

  getLogs: ->
    @logger.logs.all()

  getLogsDump: ->
    @getLogs().map((logItem) ->
      logItem.body[0].replace(/\n/g, '\n____')
    ).join('\n')

modula.export('js_error_logger/logger', Logger)
