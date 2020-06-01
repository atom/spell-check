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
<<<<<<< HEAD
    instance.getCorrectionsForMisspelling(word)
=======
    @deferredInit()
    @spellchecker.getCorrectionsForMisspelling(word)

  deferredInit: ->
    # If we already have a spellchecker, then we don't have to do anything.
    if @spellchecker
      return

    # Initialize the spell checker which can take some time.
    @spellchecker = new spellchecker.Spellchecker

    # Windows uses its own API and the paths are unimportant, only attempting
    # to load it works.
    if /win32/.test process.platform
      if @spellchecker.setDictionary @locale, "C:\\"
        return

    # Check the paths supplied by the user.
    for path in @paths
      if @spellchecker.setDictionary @locale, path
        return

    # For Linux, we have to search the directory paths to find the dictionary.
    if /linux/.test process.platform
      if @spellchecker.setDictionary @locale, "/usr/share/hunspell"
        return
      if @spellchecker.setDictionary @locale, "/usr/share/myspell"
        return
      if @spellchecker.setDictionary @locale, "/usr/share/myspell/dicts"
        return

    # OS X uses the following paths.
    if /darwin/.test process.platform
      if @spellchecker.setDictionary @locale, "/"
        return
      if @spellchecker.setDictionary @locale, "/System/Library/Spelling"
        return

    vendor = spellchecker.getDictionaryPath()
    if @spellchecker.setDictionary @locale, vendor
      return

    # If we fell through all the if blocks, then we couldn't load the dictionary.
    @enabled = false
    @reason = "Cannot find dictionary for " + @locale + "."
    console.log @getId(), "Can't load " + @locale + ": " + @reason
>>>>>>> origin/pr-233

module.exports = SystemChecker
