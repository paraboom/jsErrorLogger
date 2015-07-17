TimerWrapper = modula.require 'yolog/timer_wrapper'

describe 'TimerWrapper', ->

  describe '.create', ->
    it 'returns true', ->
      expect(TimerWrapper.create()).to.be.true
