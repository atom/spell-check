spellchecker = require 'spellchecker'
pathspec = require 'atom-pathspec'
env = require './checker-env'

# Initialize the global spell checker which can take some time. We also force
# the use of the system or operating system library instead of Hunspell.
instance = new spellchecker.Spellchecker
instance.setSpellcheckerType spellchecker.ALWAYS_USE_SYSTEM

# The `SystemChecker` is a special case to use the built-in system spell-checking
# provided by some platforms, such as Windows 8+ and macOS. This also doesn't have
# settings for specific locales because we need to use default, otherwise macOS
# starts to throw an occasional error if you use multiple locales at the same time
# due to some memory bug.
class SystemChecker
  constructor: ->
    #console.log @getId(), "enabled", @isEnabled()

  deactivate: ->
    return

  getId: -> "spell-check:system"
  getName: -> "System Checker"
  getPriority: -> 110
  isEnabled: -> env.isSystemSupported()
  getStatus: ->
    if env.isSystemSupported()
      "Working correctly"
    else
      "Disabled on Linux"

  providesSpelling: (args) -> @isEnabled()
  providesSuggestions: (args) -> @isEnabled()
  providesAdding: (args) -> false # Users can't add yet.

  check: (args, text) ->
    id = @getId()
    if @isEnabled()
      # We use the default checker here and not the locale-specific one so it
      # will check all languages at the same time.
      instance.checkSpellingAsync(text).then (incorrect) ->
        {id, invertIncorrectAsCorrect: true, incorrect}
    else
      {id, status: @getStatus()}

  suggest: (args, word) ->
    instance.getCorrectionsForMisspelling(word)

module.exports = SystemChecker
