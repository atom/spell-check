SpecChecker = require './spec-checker'

class KnownUnicodeSpecChecker extends SpecChecker
  constructor: ->
    super("known-unicode", false, ["абырг"])

checker = new KnownUnicodeSpecChecker
module.exports = checker
