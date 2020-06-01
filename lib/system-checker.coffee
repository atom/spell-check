spellchecker = require 'spellchecker'
pathspec = require 'atom-pathspec'
env = require './checker-env'
debug = require 'debug'

# Initialize the global spell checker which can take some time. We also force
# the use of the system or operating system library instead of Hunspell.
if env.isSystemSupported()
  instance = new spellchecker.Spellchecker
  instance.setSpellcheckerType spellchecker.ALWAYS_USE_SYSTEM

  if not instance.setDictionary("", "")
    instance = undefined
else
  instance = undefined

# The `SystemChecker` is a special case to use the built-in system spell-checking
# provided by some platforms, such as Windows 8+ and macOS. This also doesn't have
# settings for specific locales because we need to use default, otherwise macOS
# starts to throw an occasional error if you use multiple locales at the same time
# due to some memory bug.
class SystemChecker
  constructor: ->
    @log = debug('spell-check:system-checker')
    @log 'enabled', @isEnabled(), @getStatus()

  deactivate: ->
    return

  getId: -> "spell-check:system"
  getName: -> "System Checker"
  getPriority: -> 110
  isEnabled: -> instance
  getStatus: ->
    if instance
      "working correctly"
    else
      "not supported on platform"

  providesSpelling: (args) -> @isEnabled()
  providesSuggestions: (args) -> @isEnabled()
  providesAdding: (args) -> false # Users can't add yet.

  check: (args, text) ->
<<<<<<< HEAD
    id = @getId()

    if @isEnabled()
      # We use the default checker here and not the locale-specific one so it
      # will check all languages at the same time.
      instance.checkSpellingAsync(text).then (incorrect) =>
        if @log.enabled
          @log 'check', incorrect
        {id, invertIncorrectAsCorrect: true, incorrect}
    else
      {id, status: @getStatus()}
=======
    @deferredInit()
    @spellchecker.checkSpellingAsync(text).then (incorrect) ->
      {invertIncorrectAsCorrect: true, incorrect}
>>>>>>> origin/aw-async-check

  suggest: (args, word) ->
    instance.getCorrectionsForMisspelling(word)

module.exports = SystemChecker
