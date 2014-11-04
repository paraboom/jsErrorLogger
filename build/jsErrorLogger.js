/*! jsErrorLogger (v0.1.0),
 Advanced javascript error logger ,
 by Ivan Shornikov <paraboom@gmail.com>
 Tue Nov 04 2014 */
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
      if (options.store) {
        this.store = options.store;
      }
      if (options.dataFunction) {
        this.dataFunction = options.dataFunction;
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
      return typeof this.errorProcessFn === "function" ? this.errorProcessFn(e, this._errorData(e)) : void 0;
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

    _Class.prototype.logPageVisit = function() {
      var store, visitedPages;
      if (!this._checkStorage(this.store)) {
        return false;
      }
      if (this.store) {
        store = this.store;
      } else {
        store = this._getDefaultStore();
      }
      visitedPages = store.get('visited_pages') || [];
      if (visitedPages.length > 0) {
        this._logRecentlyVisitedPages(visitedPages);
      }
      visitedPages.push({
        location: window.location.href,
        time: new Date()
      });
      if (visitedPages.length > VISITED_PAGES_LENGTH) {
        visitedPages = visitedPages.slice(visitedPages.length - VISITED_PAGES_LENGTH);
      }
      return store.set('visited_pages', visitedPages);
    };

    _Class.prototype._logsDump = function() {
      return echo.dump();
    };

    _Class.prototype._stacktrace = function(e) {
      return printStackTrace({
        e: e
      });
    };

    _Class.prototype._stacktraceDump = function(e) {
      return JSON.stringify(this._stacktrace(e));
    };

    _Class.prototype._userAgent = function() {
      return navigator.userAgent;
    };

    _Class.prototype._errorData = function(e) {
      return {
        name: e.name,
        level: 'error',
        msg: e.message,
        person: (typeof this.dataFunction === "function" ? this.dataFunction('user') : void 0) || '',
        data: e.data,
        stacktrace: this._stacktraceDump(e),
        logs: this._logsDump()
      };
    };

    _Class.prototype._catch = function(e) {
      return this.processError(e);
    };

    _Class.prototype._logRecentlyVisitedPages = function(pages) {
      var log, _i, _len, _results;
      echo['info']('Recently visited pages:');
      _results = [];
      for (_i = 0, _len = pages.length; _i < _len; _i++) {
        log = pages[_i];
        _results.push(echo['info']("" + log.time + ": " + log.location));
      }
      return _results;
    };

    _Class.prototype._checkStorage = function(store) {
      var e;
      if (store && store.enabled) {
        return true;
      }
      try {
        localStorage.setItem('test', 'test');
        localStorage.removeItem('test');
        return true;
      } catch (_error) {
        e = _error;
        return false;
      }
    };

    _Class.prototype._getDefaultStore = function() {
      return {
        get: function(key) {
          var e, value;
          value = window.localStorage.getItem(key);
          try {
            return JSON.parse(value);
          } catch (_error) {
            e = _error;
            return value || void 0;
          }
        },
        set: function(key, val) {
          if (val != null) {
            window.localStorage.setItem(key, JSON.stringify(val));
          }
          return val;
        }
      };
    };

    return _Class;

  })();

  modula["export"]('js_error_logger', JsErrorLogger);

}).call(this);
