/*! jsErrorLogger (v0.1.0),
 Advanced javascript error logger ,
 by Ivan Shornikov <paraboom@gmail.com>
 Tue Oct 14 2014 */
(function() {
  var modules;

  modules = {};

  if (window.modula == null) {
    window.modula = {
      "export": function(name, exports) {
        return modules[name] = exports;
      },
      require: function(name) {
        var Module;
        Module = modules[name];
        if (Module) {
          return Module;
        } else {
          throw "Module '" + name + "' not found.";
        }
      }
    };
  }

}).call(this);

(function() {
  var __slice = [].slice;

  window.JsErrorLogger = (function() {
    var LOG_LEVELS, LOG_LEVEL_ALIASES, VISITED_PAGES_LENGTH;

    LOG_LEVELS = 'info warn error'.split(' ');

    LOG_LEVEL_ALIASES = {
      log: 'info'
    };

    VISITED_PAGES_LENGTH = 5;

    function _Class(options) {
      if (options.errorProcessFn && _.isFunction(options.errorProcessFn)) {
        this.errorProcessFn = options.errorProcessFn;
      }
      window.onerror = _.bind(this.onError, this);
    }

    _Class.prototype.addLogger = function(object) {
      var alias, level, _i, _len;
      for (_i = 0, _len = LOG_LEVELS.length; _i < _len; _i++) {
        level = LOG_LEVELS[_i];
        object[level] = function(message) {
          return echo[level](message);
        };
      }
      for (alias in LOG_LEVEL_ALIASES) {
        level = LOG_LEVEL_ALIASES[alias];
        object[alias] = object[level];
      }
      return object;
    };

    _Class.prototype.onError = function(message, url, line, symbol, e) {
      var hasExceptionObject, messageIsObject, notOurProblem;
      if (this.rethrow) {
        this.rethrow = false;
      } else {
        notOurProblem = line === 0;
        messageIsObject = _.isObject(message);
        hasExceptionObject = e != null;
        if (!notOurProblem) {
          if (hasExceptionObject) {
            this._catch(e);
          } else if (messageIsObject) {
            this._catch({
              message: 'Unknown error',
              data: message
            });
          } else {
            this._catch({
              message: "Global error: " + message + " @ " + url + ":" + line + ":" + symbol
            });
          }
        }
      }
      return false;
    };

    _Class.prototype.processError = function(e) {
      return this.errorProcessFn(e);
    };

    _Class.prototype.catchWrap = function(fnOrObj, fnName) {
      var fn, obj, origin, that;
      if (fnName) {
        obj = fnOrObj;
        origin = obj[fnName];
        return obj[fnName] = this.catchWrap(origin);
      } else {
        fn = fnOrObj;
        that = this;
        return function() {
          var args, e;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          try {
            return fn.apply(this, args);
          } catch (_error) {
            e = _error;
            return that._catch(e);
          }
        };
      }
    };

    _Class.prototype.catchWrapTimer = function(obj, fnName) {
      var originFn, that;
      originFn = obj[fnName];
      that = this;
      return obj[fnName] = function() {
        var args, fn, wrappedFn;
        fn = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        wrappedFn = function() {
          var e;
          try {
            if (typeof fn === 'string') {
              return eval(fn);
            } else {
              return fn.apply(this, arguments);
            }
          } catch (_error) {
            e = _error;
            return that._catch(e);
          }
        };
        return originFn.call.apply(originFn, [window, wrappedFn].concat(__slice.call(args)));
      };
    };

    _Class.prototype._catch = function(e) {
      return this.processError(e);
    };

    return _Class;

  })();

  modula["export"]('js_error_logger', JsErrorLogger);

}).call(this);
