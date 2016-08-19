SpecChecker = require './spec-checker'

class EndOfTestSpecChecker extends SpecChecker
  constructor: ->
    super("eot", true, ["eot"])

checker = new EndOfTestSpecChecker
module.exports = checker
