SpecChecker = require './spec-checker'

class KnownUnicodeSpecChecker extends SpecChecker
  constructor: ->
    super("known-unicode", false, ["こんいちば"])

checker = new KnownUnicodeSpecChecker
module.exports = checker
