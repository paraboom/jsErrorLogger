FnWrapper = modula.require 'yolog/fn_wrapper'

describe 'FnWrapper', ->

  describe '.create', ->
    it 'returns true', ->
      expect(FnWrapper.create()).to.be.true
