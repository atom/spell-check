# Background task for checking the text of a buffer and returning the
# spelling. Since this can be an expensive operation, it is intended to be run
# in the background with the results returned asynchronously.
backgroundCheck = (data) ->
  # Load a manager in memory and let it initialize.
  SpellCheckerManager = require './spell-check-manager.coffee'
  instance = SpellCheckerManager
  instance.locales = data.args.locales
  instance.localePaths = data.args.localePaths
  instance.useLocales = data.args.useLocales
  instance.knownWords = data.args.knownWords
  instance.addKnownWords = data.args.addKnownWords

  misspellings = instance.check data.args, data.text
  {id: data.args.id, misspellings}

module.exports = backgroundCheck
